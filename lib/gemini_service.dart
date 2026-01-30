import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class GeminiService {
  String? instagramAccessToken;
  // Reference to InstagramService for authenticated fetching
  dynamic instagramService;

  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';
  static const String _geminiUploadUrl =
      'https://generativelanguage.googleapis.com/upload/v1beta/files';
  static const String _apiKey = "AIzaSyBwk-1wF2ze3pa8BgOcFYDZV2eySw9YthY";

  // Test network connectivity first
  Future<bool> _testNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Extract hashtags from text, returns them without # symbol
  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#(\w+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }

  // Remove hashtags from text to get clean caption
  String _removeHashtags(String text) {
    return text.replaceAll(RegExp(r'#\w+\s*'), '').trim();
  }

  // Analyze Instagram video using Gemini AI
  Future<Map<String, dynamic>?> _analyzeInstagramVideo(
    String videoUrl,
    Map<String, dynamic> metadata,
  ) async {
    try {
      // Download video to temp file
      final videoFile = await instagramService.downloadVideo(videoUrl);
      if (videoFile == null) {
        print('Failed to download video for analysis');
        return null;
      }

      try {
        // Upload video to Gemini Files API
        final fileUri = await _uploadVideoToGemini(videoFile);
        if (fileUri == null) {
          print('Failed to upload video to Gemini');
          return null;
        }

        // Wait for video processing
        await Future.delayed(const Duration(seconds: 3));

        // Send to Gemini for analysis
        final author = metadata['author']?.toString() ?? '';
        final existingCaption = metadata['rawCaption']?.toString() ?? '';
        final hashtags = metadata['hashtags'] as List? ?? [];

        final prompt =
            '''
Analyze this Instagram reel video and provide a detailed summary of its content.

${author.isNotEmpty ? 'Creator: $author' : ''}
${existingCaption.isNotEmpty ? 'Original caption: $existingCaption' : ''}

Please describe:
1. What is happening in the video (main subject, actions, scenes)
2. The key message or purpose of the content
3. Any text overlays, spoken words, or music that's relevant
4. The overall mood/tone of the video

Provide a comprehensive 2-4 sentence description that captures what a viewer would learn or experience from this reel.
''';

        final requestBody = {
          'contents': [
            {
              'parts': [
                {
                  'fileData': {'mimeType': 'video/mp4', 'fileUri': fileUri},
                },
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
        };

        final client = http.Client();
        final response = await client
            .post(
              Uri.parse('$_geminiApiUrl?key=$_apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 60));
        client.close();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null) {
            final summary =
                data['candidates'][0]['content']['parts'][0]['text']
                    ?.toString() ??
                '';

            if (summary.isNotEmpty) {
              final contentType = metadata['contentType']?.toString() ?? 'reel';
              return {
                'title': summary.split('.').first.trim(),
                'description': summary.trim(),
                'author': author,
                'platform': 'Instagram',
                'contentType': contentType,
                'thumbnail': metadata['thumbnail']?.toString() ?? '',
                'publishDate': '',
                'duration': '',
                'viewCount': '',
                'engagement': {},
                'hashtags': hashtags,
                'rawCaption': existingCaption,
                'aiSummary':
                    true, // Flag to indicate this came from AI analysis
              };
            }
          }
        } else {
          print(
            'Gemini video analysis failed: ${response.statusCode} - ${response.body}',
          );
        }
      } finally {
        // Clean up temp file
        try {
          await videoFile.delete();
        } catch (_) {}
      }
    } catch (e) {
      print('Error analyzing Instagram video: $e');
    }
    return null;
  }

  // Upload video to Gemini Files API
  Future<String?> _uploadVideoToGemini(File videoFile) async {
    try {
      final fileBytes = await videoFile.readAsBytes();
      final fileSize = fileBytes.length;

      // Start resumable upload
      final client = http.Client();

      final initResponse = await client.post(
        Uri.parse('$_geminiUploadUrl?key=$_apiKey'),
        headers: {
          'X-Goog-Upload-Protocol': 'resumable',
          'X-Goog-Upload-Command': 'start',
          'X-Goog-Upload-Header-Content-Length': fileSize.toString(),
          'X-Goog-Upload-Header-Content-Type': 'video/mp4',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'file': {'displayName': 'instagram_reel.mp4'},
        }),
      );

      if (initResponse.statusCode != 200) {
        print('Failed to init upload: ${initResponse.statusCode}');
        client.close();
        return null;
      }

      final uploadUrl = initResponse.headers['x-goog-upload-url'];
      if (uploadUrl == null) {
        print('No upload URL in response');
        client.close();
        return null;
      }

      // Upload the file
      final uploadResponse = await client.post(
        Uri.parse(uploadUrl),
        headers: {
          'X-Goog-Upload-Command': 'upload, finalize',
          'X-Goog-Upload-Offset': '0',
          'Content-Type': 'video/mp4',
        },
        body: fileBytes,
      );

      client.close();

      if (uploadResponse.statusCode == 200) {
        final data = jsonDecode(uploadResponse.body);
        final fileUri = data['file']?['uri']?.toString();
        print('Video uploaded to Gemini: $fileUri');
        return fileUri;
      } else {
        print(
          'Failed to upload video: ${uploadResponse.statusCode} - ${uploadResponse.body}',
        );
      }
    } catch (e) {
      print('Error uploading video to Gemini: $e');
    }
    return null;
  }

  // Fetch actual content from URL
  Future<Map<String, dynamic>> _fetchUrlContent(String url) async {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    // For Instagram, use special scraping since normal HTML doesn't work
    if (host.contains('instagram.com')) {
      return _fetchInstagramContent(url);
    }

    // For YouTube Shorts, use special handling
    if ((host.contains('youtube.com') && uri.path.contains('/shorts/')) ||
        host.contains('youtu.be')) {
      return _fetchYouTubeShortsContent(url);
    }

    // For everything else (including YouTube), use standard HTML scraping
    try {
      final client = http.Client();
      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Cache-Control': 'max-age=0',
      };

      final response = await client
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));

      client.close();

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        return _extractContentFromHtml(document, url);
      } else {
        throw Exception('Failed to fetch content: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching content: $e');
      return _analyzeUrlPattern(url);
    }
  }

  // ===== YOUTUBE SHORTS SCRAPING =====

  // Extract video ID from YouTube URL
  String? _extractYouTubeVideoId(String url) {
    final uri = Uri.parse(url);
    // /shorts/VIDEO_ID
    final shortsMatch = RegExp(
      r'/shorts/([A-Za-z0-9_-]+)',
    ).firstMatch(uri.path);
    if (shortsMatch != null) return shortsMatch.group(1);
    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    // ?v=VIDEO_ID
    return uri.queryParameters['v'];
  }

  Future<Map<String, dynamic>> _fetchYouTubeShortsContent(String url) async {
    final videoId = _extractYouTubeVideoId(url);

    // Strategy 1: Fetch the regular /watch?v= page which has richer data
    if (videoId != null) {
      final watchUrl = 'https://www.youtube.com/watch?v=$videoId';
      try {
        final client = http.Client();
        final response = await client
            .get(
              Uri.parse(watchUrl),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept-Language': 'en-US,en;q=0.9',
              },
            )
            .timeout(Duration(seconds: 20));
        client.close();

        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          final result = _extractContentFromHtml(document, watchUrl);
          // Ensure it's marked as a Short
          result['contentType'] = 'short';
          if (result['description']?.toString().isNotEmpty == true ||
              result['rawCaption']?.toString().isNotEmpty == true) {
            return result;
          }
        }
      } catch (e) {
        print('YouTube Shorts watch page fetch failed: $e');
      }
    }

    // Strategy 2: Use oEmbed API to get title/author
    if (videoId != null) {
      try {
        final oembedUrl =
            'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
        final client = http.Client();
        final response = await client
            .get(Uri.parse(oembedUrl))
            .timeout(Duration(seconds: 10));
        client.close();

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final title = data['title']?.toString() ?? '';
          final author = data['author_name']?.toString() ?? '';

          if (title.isNotEmpty) {
            final hashtags = _extractHashtags(title);
            final cleanTitle = _removeHashtags(title);
            return {
              'title': cleanTitle.isNotEmpty ? cleanTitle : title,
              'description': cleanTitle,
              'author': author,
              'platform': 'YouTube',
              'contentType': 'short',
              'thumbnail': data['thumbnail_url']?.toString() ?? '',
              'publishDate': '',
              'duration': '',
              'viewCount': '',
              'engagement': {},
              'hashtags': hashtags,
              'rawCaption': title,
            };
          }
        }
      } catch (e) {
        print('YouTube Shorts oEmbed failed: $e');
      }
    }

    // Strategy 3: Fetch the Shorts page directly
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(Duration(seconds: 20));
      client.close();

      if (response.statusCode == 200) {
        final body = response.body;
        final document = html_parser.parse(body);

        // Try extracting caption from ytInitialData JSON
        String caption = '';
        String author = '';
        final scripts = document.querySelectorAll('script');
        for (final script in scripts) {
          final text = script.text;
          if (text.contains('ytInitialData') ||
              text.contains('ytInitialPlayerResponse')) {
            // Try shortDescription
            final shortDescMatch = RegExp(
              r'"shortDescription"\s*:\s*"((?:[^"\\]|\\.)*)"',
            ).firstMatch(text);
            if (shortDescMatch != null) {
              caption = shortDescMatch
                  .group(1)!
                  .replaceAll('\\n', '\n')
                  .replaceAll('\\r', '')
                  .replaceAll('\\"', '"')
                  .replaceAll('\\\\', '\\');
            }

            // Try to get author/channel name
            final authorMatch = RegExp(
              r'"ownerChannelName"\s*:\s*"((?:[^"\\]|\\.)*)"',
            ).firstMatch(text);
            if (authorMatch != null) {
              author = authorMatch.group(1)!;
            }
            if (author.isEmpty) {
              final authorMatch2 = RegExp(
                r'"author"\s*:\s*"((?:[^"\\]|\\.)*)"',
              ).firstMatch(text);
              if (authorMatch2 != null) {
                author = authorMatch2.group(1)!;
              }
            }

            if (caption.isNotEmpty) break;
          }
        }

        // Fall back to meta tags
        if (caption.isEmpty) {
          caption = _extractMetaDescription(document);
        }
        if (author.isEmpty) {
          author = _extractFromMeta(document, 'name="author"') ?? '';
        }

        final title = _extractTitle(document);
        final hashtags = _extractHashtags('$caption $title');
        final cleanCaption = _removeHashtags(caption);

        return {
          'title': title,
          'description': cleanCaption.isNotEmpty
              ? cleanCaption
              : _removeHashtags(title),
          'author': author,
          'platform': 'YouTube',
          'contentType': 'short',
          'thumbnail': _extractThumbnail(document, url),
          'publishDate': '',
          'duration': '',
          'viewCount': _extractViewCount(document),
          'engagement': {},
          'hashtags': hashtags,
          'rawCaption': caption.isNotEmpty ? caption : title,
        };
      }
    } catch (e) {
      print('YouTube Shorts direct fetch failed: $e');
    }

    // Fallback
    return {
      'title': 'YouTube Short',
      'description': '',
      'author': '',
      'platform': 'YouTube',
      'contentType': 'short',
      'thumbnail': videoId != null
          ? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg'
          : '',
      'publishDate': '',
      'duration': '',
      'viewCount': '',
      'engagement': {},
      'hashtags': <String>[],
      'rawCaption': '',
    };
  }

  // ===== INSTAGRAM SCRAPING =====

  // Fetch Instagram content using multiple strategies
  Future<Map<String, dynamic>> _fetchInstagramContent(String url) async {
    String contentType = 'post';
    if (url.contains('/reel/') || url.contains('/reels/')) {
      contentType = 'reel';
    } else if (url.contains('/p/')) {
      contentType = 'post';
    } else if (url.contains('/stories/')) {
      contentType = 'story';
    } else if (url.contains('/tv/')) {
      contentType = 'igtv';
    }

    // Strategy 0: Use authenticated session + AI video analysis if user has connected Instagram
    if (instagramService != null) {
      try {
        final authResult = await instagramService.fetchWithAuth(url);
        if (authResult != null) {
          final videoUrl = authResult['videoUrl']?.toString() ?? '';

          // Try AI video analysis first for reels/videos
          if (videoUrl.isNotEmpty &&
              (contentType == 'reel' || contentType == 'igtv')) {
            print('Attempting AI video analysis for Instagram $contentType...');
            final videoSummary = await _analyzeInstagramVideo(
              videoUrl,
              authResult,
            );
            if (videoSummary != null && _hasUsefulData(videoSummary)) {
              print('AI video analysis successful!');
              return videoSummary;
            }
            print('AI video analysis failed, falling back to scraped data');
          }

          // Fall back to scraped caption data
          if (_hasUsefulData(authResult)) {
            print('Using authenticated scraped data');
            return authResult;
          }
        }
      } catch (e) {
        print('Instagram authenticated strategy failed: $e');
      }
    }

    // Strategy 1: Try fetching HTML with og: meta tags
    Map<String, dynamic>? result = await _scrapeInstagramHtml(url, contentType);
    if (result != null && _hasUsefulData(result)) {
      return result;
    }

    // Strategy 2: Try noembed.com oEmbed proxy
    result = await _scrapeInstagramOEmbed(url, contentType);
    if (result != null && _hasUsefulData(result)) {
      return result;
    }

    // Strategy 3: Try fetching with different user agent (mobile)
    result = await _scrapeInstagramMobile(url, contentType);
    if (result != null && _hasUsefulData(result)) {
      return result;
    }

    // Strategy 4: Try adding ?__a=1&__d=dis to the URL
    result = await _scrapeInstagramApi(url, contentType);
    if (result != null && _hasUsefulData(result)) {
      return result;
    }

    // Fallback
    return {
      'title': 'Instagram ${contentType}',
      'description': '',
      'author': '',
      'platform': 'Instagram',
      'contentType': contentType,
      'thumbnail': '',
      'publishDate': '',
      'duration': '',
      'viewCount': '',
      'engagement': {},
      'hashtags': <String>[],
      'rawCaption': '',
    };
  }

  bool _hasUsefulData(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? '';
    final desc = data['description']?.toString() ?? '';
    final author = data['author']?.toString() ?? '';
    final rawCaption = data['rawCaption']?.toString() ?? '';
    return title.length > 15 ||
        desc.isNotEmpty ||
        author.isNotEmpty ||
        rawCaption.isNotEmpty;
  }

  // Strategy 1: Standard HTML scraping with og: meta tags
  Future<Map<String, dynamic>?> _scrapeInstagramHtml(
    String url,
    String contentType,
  ) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
              'Cookie': 'ig_cb=1',
            },
          )
          .timeout(Duration(seconds: 15));
      client.close();

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final ogDesc =
            _extractFromMeta(document, 'property="og:description"') ?? '';
        final ogTitle = _extractFromMeta(document, 'property="og:title"') ?? '';
        final twitterDesc =
            _extractFromMeta(document, 'name="twitter:description"') ?? '';
        final twitterTitle =
            _extractFromMeta(document, 'name="twitter:title"') ?? '';
        final metaDesc = _extractFromMeta(document, 'name="description"') ?? '';

        // Pick the richest text available
        String rawText = '';
        for (final candidate in [
          ogDesc,
          twitterDesc,
          metaDesc,
          ogTitle,
          twitterTitle,
        ]) {
          if (candidate.length > rawText.length) {
            rawText = candidate;
          }
        }

        if (rawText.isEmpty) return null;

        final hashtags = _extractHashtags(rawText);
        final cleanText = _removeHashtags(rawText);

        // Extract author from title patterns like "Name (@username)"
        String author = '';
        if (ogTitle.contains('(@')) {
          final match = RegExp(r'\(@([^)]+)\)').firstMatch(ogTitle);
          if (match != null) author = '@${match.group(1)}';
        } else if (ogTitle.contains('•')) {
          author = ogTitle.split('•')[0].trim();
          if (!author.startsWith('@')) author = '@$author';
        }

        return {
          'title': cleanText.isNotEmpty ? cleanText : ogTitle,
          'description': cleanText,
          'author': author,
          'platform': 'Instagram',
          'contentType': contentType,
          'thumbnail': _extractFromMeta(document, 'property="og:image"') ?? '',
          'publishDate': '',
          'duration': '',
          'viewCount': '',
          'engagement': {},
          'hashtags': hashtags,
          'rawCaption': rawText,
        };
      }
    } catch (e) {
      print('Instagram HTML scraping failed: $e');
    }
    return null;
  }

  // Strategy 2: noembed.com oEmbed proxy
  Future<Map<String, dynamic>?> _scrapeInstagramOEmbed(
    String url,
    String contentType,
  ) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(
              'https://noembed.com/embed?url=${Uri.encodeComponent(url)}',
            ),
          )
          .timeout(Duration(seconds: 15));
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['error'] == null) {
          final caption = data['title']?.toString() ?? '';
          final author = data['author_name']?.toString() ?? '';

          if (caption.isEmpty && author.isEmpty) return null;

          final hashtags = _extractHashtags(caption);
          final cleanCaption = _removeHashtags(caption);

          return {
            'title': cleanCaption.isNotEmpty
                ? cleanCaption
                : 'Instagram $contentType',
            'description': cleanCaption,
            'author': author.isNotEmpty
                ? (author.startsWith('@') ? author : '@$author')
                : '',
            'platform': 'Instagram',
            'contentType': contentType,
            'thumbnail': data['thumbnail_url']?.toString() ?? '',
            'publishDate': '',
            'duration': '',
            'viewCount': '',
            'engagement': {},
            'hashtags': hashtags,
            'rawCaption': caption,
          };
        }
      }
    } catch (e) {
      print('Instagram oEmbed failed: $e');
    }
    return null;
  }

  // Strategy 3: Mobile user agent scraping
  Future<Map<String, dynamic>?> _scrapeInstagramMobile(
    String url,
    String contentType,
  ) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(Duration(seconds: 15));
      client.close();

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final ogDesc =
            _extractFromMeta(document, 'property="og:description"') ?? '';
        final ogTitle = _extractFromMeta(document, 'property="og:title"') ?? '';

        String rawText = ogDesc.isNotEmpty ? ogDesc : ogTitle;
        if (rawText.isEmpty) {
          // Try to find caption in embedded JSON data
          final scripts = document.querySelectorAll('script');
          for (final script in scripts) {
            final text = script.text;
            if (text.contains('"caption"') ||
                text.contains('"edge_media_to_caption"')) {
              // Try to extract caption from JSON
              final captionMatch = RegExp(
                r'"text"\s*:\s*"([^"]+)"',
              ).firstMatch(text);
              if (captionMatch != null) {
                rawText = captionMatch
                    .group(1)!
                    .replaceAll('\\n', ' ')
                    .replaceAll('\\u0040', '@');
                break;
              }
            }
          }
        }

        if (rawText.isEmpty) return null;

        final hashtags = _extractHashtags(rawText);
        final cleanText = _removeHashtags(rawText);

        String author = '';
        if (ogTitle.contains('(@')) {
          final match = RegExp(r'\(@([^)]+)\)').firstMatch(ogTitle);
          if (match != null) author = '@${match.group(1)}';
        }

        return {
          'title': cleanText.isNotEmpty ? cleanText : ogTitle,
          'description': cleanText,
          'author': author,
          'platform': 'Instagram',
          'contentType': contentType,
          'thumbnail': _extractFromMeta(document, 'property="og:image"') ?? '',
          'publishDate': '',
          'duration': '',
          'viewCount': '',
          'engagement': {},
          'hashtags': hashtags,
          'rawCaption': rawText,
        };
      }
    } catch (e) {
      print('Instagram mobile scraping failed: $e');
    }
    return null;
  }

  // Strategy 4: Try Instagram's internal API endpoint
  Future<Map<String, dynamic>?> _scrapeInstagramApi(
    String url,
    String contentType,
  ) async {
    try {
      // Extract shortcode from URL
      final shortcodeMatch = RegExp(
        r'/(p|reel|reels|tv)/([A-Za-z0-9_-]+)',
      ).firstMatch(url);
      if (shortcodeMatch == null) return null;

      final apiUrl = '${url.split('?')[0]}?__a=1&__d=dis';
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(apiUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
              'Accept': 'application/json, text/plain, */*',
              'X-Requested-With': 'XMLHttpRequest',
            },
          )
          .timeout(Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          // Navigate the JSON structure to find caption
          String caption = '';
          String author = '';

          if (data is Map) {
            // Try graphql structure
            final item =
                data['graphql']?['shortcode_media'] ??
                data['items']?[0] ??
                data;

            if (item is Map) {
              // Get caption
              final captionEdges = item['edge_media_to_caption']?['edges'];
              if (captionEdges is List && captionEdges.isNotEmpty) {
                caption = captionEdges[0]['node']?['text']?.toString() ?? '';
              }
              caption = caption.isEmpty
                  ? (item['caption']?['text']?.toString() ?? '')
                  : caption;

              // Get author
              author =
                  item['owner']?['username']?.toString() ??
                  item['user']?['username']?.toString() ??
                  '';
            }
          }

          if (caption.isEmpty && author.isEmpty) return null;

          final hashtags = _extractHashtags(caption);
          final cleanCaption = _removeHashtags(caption);

          return {
            'title': cleanCaption.isNotEmpty
                ? cleanCaption
                : 'Instagram $contentType',
            'description': cleanCaption,
            'author': author.isNotEmpty ? '@$author' : '',
            'platform': 'Instagram',
            'contentType': contentType,
            'thumbnail': '',
            'publishDate': '',
            'duration': '',
            'viewCount': '',
            'engagement': {},
            'hashtags': hashtags,
            'rawCaption': caption,
          };
        } catch (e) {
          print('Instagram API JSON parse failed: $e');
        }
      }
    } catch (e) {
      print('Instagram API scraping failed: $e');
    }
    return null;
  }

  // ===== HTML CONTENT EXTRACTION =====

  // Extract content from HTML document
  Map<String, dynamic> _extractContentFromHtml(
    dom.Document document,
    String url,
  ) {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    Map<String, dynamic> contentData = {
      'title': '',
      'description': '',
      'author': '',
      'platform': '',
      'contentType': '',
      'thumbnail': '',
      'publishDate': '',
      'duration': '',
      'viewCount': '',
      'engagement': {},
      'hashtags': <String>[],
      'rawCaption': '',
    };

    // Extract basic meta information
    contentData['title'] = _extractTitle(document);
    final rawDesc = _extractMetaDescription(document);
    contentData['thumbnail'] = _extractThumbnail(document, url);

    // Extract hashtags from description and clean it
    final hashtags = _extractHashtags(rawDesc);
    contentData['description'] = _removeHashtags(rawDesc);
    contentData['hashtags'] = hashtags;
    contentData['rawCaption'] = rawDesc;

    // Platform-specific extraction
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      final ytData = _extractYouTubeContent(document);
      contentData.addAll(ytData);

      // If we scraped a full caption, use it for description and hashtags
      final caption = ytData['caption']?.toString() ?? '';
      if (caption.isNotEmpty) {
        final captionHashtags = _extractHashtags(caption);
        final cleanCaption = _removeHashtags(caption);
        // Merge all hashtags: from meta description, title, and caption
        final titleHashtags = _extractHashtags(contentData['title'] ?? '');
        final allHashtags = <String>{
          ...hashtags,
          ...titleHashtags,
          ...captionHashtags,
        }.toList();
        contentData['hashtags'] = allHashtags;
        contentData['rawCaption'] = caption;
        // Use caption as description if it's richer than meta description
        if (cleanCaption.length >
            (contentData['description']?.toString().length ?? 0)) {
          contentData['description'] = cleanCaption;
        }
      } else {
        // Still extract hashtags from title
        final titleHashtags = _extractHashtags(contentData['title'] ?? '');
        if (titleHashtags.isNotEmpty) {
          final allHashtags = <String>{...hashtags, ...titleHashtags}.toList();
          contentData['hashtags'] = allHashtags;
        }
      }
    } else {
      contentData.addAll(_extractGenericContent(document, host));
    }

    return contentData;
  }

  // YouTube content extraction — same as original + caption scraping
  Map<String, dynamic> _extractYouTubeContent(dom.Document document) {
    // Try to extract the full video caption/description from embedded JS data
    String caption = '';
    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final text = script.text;
      if (text.contains('ytInitialPlayerResponse') ||
          text.contains('ytInitialData')) {
        // Extract shortDescription from ytInitialPlayerResponse
        final shortDescMatch = RegExp(
          r'"shortDescription"\s*:\s*"((?:[^"\\]|\\.)*)"',
        ).firstMatch(text);
        if (shortDescMatch != null) {
          caption = shortDescMatch
              .group(1)!
              .replaceAll('\\n', '\n')
              .replaceAll('\\r', '')
              .replaceAll('\\"', '"')
              .replaceAll('\\\\', '\\');
          break;
        }
        // Fallback: try description field
        final descMatch = RegExp(
          r'"description"\s*:\s*\{\s*"simpleText"\s*:\s*"((?:[^"\\]|\\.)*)"',
        ).firstMatch(text);
        if (descMatch != null) {
          caption = descMatch
              .group(1)!
              .replaceAll('\\n', '\n')
              .replaceAll('\\r', '')
              .replaceAll('\\"', '"')
              .replaceAll('\\\\', '\\');
          break;
        }
      }
    }

    return {
      'platform': 'YouTube',
      'contentType': 'video',
      'author':
          _extractFromMeta(document, 'name="author"') ??
          _extractFromJsonLd(document, 'author') ??
          _extractChannelName(document),
      'duration':
          _extractFromMeta(document, 'property="video:duration"') ??
          _extractFromJsonLd(document, 'duration'),
      'viewCount': _extractViewCount(document),
      'publishDate':
          _extractFromMeta(document, 'property="video:release_date"') ??
          _extractFromJsonLd(document, 'uploadDate'),
      'engagement': {
        'likes': _extractEngagementCount(document, 'like'),
        'comments': _extractEngagementCount(document, 'comment'),
      },
      if (caption.isNotEmpty) 'caption': caption,
    };
  }

  // Generic content extraction for unknown platforms
  Map<String, dynamic> _extractGenericContent(
    dom.Document document,
    String host,
  ) {
    final contentType = _determineGenericContentType(document);
    return {
      'platform': _formatPlatformName(host),
      'contentType': contentType,
      'author': _extractGenericAuthor(document),
      'publishDate':
          _extractFromMeta(document, 'property="article:published_time"') ??
          _extractFromMeta(document, 'name="date"'),
    };
  }

  // ===== HELPER METHODS =====

  String _extractTitle(dom.Document document) {
    return document.querySelector('title')?.text.trim() ??
        _extractFromMeta(document, 'property="og:title"') ??
        _extractFromMeta(document, 'name="twitter:title"') ??
        '';
  }

  String _extractMetaDescription(dom.Document document) {
    return _extractFromMeta(document, 'name="description"') ??
        _extractFromMeta(document, 'property="og:description"') ??
        _extractFromMeta(document, 'name="twitter:description"') ??
        '';
  }

  String _extractThumbnail(dom.Document document, String baseUrl) {
    final thumbnail =
        _extractFromMeta(document, 'property="og:image"') ??
        _extractFromMeta(document, 'name="twitter:image"') ??
        '';

    if (thumbnail.startsWith('//')) {
      return 'https:$thumbnail';
    } else if (thumbnail.startsWith('/')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}$thumbnail';
    }
    return thumbnail;
  }

  String? _extractFromMeta(dom.Document document, String selector) {
    final element = document.querySelector('meta[$selector]');
    return element?.attributes['content']?.trim();
  }

  String? _extractFromJsonLd(dom.Document document, String property) {
    try {
      final jsonLdElements = document.querySelectorAll(
        'script[type="application/ld+json"]',
      );
      for (final element in jsonLdElements) {
        final jsonData = jsonDecode(element.text);
        if (jsonData is Map && jsonData.containsKey(property)) {
          return jsonData[property]?.toString();
        }
      }
    } catch (e) {
      // Ignore JSON parsing errors
    }
    return null;
  }

  String _extractChannelName(dom.Document document) {
    return document
            .querySelector('span[itemprop="author"] link[itemprop="name"]')
            ?.attributes['content'] ??
        document.querySelector('.ytd-channel-name a')?.text.trim() ??
        '';
  }

  String _extractViewCount(dom.Document document) {
    return document
            .querySelector('meta[itemprop="interactionCount"]')
            ?.attributes['content'] ??
        document.querySelector('.view-count')?.text.trim() ??
        '';
  }

  String _extractEngagementCount(dom.Document document, String type) {
    return document
            .querySelector('button[aria-label*="$type"] span')
            ?.text
            .trim() ??
        '';
  }

  String _determineGenericContentType(dom.Document document) {
    if (document.querySelector('video') != null) return 'video';
    if (document.querySelector('audio') != null) return 'audio';
    if (document.querySelector('article') != null) return 'article';
    if (document.querySelector('img') != null &&
        document.querySelectorAll('img').length >
            document.querySelectorAll('p').length) {
      return 'image';
    }
    return 'webpage';
  }

  String _extractGenericAuthor(dom.Document document) {
    return _extractFromMeta(document, 'name="author"') ??
        document.querySelector('.author')?.text.trim() ??
        document.querySelector('[rel="author"]')?.text.trim() ??
        document.querySelector('.byline')?.text.trim() ??
        '';
  }

  String _formatPlatformName(String host) {
    return host
        .replaceAll('www.', '')
        .split('.')
        .first
        .toLowerCase()
        .split('')
        .asMap()
        .map((i, char) => MapEntry(i, i == 0 ? char.toUpperCase() : char))
        .values
        .join('');
  }

  // ===== URL PATTERN FALLBACK =====

  Map<String, dynamic> _analyzeUrlPattern(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return {
        'title': 'Unknown Content',
        'description': 'Unable to analyze this URL',
        'author': '',
        'platform': 'Unknown',
        'contentType': 'unknown',
      };
    }

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      final isShort = path.contains('/shorts/');
      return {
        'title': isShort ? 'YouTube Short' : 'YouTube Video',
        'description': isShort
            ? 'Short video content from YouTube'
            : 'Video content from YouTube',
        'author': '',
        'platform': 'YouTube',
        'contentType': isShort ? 'short' : 'video',
      };
    } else if (host.contains('instagram.com')) {
      String contentType = 'post';
      if (path.contains('/reel/') || path.contains('/reels/')) {
        contentType = 'reel';
      } else if (path.contains('/stories/')) {
        contentType = 'story';
      } else if (path.contains('/tv/')) {
        contentType = 'igtv';
      }

      return {
        'title': 'Instagram ${contentType.toUpperCase()}',
        'description': 'Content from Instagram',
        'author': '',
        'platform': 'Instagram',
        'contentType': contentType,
      };
    }

    return {
      'title': 'Web Content',
      'description': 'Content from ${_formatPlatformName(host)}',
      'author': '',
      'platform': _formatPlatformName(host),
      'contentType': 'webpage',
    };
  }

  // ===== MAIN GENERATION METHOD =====

  Future<Map<String, String>> generateDetailsFromUrl(
    String url, {
    List<String>? existingCollections,
  }) async {
    try {
      print('Testing network connectivity...');

      bool hasConnection = await _testNetworkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      print('Network connectivity OK');
      print('Fetching and analyzing content from URL: $url');

      final contentData = await _fetchUrlContent(url);

      print('Content fetched successfully');
      print(
        'Platform: ${contentData['platform']}, Author: ${contentData['author']}',
      );

      // Build collections context for the prompt
      String collectionsContext = '';
      if (existingCollections != null && existingCollections.isNotEmpty) {
        final validCollections = existingCollections
            .where((c) => c != 'Create New')
            .toList();
        if (validCollections.isNotEmpty) {
          collectionsContext =
              '''

          The user has the following existing collections: ${validCollections.join(', ')}

          For the collection recommendation:
          - If the content matches any of these existing collections, choose the most appropriate one
          - If none of the existing collections are suitable, suggest a new collection name that best describes the content's category
          ''';
        }
      }

      final prompt = _buildDetailedPrompt(url, contentData, collectionsContext);

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
      };

      final client = http.Client();

      try {
        print('Sending detailed content analysis request...');
        final response = await client
            .post(
              Uri.parse('$_geminiApiUrl?key=$_apiKey'),
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'Flutter/1.0',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              Duration(seconds: 45),
              onTimeout: () {
                throw TimeoutException(
                  'Content analysis timed out',
                  Duration(seconds: 45),
                );
              },
            );

        print('Response received - Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('Response parsed successfully');

          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null) {
            final generatedText =
                data['candidates'][0]['content']['parts'][0]['text'];
            print(
              'Generated analysis: ${generatedText.substring(0, math.min(200, generatedText.length))}...',
            );

            try {
              final cleanedText = _cleanJsonResponse(generatedText);
              final generatedData = jsonDecode(cleanedText);
              return {
                'tags':
                    generatedData['tags'] ?? _generateFallbackTags(contentData),
                'description':
                    generatedData['description'] ??
                    _generateFallbackDescription(contentData),
                'collection':
                    generatedData['collection'] ??
                    _generateFallbackCollection(
                      contentData,
                      existingCollections,
                    ),
              };
            } catch (e) {
              print('JSON parsing failed: $e');
              return {
                'tags':
                    _extractTagsFromText(generatedText) ??
                    _generateFallbackTags(contentData),
                'description':
                    _extractDescription(generatedText) ??
                    _generateFallbackDescription(contentData),
                'collection':
                    _extractCollection(generatedText, existingCollections) ??
                    _generateFallbackCollection(
                      contentData,
                      existingCollections,
                    ),
              };
            }
          } else {
            throw Exception('Unexpected response structure: ${response.body}');
          }
        } else if (response.statusCode == 400) {
          final errorData = jsonDecode(response.body);
          print('API Error 400: $errorData');
          return _generateFallbackResponse(contentData, existingCollections);
        } else if (response.statusCode == 403) {
          throw Exception('API Key error: Please check your Gemini API key');
        } else {
          print('HTTP Error ${response.statusCode}: ${response.body}');
          return _generateFallbackResponse(contentData, existingCollections);
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    } catch (e) {
      print('General error: $e');
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    }
  }

  // ===== GEMINI PROMPT =====

  String _buildDetailedPrompt(
    String url,
    Map<String, dynamic> contentData,
    String collectionsContext,
  ) {
    final platform = contentData['platform'] ?? 'Unknown';
    final contentType = contentData['contentType'] ?? 'content';
    final title = contentData['title'] ?? '';
    final description = contentData['description'] ?? '';
    final author = contentData['author'] ?? '';
    final publishDate = contentData['publishDate'] ?? '';
    final duration = contentData['duration'] ?? '';
    final viewCount = contentData['viewCount'] ?? '';
    final engagement = contentData['engagement'] ?? {};
    final hashtags = contentData['hashtags'] ?? [];
    final rawCaption = contentData['rawCaption'] ?? '';

    return '''
    Analyze this $contentType from $platform and provide detailed insights:

    URL: $url
    Platform: $platform
    Content Type: $contentType
    Title: $title
    Description/Caption: $description
    Full Raw Caption: $rawCaption
    Author/Creator: $author
    Publish Date: $publishDate
    ${duration.toString().isNotEmpty ? 'Duration: $duration' : ''}
    ${viewCount.toString().isNotEmpty ? 'View Count: $viewCount' : ''}
    ${engagement is Map && engagement.isNotEmpty ? 'Engagement Data: ${engagement.toString()}' : ''}
    ${hashtags is List && hashtags.isNotEmpty ? 'Hashtags found in content: ${hashtags.join(', ')}' : ''}
    $collectionsContext

    Based on this detailed content information, please provide:

    1. "tags": Extract ALL hashtags from the content. Return them as comma-separated values WITHOUT the # symbol. ${hashtags is List && hashtags.isNotEmpty ? 'The following hashtags were found: ${hashtags.join(', ')}. Include all of them.' : 'If no hashtags exist, suggest relevant topic tags based on the content.'} Example: "fitness, motivation, workout, gym"

    2. "description": Write a comprehensive description (2-3 sentences) that includes:
       - The caption/title of the content
       - Who created it (author name)
       - Key details like duration, view count, engagement metrics if available
       - What users can expect when they access this content
       - Do NOT include any hashtags in the description

    3. "collection": A collection name recommendation.
       ${collectionsContext.isNotEmpty ? '- Choose from existing collections if appropriate' : '- Suggest a new collection name'}
       - Collection names should be broad categories that group similar content types

    Please respond ONLY in this JSON format:
    {
      "tags": "comma, separated, tags, without, hash, symbol",
      "description": "comprehensive description with caption and details, no hashtags",
      "collection": "recommended_collection_name"
    }
    ''';
  }

  // ===== FALLBACK METHODS =====

  Map<String, String> _generateFallbackResponse(
    Map<String, dynamic> contentData,
    List<String>? existingCollections,
  ) {
    return {
      'tags': _generateFallbackTags(contentData),
      'description': _generateFallbackDescription(contentData),
      'collection': _generateFallbackCollection(
        contentData,
        existingCollections,
      ),
    };
  }

  String _generateFallbackTags(Map<String, dynamic> contentData) {
    final hashtags = contentData['hashtags'];
    if (hashtags is List && hashtags.isNotEmpty) {
      return hashtags.join(', ');
    }
    final platform = contentData['platform'] ?? 'web';
    final contentType = contentData['contentType'] ?? 'content';
    return '$platform, $contentType';
  }

  String _generateFallbackDescription(Map<String, dynamic> contentData) {
    final platform = contentData['platform'] ?? 'web platform';
    final contentType = contentData['contentType'] ?? 'content';
    final author = contentData['author'] ?? '';
    final title = contentData['title'] ?? '';
    final description = contentData['description'] ?? '';
    final rawCaption = contentData['rawCaption'] ?? '';
    final duration = contentData['duration'] ?? '';
    final viewCount = contentData['viewCount'] ?? '';

    // Use clean text (without hashtags) for description
    String cleanText = description.isNotEmpty
        ? _removeHashtags(description)
        : _removeHashtags(rawCaption);

    String baseDescription = '';
    if (cleanText.isNotEmpty) {
      baseDescription = cleanText;
    } else if (title.isNotEmpty) {
      baseDescription = 'Content titled "$title"';
    } else {
      baseDescription = 'Content from $platform';
    }

    String creatorInfo = author.isNotEmpty ? ' created by $author' : '';
    String additionalInfo = '';

    if (duration.toString().isNotEmpty && viewCount.toString().isNotEmpty) {
      additionalInfo = ' Duration: $duration, Views: $viewCount.';
    } else if (duration.toString().isNotEmpty) {
      additionalInfo = ' Duration: $duration.';
    } else if (viewCount.toString().isNotEmpty) {
      additionalInfo = ' Views: $viewCount.';
    }

    return 'This is $contentType$creatorInfo on $platform.$additionalInfo $baseDescription';
  }

  String _generateFallbackCollection(
    Map<String, dynamic> contentData,
    List<String>? existingCollections,
  ) {
    final contentType = contentData['contentType'] ?? 'content';
    final platform = contentData['platform'] ?? 'Web';

    if (existingCollections != null) {
      final validCollections = existingCollections
          .where((c) => c != 'Create New')
          .toList();

      for (String existing in validCollections) {
        final existingLower = existing.toLowerCase();

        if ((contentType == 'video' &&
                (existingLower.contains('video') ||
                    existingLower.contains('youtube') ||
                    existingLower.contains('media'))) ||
            (contentType == 'reel' &&
                (existingLower.contains('reel') ||
                    existingLower.contains('short') ||
                    existingLower.contains('instagram') ||
                    existingLower.contains('video'))) ||
            (contentType == 'post' &&
                (existingLower.contains('instagram') ||
                    existingLower.contains('social') ||
                    existingLower.contains('post'))) ||
            (contentType == 'story' &&
                (existingLower.contains('story') ||
                    existingLower.contains('instagram'))) ||
            (contentType == 'igtv' &&
                (existingLower.contains('igtv') ||
                    existingLower.contains('instagram') ||
                    existingLower.contains('video'))) ||
            (platform.toLowerCase() == existingLower)) {
          return existing;
        }
      }
    }

    if (platform.toLowerCase() == 'youtube') {
      if (contentType == 'short') return 'YouTube Shorts';
      return 'YouTube Videos';
    } else if (platform.toLowerCase() == 'instagram') {
      switch (contentType) {
        case 'reel':
          return 'Instagram Reels';
        case 'post':
          return 'Instagram Posts';
        case 'story':
          return 'Instagram Stories';
        case 'igtv':
          return 'Instagram Videos';
        default:
          return 'Instagram Content';
      }
    }

    switch (contentType) {
      case 'video':
        return 'Videos';
      case 'reel':
        return 'Short Videos';
      case 'post':
        return 'Social Media';
      case 'story':
        return 'Stories';
      default:
        return platform == 'Web' ? 'Web Links' : platform;
    }
  }

  // ===== RESPONSE PARSING =====

  String _cleanJsonResponse(String text) {
    text = text.replaceAll('```json', '').replaceAll('```', '');
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }
    return text;
  }

  String? _extractTagsFromText(String text) {
    final tagMatch = RegExp(r'"tags":\s*"([^"]*)"').firstMatch(text);
    return tagMatch?.group(1);
  }

  String? _extractDescription(String text) {
    final descMatch = RegExp(r'"description":\s*"([^"]*)"').firstMatch(text);
    return descMatch?.group(1);
  }

  String? _extractCollection(String text, List<String>? existingCollections) {
    final collectionMatch = RegExp(
      r'"collection":\s*"([^"]*)"',
    ).firstMatch(text);
    final extractedCollection = collectionMatch?.group(1);

    if (extractedCollection != null) {
      if (existingCollections != null) {
        final validCollections = existingCollections
            .where((c) => c != 'Create New')
            .toList();
        for (String existing in validCollections) {
          if (existing.toLowerCase() == extractedCollection.toLowerCase()) {
            return existing;
          }
        }
      }
      return extractedCollection;
    }
    return null;
  }
}
