import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class InstagramService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _sessionId;
  String? _csrfToken;
  String? _username;
  bool _isConnected = false;
  bool _isLoading = false;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get username => _username;

  /// Cookie header used for authenticated scraping
  Map<String, String> get _authHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cookie': 'sessionid=$_sessionId; csrftoken=$_csrfToken; ig_cb=1',
        'X-CSRFToken': _csrfToken ?? '',
      };

  InstagramService() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      _sessionId = await _secureStorage.read(key: 'ig_session_id');
      _csrfToken = await _secureStorage.read(key: 'ig_csrf_token');
      _username = await _secureStorage.read(key: 'ig_username');

      if (_sessionId != null && _sessionId!.isNotEmpty) {
        // Verify the session is still valid
        _isConnected = await _verifySession();
        if (!_isConnected) {
          await _clearSession();
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading stored Instagram session: $e');
    }
  }

  Future<bool> _verifySession() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.instagram.com/accounts/edit/'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      // If we get redirected to login, session is invalid
      if (response.statusCode == 200 && !response.body.contains('"loginPage"')) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Opens a webview for the user to log in to Instagram.
  /// Returns true if login was successful.
  Future<bool> connectInstagram(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const _InstagramLoginWebView(),
        ),
      );

      if (result == true) {
        // Cookies were captured by the webview, now read them
        final cookieManager = CookieManager.instance();
        final cookies = await cookieManager.getCookies(
          url: WebUri('https://www.instagram.com'),
        );

        String? sessionId;
        String? csrfToken;

        for (final cookie in cookies) {
          if (cookie.name == 'sessionid') {
            sessionId = cookie.value;
          } else if (cookie.name == 'csrftoken') {
            csrfToken = cookie.value;
          }
        }

        if (sessionId != null && sessionId.isNotEmpty) {
          _sessionId = sessionId;
          _csrfToken = csrfToken;
          _isConnected = true;

          // Try to fetch the username
          await _fetchUsername();
          await _saveSession();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Instagram login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUsername() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.instagram.com/accounts/edit/?__a=1&__d=dis'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          _username = data['form_data']?['username']?.toString();
        } catch (_) {
          // Try parsing from HTML
          final usernameMatch = RegExp(r'"username"\s*:\s*"([^"]+)"')
              .firstMatch(response.body);
          if (usernameMatch != null) {
            _username = usernameMatch.group(1);
          }
        }
      }
    } catch (e) {
      print('Error fetching Instagram username: $e');
    }
  }

  Future<void> disconnectInstagram() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear webview cookies for Instagram
      final cookieManager = CookieManager.instance();
      await cookieManager.deleteCookies(
        url: WebUri('https://www.instagram.com'),
      );

      await _clearSession();
    } catch (e) {
      print('Error disconnecting Instagram: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _clearSession() async {
    _sessionId = null;
    _csrfToken = null;
    _username = null;
    _isConnected = false;

    await _secureStorage.delete(key: 'ig_session_id');
    await _secureStorage.delete(key: 'ig_csrf_token');
    await _secureStorage.delete(key: 'ig_username');
  }

  Future<void> _saveSession() async {
    if (_sessionId != null) {
      await _secureStorage.write(key: 'ig_session_id', value: _sessionId);
    }
    if (_csrfToken != null) {
      await _secureStorage.write(key: 'ig_csrf_token', value: _csrfToken);
    }
    if (_username != null) {
      await _secureStorage.write(key: 'ig_username', value: _username);
    }
  }

  /// Fetch Instagram content using authenticated session cookies.
  /// Returns null if not connected or fetch fails — caller should fall back to scraping.
  Future<Map<String, dynamic>?> fetchWithAuth(String url) async {
    if (!_isConnected || _sessionId == null) return null;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      // Check if we got redirected to login (session expired)
      if (response.body.contains('"loginPage"') ||
          response.body.contains('not-logged-in')) {
        _isConnected = false;
        await _clearSession();
        notifyListeners();
        return null;
      }

      final document = html_parser.parse(response.body);

      // Try extracting from og: meta tags first (richer data when authenticated)
      final ogDesc = _extractMeta(document, 'property="og:description"') ?? '';
      final ogTitle = _extractMeta(document, 'property="og:title"') ?? '';
      final ogImage = _extractMeta(document, 'property="og:image"') ?? '';

      // Try extracting from embedded JSON (works better when logged in)
      String caption = '';
      String author = '';
      String thumbnail = ogImage;

      final scripts = document.querySelectorAll('script');
      for (final script in scripts) {
        final text = script.text;

        // Look for shared data JSON
        if (text.contains('window._sharedData') || text.contains('window.__additionalDataLoaded')) {
          final captionMatch = RegExp(r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
          if (captionMatch != null) {
            caption = captionMatch.group(1)!
                .replaceAll('\\n', '\n')
                .replaceAll('\\u0040', '@')
                .replaceAll('\\"', '"')
                .replaceAll('\\\\', '\\');
          }

          final usernameMatch = RegExp(r'"username"\s*:\s*"([^"]+)"').firstMatch(text);
          if (usernameMatch != null) {
            author = usernameMatch.group(1)!;
          }

          if (caption.isNotEmpty) break;
        }

        // Also try the newer require/relay data format
        if (text.contains('"edge_media_to_caption"') || text.contains('"caption"')) {
          final captionTextMatch = RegExp(r'"text"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
          if (captionTextMatch != null && caption.isEmpty) {
            caption = captionTextMatch.group(1)!
                .replaceAll('\\n', '\n')
                .replaceAll('\\u0040', '@')
                .replaceAll('\\"', '"')
                .replaceAll('\\\\', '\\');
          }

          final ownerMatch = RegExp(r'"owner"\s*:\s*\{[^}]*"username"\s*:\s*"([^"]+)"').firstMatch(text);
          if (ownerMatch != null && author.isEmpty) {
            author = ownerMatch.group(1)!;
          }

          if (caption.isNotEmpty) break;
        }
      }

      // Fall back to og: tags if JSON extraction failed
      if (caption.isEmpty) {
        caption = ogDesc.isNotEmpty ? ogDesc : ogTitle;
      }

      if (caption.isEmpty && author.isEmpty) return null;

      // Extract author from og:title if still empty
      if (author.isEmpty && ogTitle.contains('(@')) {
        final match = RegExp(r'\(@([^)]+)\)').firstMatch(ogTitle);
        if (match != null) author = match.group(1)!;
      }

      String contentType = 'post';
      if (url.contains('/reel/') || url.contains('/reels/')) {
        contentType = 'reel';
      } else if (url.contains('/stories/')) {
        contentType = 'story';
      } else if (url.contains('/tv/')) {
        contentType = 'igtv';
      }

      final hashtagRegex = RegExp(r'#(\w+)');
      final hashtags = hashtagRegex.allMatches(caption).map((m) => m.group(1)!).toList();
      final cleanCaption = caption.replaceAll(RegExp(r'#\w+\s*'), '').trim();

      return {
        'title': cleanCaption.isNotEmpty ? cleanCaption : 'Instagram $contentType',
        'description': cleanCaption,
        'author': author.isNotEmpty ? '@$author' : '',
        'platform': 'Instagram',
        'contentType': contentType,
        'thumbnail': thumbnail,
        'publishDate': '',
        'duration': '',
        'viewCount': '',
        'engagement': {},
        'hashtags': hashtags,
        'rawCaption': caption,
      };
    } catch (e) {
      print('Instagram authenticated fetch failed: $e');
      return null;
    }
  }

  String? _extractMeta(dynamic document, String selector) {
    final element = document.querySelector('meta[$selector]');
    return element?.attributes['content']?.trim();
  }
}

/// Full-screen webview that loads Instagram login page.
/// Closes and returns true once the user has logged in successfully.
class _InstagramLoginWebView extends StatefulWidget {
  const _InstagramLoginWebView();

  @override
  State<_InstagramLoginWebView> createState() => _InstagramLoginWebViewState();
}

class _InstagramLoginWebViewState extends State<_InstagramLoginWebView> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Instagram'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://www.instagram.com/accounts/login/'),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            ),
            onLoadStop: (controller, url) async {
              setState(() => _isLoading = false);

              final currentUrl = url?.toString() ?? '';

              // User has logged in and been redirected to feed or home
              if (currentUrl == 'https://www.instagram.com/' ||
                  currentUrl.startsWith('https://www.instagram.com/?') ||
                  currentUrl.contains('instagram.com/accounts/onetap')) {
                // Check if sessionid cookie exists
                final cookieManager = CookieManager.instance();
                final cookies = await cookieManager.getCookies(
                  url: WebUri('https://www.instagram.com'),
                );

                final hasSession = cookies.any((c) => c.name == 'sessionid' && c.value.isNotEmpty);
                if (hasSession) {
                  if (mounted) Navigator.pop(context, true);
                }
              }
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
