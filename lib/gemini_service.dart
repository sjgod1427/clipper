// import 'dart:convert';
// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;
// import 'package:http/http.dart' as http;
// import 'package:html/parser.dart' as html_parser;
// import 'package:html/dom.dart' as dom;

// class GeminiService {
//   static const String _geminiApiUrl =
//       'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';
//   static const String _apiKey =
//       "AIzaSyBwk-1wF2ze3pa8BgOcFYDZV2eySw9YthY"; // Replace with your actual API key

//   // Test network connectivity first
//   Future<bool> _testNetworkConnectivity() async {
//     try {
//       final result = await InternetAddress.lookup('google.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Fetch actual content from URL
//   Future<Map<String, dynamic>> _fetchUrlContent(String url) async {
//     try {
//       final client = http.Client();
//       final headers = {
//         'User-Agent':
//             'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
//         'Accept':
//             'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
//         'Accept-Language': 'en-US,en;q=0.5',
//         'Accept-Encoding': 'gzip, deflate',
//         'Connection': 'keep-alive',
//         'Upgrade-Insecure-Requests': '1',
//       };

//       final response = await client
//           .get(Uri.parse(url), headers: headers)
//           .timeout(Duration(seconds: 30));

//       client.close();

//       if (response.statusCode == 200) {
//         final document = html_parser.parse(response.body);
//         return _extractContentFromHtml(document, url);
//       } else {
//         throw Exception('Failed to fetch content: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching content: $e');
//       return _analyzeUrlPattern(url);
//     }
//   }

//   // Extract content from HTML document
//   Map<String, dynamic> _extractContentFromHtml(
//     dom.Document document,
//     String url,
//   ) {
//     final uri = Uri.parse(url);
//     final host = uri.host.toLowerCase();

//     Map<String, dynamic> contentData = {
//       'title': '',
//       'description': '',
//       'author': '',
//       'platform': '',
//       'contentType': '',
//       'thumbnail': '',
//       'publishDate': '',
//       'duration': '',
//       'viewCount': '',
//       'engagement': {},
//     };

//     // Extract basic meta information
//     contentData['title'] = _extractTitle(document);
//     contentData['description'] = _extractMetaDescription(document);
//     contentData['thumbnail'] = _extractThumbnail(document, url);

//     // Platform-specific extraction
//     if (host.contains('youtube.com') || host.contains('youtu.be')) {
//       contentData.addAll(_extractYouTubeContent(document));
//     } else if (host.contains('instagram.com')) {
//       contentData.addAll(_extractInstagramContent(document));
//     } else if (host.contains('tiktok.com')) {
//       contentData.addAll(_extractTikTokContent(document));
//     } else if (host.contains('twitter.com') || host.contains('x.com')) {
//       contentData.addAll(_extractTwitterContent(document));
//     } else if (host.contains('facebook.com')) {
//       contentData.addAll(_extractFacebookContent(document));
//     } else if (host.contains('linkedin.com')) {
//       contentData.addAll(_extractLinkedInContent(document));
//     } else if (host.contains('reddit.com')) {
//       contentData.addAll(_extractRedditContent(document));
//     } else if (host.contains('vimeo.com')) {
//       contentData.addAll(_extractVimeoContent(document));
//     } else if (host.contains('twitch.tv')) {
//       contentData.addAll(_extractTwitchContent(document));
//     } else if (host.contains('github.com')) {
//       contentData.addAll(_extractGitHubContent(document));
//     } else if (host.contains('medium.com')) {
//       contentData.addAll(_extractMediumContent(document));
//     } else if (host.contains('pinterest.com')) {
//       contentData.addAll(_extractPinterestContent(document));
//     } else if (host.contains('spotify.com')) {
//       contentData.addAll(_extractSpotifyContent(document));
//     } else if (host.contains('soundcloud.com')) {
//       contentData.addAll(_extractSoundCloudContent(document));
//     } else {
//       contentData.addAll(_extractGenericContent(document, host));
//     }

//     return contentData;
//   }

//   // YouTube content extraction
//   Map<String, dynamic> _extractYouTubeContent(dom.Document document) {
//     return {
//       'platform': 'YouTube',
//       'contentType': 'video',
//       'author':
//           _extractFromMeta(document, 'name="author"') ??
//           _extractFromJsonLd(document, 'author') ??
//           _extractChannelName(document),
//       'duration':
//           _extractFromMeta(document, 'property="video:duration"') ??
//           _extractFromJsonLd(document, 'duration'),
//       'viewCount': _extractViewCount(document),
//       'publishDate':
//           _extractFromMeta(document, 'property="video:release_date"') ??
//           _extractFromJsonLd(document, 'uploadDate'),
//       'engagement': {
//         'likes': _extractEngagementCount(document, 'like'),
//         'comments': _extractEngagementCount(document, 'comment'),
//       },
//     };
//   }

//   // Instagram content extraction
//   Map<String, dynamic> _extractInstagramContent(dom.Document document) {
//     return {
//       'platform': 'Instagram',
//       'contentType': _determineInstagramContentType(document),
//       'author':
//           _extractFromMeta(document, 'property="instapp:owner_user_id"') ??
//           _extractFromJsonLd(document, 'author') ??
//           _extractInstagramUsername(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//       'engagement': {
//         'likes': _extractInstagramLikes(document),
//         'comments': _extractInstagramComments(document),
//       },
//     };
//   }

//   // TikTok content extraction
//   Map<String, dynamic> _extractTikTokContent(dom.Document document) {
//     return {
//       'platform': 'TikTok',
//       'contentType': 'short_video',
//       'author':
//           _extractFromMeta(document, 'name="author"') ??
//           _extractTikTokUsername(document),
//       'duration': _extractFromJsonLd(document, 'duration'),
//       'viewCount': _extractTikTokViews(document),
//       'engagement': {
//         'likes': _extractTikTokLikes(document),
//         'shares': _extractTikTokShares(document),
//         'comments': _extractTikTokComments(document),
//       },
//     };
//   }

//   // Twitter/X content extraction
//   Map<String, dynamic> _extractTwitterContent(dom.Document document) {
//     return {
//       'platform': 'Twitter/X',
//       'contentType': 'tweet',
//       'author':
//           _extractFromMeta(document, 'name="twitter:creator"') ??
//           _extractTwitterUsername(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//       'engagement': {
//         'retweets': _extractTwitterRetweets(document),
//         'likes': _extractTwitterLikes(document),
//         'replies': _extractTwitterReplies(document),
//       },
//     };
//   }

//   // Facebook content extraction
//   Map<String, dynamic> _extractFacebookContent(dom.Document document) {
//     return {
//       'platform': 'Facebook',
//       'contentType': 'post',
//       'author':
//           _extractFromMeta(document, 'property="og:site_name"') ??
//           _extractFacebookPageName(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//     };
//   }

//   // LinkedIn content extraction
//   Map<String, dynamic> _extractLinkedInContent(dom.Document document) {
//     return {
//       'platform': 'LinkedIn',
//       'contentType': 'professional_post',
//       'author': _extractLinkedInAuthor(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//     };
//   }

//   // Reddit content extraction
//   Map<String, dynamic> _extractRedditContent(dom.Document document) {
//     return {
//       'platform': 'Reddit',
//       'contentType': 'discussion',
//       'author': _extractRedditUsername(document),
//       'subreddit': _extractSubreddit(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//       'engagement': {
//         'upvotes': _extractRedditUpvotes(document),
//         'comments': _extractRedditComments(document),
//       },
//     };
//   }

//   // Vimeo content extraction
//   Map<String, dynamic> _extractVimeoContent(dom.Document document) {
//     return {
//       'platform': 'Vimeo',
//       'contentType': 'video',
//       'author':
//           _extractFromMeta(document, 'name="author"') ??
//           _extractVimeoAuthor(document),
//       'duration': _extractFromMeta(document, 'property="video:duration"'),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="video:release_date"',
//       ),
//     };
//   }

//   // Twitch content extraction
//   Map<String, dynamic> _extractTwitchContent(dom.Document document) {
//     return {
//       'platform': 'Twitch',
//       'contentType': 'stream',
//       'author':
//           _extractFromMeta(document, 'name="twitter:creator"') ??
//           _extractTwitchStreamer(document),
//       'viewCount': _extractTwitchViewers(document),
//     };
//   }

//   // GitHub content extraction
//   Map<String, dynamic> _extractGitHubContent(dom.Document document) {
//     return {
//       'platform': 'GitHub',
//       'contentType': 'repository',
//       'author': _extractGitHubOwner(document),
//       'language': _extractGitHubLanguage(document),
//       'stars': _extractGitHubStars(document),
//       'forks': _extractGitHubForks(document),
//     };
//   }

//   // Medium content extraction
//   Map<String, dynamic> _extractMediumContent(dom.Document document) {
//     return {
//       'platform': 'Medium',
//       'contentType': 'article',
//       'author':
//           _extractFromMeta(document, 'name="author"') ??
//           _extractMediumAuthor(document),
//       'publishDate': _extractFromMeta(
//         document,
//         'property="article:published_time"',
//       ),
//       'readTime': _extractMediumReadTime(document),
//       'engagement': {
//         'claps': _extractMediumClaps(document),
//         'responses': _extractMediumResponses(document),
//       },
//     };
//   }

//   // Pinterest content extraction
//   Map<String, dynamic> _extractPinterestContent(dom.Document document) {
//     return {
//       'platform': 'Pinterest',
//       'contentType': 'pin',
//       'author': _extractPinterestAuthor(document),
//       'boardName': _extractPinterestBoard(document),
//     };
//   }

//   // Spotify content extraction
//   Map<String, dynamic> _extractSpotifyContent(dom.Document document) {
//     return {
//       'platform': 'Spotify',
//       'contentType': 'music',
//       'author':
//           _extractFromMeta(document, 'name="music:musician"') ??
//           _extractSpotifyArtist(document),
//       'album': _extractSpotifyAlbum(document),
//       'duration': _extractFromMeta(document, 'property="music:duration"'),
//     };
//   }

//   // SoundCloud content extraction
//   Map<String, dynamic> _extractSoundCloudContent(dom.Document document) {
//     return {
//       'platform': 'SoundCloud',
//       'contentType': 'audio',
//       'author':
//           _extractFromMeta(document, 'name="twitter:creator"') ??
//           _extractSoundCloudArtist(document),
//       'duration': _extractFromMeta(document, 'property="music:duration"'),
//     };
//   }

//   // Generic content extraction for unknown platforms
//   Map<String, dynamic> _extractGenericContent(
//     dom.Document document,
//     String host,
//   ) {
//     final contentType = _determineGenericContentType(document);
//     return {
//       'platform': _formatPlatformName(host),
//       'contentType': contentType,
//       'author': _extractGenericAuthor(document),
//       'publishDate':
//           _extractFromMeta(document, 'property="article:published_time"') ??
//           _extractFromMeta(document, 'name="date"'),
//     };
//   }

//   // Helper methods for content extraction
//   String _extractTitle(dom.Document document) {
//     return document.querySelector('title')?.text?.trim() ??
//         _extractFromMeta(document, 'property="og:title"') ??
//         _extractFromMeta(document, 'name="twitter:title"') ??
//         '';
//   }

//   String _extractMetaDescription(dom.Document document) {
//     return _extractFromMeta(document, 'name="description"') ??
//         _extractFromMeta(document, 'property="og:description"') ??
//         _extractFromMeta(document, 'name="twitter:description"') ??
//         '';
//   }

//   String _extractThumbnail(dom.Document document, String baseUrl) {
//     final thumbnail =
//         _extractFromMeta(document, 'property="og:image"') ??
//         _extractFromMeta(document, 'name="twitter:image"') ??
//         '';

//     if (thumbnail.startsWith('//')) {
//       return 'https:$thumbnail';
//     } else if (thumbnail.startsWith('/')) {
//       final uri = Uri.parse(baseUrl);
//       return '${uri.scheme}://${uri.host}$thumbnail';
//     }
//     return thumbnail;
//   }

//   String? _extractFromMeta(dom.Document document, String selector) {
//     final element = document.querySelector('meta[$selector]');
//     return element?.attributes['content']?.trim();
//   }

//   String? _extractFromJsonLd(dom.Document document, String property) {
//     try {
//       final jsonLdElements = document.querySelectorAll(
//         'script[type="application/ld+json"]',
//       );
//       for (final element in jsonLdElements) {
//         final jsonData = jsonDecode(element.text);
//         if (jsonData is Map && jsonData.containsKey(property)) {
//           return jsonData[property]?.toString();
//         }
//       }
//     } catch (e) {
//       // Ignore JSON parsing errors
//     }
//     return null;
//   }

//   // Platform-specific helper methods
//   String _extractChannelName(dom.Document document) {
//     return document
//             .querySelector('span[itemprop="author"] link[itemprop="name"]')
//             ?.attributes['content'] ??
//         document.querySelector('.ytd-channel-name a')?.text?.trim() ??
//         '';
//   }

//   String _extractViewCount(dom.Document document) {
//     return document
//             .querySelector('meta[itemprop="interactionCount"]')
//             ?.attributes['content'] ??
//         document.querySelector('.view-count')?.text?.trim() ??
//         '';
//   }

//   String _extractEngagementCount(dom.Document document, String type) {
//     return document
//             .querySelector('button[aria-label*="$type"] span')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _determineInstagramContentType(dom.Document document) {
//     if (document.querySelector('video') != null) return 'reel';
//     if (document.querySelector('[data-testid="post-preview-image"]') != null)
//       return 'post';
//     return 'content';
//   }

//   String _extractInstagramUsername(dom.Document document) {
//     return document
//             .querySelector('meta[name="twitter:title"]')
//             ?.attributes['content']
//             ?.split('(')[0]
//             ?.trim() ??
//         document.querySelector('h2')?.text?.trim() ??
//         '';
//   }

//   String _extractInstagramLikes(dom.Document document) {
//     return document.querySelector('button span[title*="like"]')?.text?.trim() ??
//         '';
//   }

//   String _extractInstagramComments(dom.Document document) {
//     return document
//             .querySelector('button span[title*="comment"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractTikTokUsername(dom.Document document) {
//     return document
//             .querySelector('h2[data-e2e="browse-username"]')
//             ?.text
//             ?.trim() ??
//         _extractFromMeta(document, 'name="author') ??
//         '';
//   }

//   String _extractTikTokViews(dom.Document document) {
//     return document.querySelector('[data-e2e="video-views"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTikTokLikes(dom.Document document) {
//     return document.querySelector('[data-e2e="like-count"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTikTokShares(dom.Document document) {
//     return document.querySelector('[data-e2e="share-count"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTikTokComments(dom.Document document) {
//     return document.querySelector('[data-e2e="comment-count"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTwitterUsername(dom.Document document) {
//     return _extractFromMeta(
//           document,
//           'name="twitter:creator"',
//         )?.replaceAll('@', '') ??
//         document.querySelector('[data-testid="User-Names"] a')?.text?.trim() ??
//         '';
//   }

//   String _extractTwitterRetweets(dom.Document document) {
//     return document.querySelector('[data-testid="retweet"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTwitterLikes(dom.Document document) {
//     return document.querySelector('[data-testid="like"]')?.text?.trim() ?? '';
//   }

//   String _extractTwitterReplies(dom.Document document) {
//     return document.querySelector('[data-testid="reply"]')?.text?.trim() ?? '';
//   }

//   String _extractFacebookPageName(dom.Document document) {
//     return document.querySelector('h1')?.text?.trim() ??
//         _extractFromMeta(document, 'property="og:title"') ??
//         '';
//   }

//   String _extractLinkedInAuthor(dom.Document document) {
//     return document.querySelector('.feed-shared-actor__name')?.text?.trim() ??
//         document.querySelector('h1')?.text?.trim() ??
//         '';
//   }

//   String _extractRedditUsername(dom.Document document) {
//     return document
//             .querySelector('[data-testid="post_author_link"]')
//             ?.text
//             ?.trim() ??
//         document.querySelector('.author')?.text?.trim() ??
//         '';
//   }

//   String _extractSubreddit(dom.Document document) {
//     return document
//             .querySelector('[data-testid="subreddit-name"]')
//             ?.text
//             ?.trim() ??
//         document.querySelector('._19bCWnxeTjqzBElWZfIlJb')?.text?.trim() ??
//         '';
//   }

//   String _extractRedditUpvotes(dom.Document document) {
//     return document
//             .querySelector('[data-testid="post-vote-score"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractRedditComments(dom.Document document) {
//     return document
//             .querySelector('[data-testid="post-comment-count"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractVimeoAuthor(dom.Document document) {
//     return document.querySelector('.js-user_name')?.text?.trim() ??
//         document.querySelector('[data-name="user-name"]')?.text?.trim() ??
//         '';
//   }

//   String _extractTwitchStreamer(dom.Document document) {
//     return document
//             .querySelector('h1[data-a-target="stream-title"]')
//             ?.text
//             ?.trim() ??
//         document.querySelector('.tw-title')?.text?.trim() ??
//         '';
//   }

//   String _extractTwitchViewers(dom.Document document) {
//     return document
//             .querySelector('[data-a-target="animated-channel-viewers-count"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractGitHubOwner(dom.Document document) {
//     return document
//             .querySelector('[data-testid="breadcrumb"] a')
//             ?.text
//             .trim() ??
//         document.querySelector('.author a')?.text?.trim() ??
//         '';
//   }

//   String _extractGitHubLanguage(dom.Document document) {
//     return document
//             .querySelector('[data-ga-click*="language"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractGitHubStars(dom.Document document) {
//     return document.querySelector('#repo-stars-counter-star')?.text?.trim() ??
//         '';
//   }

//   String _extractGitHubForks(dom.Document document) {
//     return document.querySelector('#repo-network-counter')?.text?.trim() ?? '';
//   }

//   String _extractMediumAuthor(dom.Document document) {
//     return document.querySelector('[data-testid="authorName"]')?.text?.trim() ??
//         document.querySelector('.ds-link--accent')?.text?.trim() ??
//         '';
//   }

//   String _extractMediumReadTime(dom.Document document) {
//     return document
//             .querySelector('[data-testid="storyReadTime"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractMediumClaps(dom.Document document) {
//     return document.querySelector('[data-testid="clapCount"]')?.text?.trim() ??
//         '';
//   }

//   String _extractMediumResponses(dom.Document document) {
//     return document
//             .querySelector('[data-testid="responsesCount"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractPinterestAuthor(dom.Document document) {
//     return document
//             .querySelector('[data-test-id="creator-avatar"] img')
//             ?.attributes['alt'] ??
//         document.querySelector('.user-name')?.text?.trim() ??
//         '';
//   }

//   String _extractPinterestBoard(dom.Document document) {
//     return document
//             .querySelector('[data-test-id="board-name"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractSpotifyArtist(dom.Document document) {
//     return document
//             .querySelector('[data-testid="creator-entity-title"]')
//             ?.text
//             ?.trim() ??
//         document.querySelector('.artist-name')?.text?.trim() ??
//         '';
//   }

//   String _extractSpotifyAlbum(dom.Document document) {
//     return document
//             .querySelector('[data-testid="album-entity-title"]')
//             ?.text
//             ?.trim() ??
//         '';
//   }

//   String _extractSoundCloudArtist(dom.Document document) {
//     return document.querySelector('.soundTitle__username')?.text?.trim() ??
//         document.querySelector('.sound__byArtist')?.text?.trim() ??
//         '';
//   }

//   String _determineGenericContentType(dom.Document document) {
//     if (document.querySelector('video') != null) return 'video';
//     if (document.querySelector('audio') != null) return 'audio';
//     if (document.querySelector('article') != null) return 'article';
//     if (document.querySelector('img') != null &&
//         document.querySelectorAll('img').length >
//             document.querySelectorAll('p').length) {
//       return 'image';
//     }
//     return 'webpage';
//   }

//   String _extractGenericAuthor(dom.Document document) {
//     return _extractFromMeta(document, 'name="author"') ??
//         document.querySelector('.author')?.text?.trim() ??
//         document.querySelector('[rel="author"]')?.text?.trim() ??
//         document.querySelector('.byline')?.text?.trim() ??
//         '';
//   }

//   String _formatPlatformName(String host) {
//     return host
//         .replaceAll('www.', '')
//         .split('.')
//         .first
//         .toLowerCase()
//         .split('')
//         .asMap()
//         .map((i, char) => MapEntry(i, i == 0 ? char.toUpperCase() : char))
//         .values
//         .join('');
//   }

//   // Fallback method for URL pattern analysis when content fetching fails
//   Map<String, dynamic> _analyzeUrlPattern(String url) {
//     final uri = Uri.tryParse(url);
//     if (uri == null) {
//       return {
//         'title': 'Unknown Content',
//         'description': 'Unable to analyze this URL',
//         'author': '',
//         'platform': 'Unknown',
//         'contentType': 'unknown',
//       };
//     }

//     final host = uri.host.toLowerCase();
//     final path = uri.path.toLowerCase();

//     if (host.contains('youtube.com') || host.contains('youtu.be')) {
//       return {
//         'title': 'YouTube Video',
//         'description': 'Video content from YouTube',
//         'author': '',
//         'platform': 'YouTube',
//         'contentType': 'video',
//       };
//     } else if (host.contains('instagram.com')) {
//       String contentType = 'post';
//       if (path.contains('/reel/'))
//         contentType = 'reel';
//       else if (path.contains('/stories/'))
//         contentType = 'story';

//       return {
//         'title': 'Instagram $contentType',
//         'description': 'Content from Instagram',
//         'author': '',
//         'platform': 'Instagram',
//         'contentType': contentType,
//       };
//     }
//     // Add more fallback patterns as needed...

//     return {
//       'title': 'Web Content',
//       'description': 'Content from ${_formatPlatformName(host)}',
//       'author': '',
//       'platform': _formatPlatformName(host),
//       'contentType': 'webpage',
//     };
//   }

//   Future<Map<String, String>> generateDetailsFromUrl(
//     String url, {
//     List<String>? existingCollections,
//   }) async {
//     try {
//       print('Testing network connectivity...');

//       // Test network first
//       bool hasConnection = await _testNetworkConnectivity();
//       if (!hasConnection) {
//         throw Exception('No internet connection available');
//       }

//       print('Network connectivity OK');
//       print('Fetching and analyzing content from URL: $url');

//       // Fetch actual content from URL
//       final contentData = await _fetchUrlContent(url);

//       print('Content fetched successfully');
//       print(
//         'Platform: ${contentData['platform']}, Author: ${contentData['author']}',
//       );

//       // Build collections context for the prompt
//       String collectionsContext = '';
//       if (existingCollections != null && existingCollections.isNotEmpty) {
//         final validCollections = existingCollections
//             .where((c) => c != 'Create New')
//             .toList();
//         if (validCollections.isNotEmpty) {
//           collectionsContext =
//               '''

//           The user has the following existing collections: ${validCollections.join(', ')}

//           For the collection recommendation:
//           - If the content matches any of these existing collections, choose the most appropriate one
//           - If none of the existing collections are suitable, suggest a new collection name that best describes the content's category
//           ''';
//         }
//       }

//       // Create detailed prompt with actual content data
//       final prompt = _buildDetailedPrompt(url, contentData, collectionsContext);

//       final requestBody = {
//         'contents': [
//           {
//             'parts': [
//               {'text': prompt},
//             ],
//           },
//         ],
//         'generationConfig': {
//           'temperature': 0.7,
//           'topK': 40,
//           'topP': 0.95,
//           'maxOutputTokens': 2048,
//         },
//       };

//       final client = http.Client();

//       try {
//         print('Sending detailed content analysis request...');
//         final response = await client
//             .post(
//               Uri.parse('$_geminiApiUrl?key=$_apiKey'),
//               headers: {
//                 'Content-Type': 'application/json',
//                 'User-Agent': 'Flutter/1.0',
//               },
//               body: jsonEncode(requestBody),
//             )
//             .timeout(
//               Duration(seconds: 45),
//               onTimeout: () {
//                 throw TimeoutException(
//                   'Content analysis timed out',
//                   Duration(seconds: 45),
//                 );
//               },
//             );

//         print('Response received - Status: ${response.statusCode}');

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           print('Response parsed successfully');

//           if (data['candidates'] != null &&
//               data['candidates'].isNotEmpty &&
//               data['candidates'][0]['content'] != null) {
//             final generatedText =
//                 data['candidates'][0]['content']['parts'][0]['text'];
//             print(
//               'Generated analysis: ${generatedText.substring(0, math.min(200, generatedText.length))}...',
//             );

//             try {
//               // Try to parse the JSON response from Gemini
//               final cleanedText = _cleanJsonResponse(generatedText);
//               final generatedData = jsonDecode(cleanedText);
//               return {
//                 'tag':
//                     generatedData['tag'] ?? _generateFallbackTag(contentData),
//                 'description':
//                     generatedData['description'] ??
//                     _generateFallbackDescription(contentData),
//                 'collection':
//                     generatedData['collection'] ??
//                     _generateFallbackCollection(
//                       contentData,
//                       existingCollections,
//                     ),
//               };
//             } catch (e) {
//               print('JSON parsing failed: $e');
//               // If JSON parsing fails, extract manually or return defaults
//               return {
//                 'tag':
//                     _extractTag(generatedText) ??
//                     _generateFallbackTag(contentData),
//                 'description':
//                     _extractDescription(generatedText) ??
//                     _generateFallbackDescription(contentData),
//                 'collection':
//                     _extractCollection(generatedText, existingCollections) ??
//                     _generateFallbackCollection(
//                       contentData,
//                       existingCollections,
//                     ),
//               };
//             }
//           } else {
//             throw Exception('Unexpected response structure: ${response.body}');
//           }
//         } else if (response.statusCode == 400) {
//           final errorData = jsonDecode(response.body);
//           print('API Error 400: ${errorData}');
//           // Return fallback data for 400 errors
//           return _generateFallbackResponse(contentData, existingCollections);
//         } else if (response.statusCode == 403) {
//           throw Exception('API Key error: Please check your Gemini API key');
//         } else {
//           print('HTTP Error ${response.statusCode}: ${response.body}');
//           // Return fallback data for other HTTP errors
//           return _generateFallbackResponse(contentData, existingCollections);
//         }
//       } finally {
//         client.close();
//       }
//     } on SocketException catch (e) {
//       print('SocketException: $e');
//       // Fallback to URL pattern analysis for network errors
//       final fallbackData = _analyzeUrlPattern(url);
//       return _generateFallbackResponse(fallbackData, existingCollections);
//     } on TimeoutException catch (e) {
//       print('TimeoutException: $e');
//       // Fallback to URL pattern analysis for timeout
//       final fallbackData = _analyzeUrlPattern(url);
//       return _generateFallbackResponse(fallbackData, existingCollections);
//     } catch (e) {
//       print('General error: $e');
//       // Fallback to URL pattern analysis for any other error
//       final fallbackData = _analyzeUrlPattern(url);
//       return _generateFallbackResponse(fallbackData, existingCollections);
//     }
//   }

//   String _buildDetailedPrompt(
//     String url,
//     Map<String, dynamic> contentData,
//     String collectionsContext,
//   ) {
//     final platform = contentData['platform'] ?? 'Unknown';
//     final contentType = contentData['contentType'] ?? 'content';
//     final title = contentData['title'] ?? '';
//     final description = contentData['description'] ?? '';
//     final author = contentData['author'] ?? '';
//     final publishDate = contentData['publishDate'] ?? '';
//     final duration = contentData['duration'] ?? '';
//     final viewCount = contentData['viewCount'] ?? '';
//     final engagement = contentData['engagement'] ?? {};

//     return '''
//     Analyze this $contentType from $platform and provide detailed insights:

//     URL: $url
//     Platform: $platform
//     Content Type: $contentType
//     Title: $title
//     Description: $description
//     Author/Creator: $author
//     Publish Date: $publishDate
//     ${duration.isNotEmpty ? 'Duration: $duration' : ''}
//     ${viewCount.isNotEmpty ? 'View Count: $viewCount' : ''}
//     ${engagement.isNotEmpty ? 'Engagement Data: ${engagement.toString()}' : ''}
//     $collectionsContext

//     Based on this detailed content information, please provide:
//     1. A specific, descriptive tag that captures what this content is about (incorporate the author name if available, e.g., "Cooking Tutorial by Gordon Ramsay", "Tech Review by MKBHD", etc.)
//     2. A comprehensive description (2-3 sentences) that explains:
//        - What the content is about and who created it
//        - Key details like duration, view count, or engagement metrics if available
//        - What users can expect when they access this content
//     3. A collection name recommendation:
//        ${collectionsContext.isNotEmpty ? '- Choose from existing collections if appropriate' : '- Suggest a new collection name'}
//        - Collection names should be broad categories that group similar content types

//     Please respond in JSON format:
//     {
//       "tag": "specific_content_tag_with_creator",
//       "description": "comprehensive_description_with_details",
//       "collection": "recommended_collection_name"
//     }
//     ''';
//   }

//   Map<String, String> _generateFallbackResponse(
//     Map<String, dynamic> contentData,
//     List<String>? existingCollections,
//   ) {
//     return {
//       'tag': _generateFallbackTag(contentData),
//       'description': _generateFallbackDescription(contentData),
//       'collection': _generateFallbackCollection(
//         contentData,
//         existingCollections,
//       ),
//     };
//   }

//   String _generateFallbackTag(Map<String, dynamic> contentData) {
//     final platform = contentData['platform'] ?? 'Web';
//     final contentType = contentData['contentType'] ?? 'content';
//     final author = contentData['author'] ?? '';
//     final title = contentData['title'] ?? '';

//     if (author.isNotEmpty && title.isNotEmpty) {
//       return '$title by $author';
//     } else if (author.isNotEmpty) {
//       return '$platform ${_capitalizeFirst(contentType)} by $author';
//     } else if (title.isNotEmpty) {
//       return title;
//     } else {
//       return '$platform ${_capitalizeFirst(contentType)}';
//     }
//   }

//   String _generateFallbackDescription(Map<String, dynamic> contentData) {
//     final platform = contentData['platform'] ?? 'web platform';
//     final contentType = contentData['contentType'] ?? 'content';
//     final author = contentData['author'] ?? '';
//     final title = contentData['title'] ?? '';
//     final description = contentData['description'] ?? '';
//     final duration = contentData['duration'] ?? '';
//     final viewCount = contentData['viewCount'] ?? '';

//     String baseDescription = '';

//     if (description.isNotEmpty) {
//       baseDescription = description;
//     } else if (title.isNotEmpty) {
//       baseDescription = 'Content titled "$title"';
//     } else {
//       baseDescription = 'Content from $platform';
//     }

//     String creatorInfo = author.isNotEmpty ? ' created by $author' : '';
//     String additionalInfo = '';

//     if (duration.isNotEmpty && viewCount.isNotEmpty) {
//       additionalInfo = ' Duration: $duration, Views: $viewCount.';
//     } else if (duration.isNotEmpty) {
//       additionalInfo = ' Duration: $duration.';
//     } else if (viewCount.isNotEmpty) {
//       additionalInfo = ' Views: $viewCount.';
//     }

//     return 'This is $contentType$creatorInfo on $platform.$additionalInfo $baseDescription';
//   }

//   String _generateFallbackCollection(
//     Map<String, dynamic> contentData,
//     List<String>? existingCollections,
//   ) {
//     final contentType = contentData['contentType'] ?? 'content';
//     final platform = contentData['platform'] ?? 'Web';

//     // First check if there are matching existing collections
//     if (existingCollections != null) {
//       final validCollections = existingCollections
//           .where((c) => c != 'Create New')
//           .toList();

//       for (String existing in validCollections) {
//         final existingLower = existing.toLowerCase();

//         // Check for exact or partial matches
//         if ((contentType == 'video' &&
//                 (existingLower.contains('video') ||
//                     existingLower.contains('media'))) ||
//             (contentType == 'reel' &&
//                 (existingLower.contains('reel') ||
//                     existingLower.contains('short') ||
//                     existingLower.contains('video'))) ||
//             (contentType == 'image' &&
//                 (existingLower.contains('image') ||
//                     existingLower.contains('photo'))) ||
//             (contentType == 'post' && existingLower.contains('social')) ||
//             (contentType == 'tweet' && existingLower.contains('social')) ||
//             (contentType == 'audio' && existingLower.contains('music')) ||
//             (contentType == 'article' &&
//                 (existingLower.contains('article') ||
//                     existingLower.contains('read'))) ||
//             (contentType == 'repository' && existingLower.contains('code')) ||
//             (platform.toLowerCase() == existingLower)) {
//           return existing;
//         }
//       }
//     }

//     // Generate new collection name based on content type
//     switch (contentType) {
//       case 'video':
//       case 'short_video':
//         return 'Videos';
//       case 'reel':
//         return 'Short Videos';
//       case 'image':
//       case 'pin':
//         return 'Images';
//       case 'post':
//       case 'tweet':
//         return 'Social Media';
//       case 'audio':
//       case 'music':
//         return 'Music & Audio';
//       case 'article':
//         return 'Articles';
//       case 'repository':
//         return 'Programming';
//       case 'stream':
//         return 'Live Streams';
//       case 'story':
//         return 'Stories';
//       case 'discussion':
//         return 'Discussions';
//       case 'professional_post':
//         return 'Professional';
//       default:
//         return platform == 'Web' ? 'Web Links' : platform;
//     }
//   }

//   String _capitalizeFirst(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
//   }

//   String _cleanJsonResponse(String text) {
//     // Remove markdown code blocks if present
//     text = text.replaceAll('```json', '').replaceAll('```', '');

//     // Find the JSON object
//     final jsonStart = text.indexOf('{');
//     final jsonEnd = text.lastIndexOf('}');

//     if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
//       return text.substring(jsonStart, jsonEnd + 1);
//     }

//     return text;
//   }

//   String? _extractTag(String text) {
//     final tagMatch = RegExp(r'"tag":\s*"([^"]*)"').firstMatch(text);
//     return tagMatch?.group(1);
//   }

//   String? _extractDescription(String text) {
//     final descMatch = RegExp(r'"description":\s*"([^"]*)"').firstMatch(text);
//     return descMatch?.group(1);
//   }

//   String? _extractCollection(String text, List<String>? existingCollections) {
//     final collectionMatch = RegExp(
//       r'"collection":\s*"([^"]*)"',
//     ).firstMatch(text);
//     final extractedCollection = collectionMatch?.group(1);

//     if (extractedCollection != null) {
//       if (existingCollections != null) {
//         final validCollections = existingCollections
//             .where((c) => c != 'Create New')
//             .toList();
//         for (String existing in validCollections) {
//           if (existing.toLowerCase() == extractedCollection.toLowerCase()) {
//             return existing;
//           }
//         }
//       }
//       return extractedCollection;
//     }
//     return null;
//   }
// }

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class GeminiService {
  static const String _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-latest:generateContent';
  static const String _apiKey =
      "AIzaSyBwk-1wF2ze3pa8BgOcFYDZV2eySw9YthY"; // Replace with your actual API key

  // Test network connectivity first
  Future<bool> _testNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Fetch actual content from URL
  Future<Map<String, dynamic>> _fetchUrlContent(String url) async {
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
    };

    // Extract basic meta information
    contentData['title'] = _extractTitle(document);
    contentData['description'] = _extractMetaDescription(document);
    contentData['thumbnail'] = _extractThumbnail(document, url);

    // Platform-specific extraction
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      contentData.addAll(_extractYouTubeContent(document));
    } else if (host.contains('instagram.com')) {
      contentData.addAll(_extractInstagramContent(document, url));
    } else {
      contentData.addAll(_extractGenericContent(document, host));
    }

    return contentData;
  }

  // YouTube content extraction (keeping existing implementation)
  Map<String, dynamic> _extractYouTubeContent(dom.Document document) {
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
    };
  }

  // Improved Instagram content extraction
  Map<String, dynamic> _extractInstagramContent(
    dom.Document document,
    String url,
  ) {
    // Determine content type from URL pattern
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

    return {
      'platform': 'Instagram',
      'contentType': contentType,
      'author': _extractInstagramAuthor(document),
      'publishDate': _extractInstagramPublishDate(document),
      'engagement': _extractInstagramEngagement(document),
      'followers': _extractInstagramFollowers(document),
      'isVerified': _extractInstagramVerification(document),
    };
  }

  // Enhanced Instagram author extraction
  String _extractInstagramAuthor(dom.Document document) {
    // Try multiple selectors for Instagram username
    final selectors = [
      'meta[property="instapp:owner_user_id"]',
      'meta[name="twitter:title"]',
      'meta[property="og:title"]',
      'meta[name="author"]',
      'title',
    ];

    for (String selector in selectors) {
      String? content;
      if (selector == 'title') {
        content = document.querySelector(selector)?.text;
      } else {
        content = document.querySelector(selector)?.attributes['content'];
      }

      if (content != null && content.isNotEmpty) {
        // Clean up the content to extract username
        if (content.contains('(@')) {
          // Format: "Name (@username) • Instagram photos and videos"
          final match = RegExp(r'\(@([^)]+)\)').firstMatch(content);
          if (match != null) return '@${match.group(1)}';
        }

        if (content.contains('•')) {
          // Format: "username • Instagram"
          final parts = content.split('•');
          if (parts.isNotEmpty) {
            final username = parts[0].trim();
            if (username.isNotEmpty &&
                !username.toLowerCase().contains('instagram')) {
              return username.startsWith('@') ? username : '@$username';
            }
          }
        }

        // Try to extract from other patterns
        if (content.contains('Instagram')) {
          final beforeInstagram = content.split('Instagram')[0].trim();
          if (beforeInstagram.isNotEmpty && beforeInstagram.length < 50) {
            return beforeInstagram.startsWith('@')
                ? beforeInstagram
                : '@$beforeInstagram';
          }
        }

        // If content looks like a username (short and no spaces)
        if (content.length < 30 &&
            !content.contains(' ') &&
            !content.toLowerCase().contains('instagram') &&
            !content.toLowerCase().contains('photo') &&
            !content.toLowerCase().contains('video')) {
          return content.startsWith('@') ? content : '@$content';
        }
      }
    }

    // Try to extract from JSON-LD
    final jsonAuthor = _extractFromJsonLd(document, 'author');
    if (jsonAuthor != null && jsonAuthor.isNotEmpty) {
      return jsonAuthor.startsWith('@') ? jsonAuthor : '@$jsonAuthor';
    }

    // Fallback: try to extract from page structure
    final pageStructureAuthor = _extractInstagramAuthorFromStructure(document);
    if (pageStructureAuthor.isNotEmpty) {
      return pageStructureAuthor;
    }

    return '';
  }

  // Helper method to extract author from page structure
  String _extractInstagramAuthorFromStructure(dom.Document document) {
    // Try various selectors that might contain the username
    final structureSelectors = [
      'h1',
      'h2',
      '[role="button"]',
      'a[href*="/"]',
      'span',
      'div[dir="ltr"]',
    ];

    for (String selector in structureSelectors) {
      final elements = document.querySelectorAll(selector);
      for (var element in elements) {
        final text = element.text.trim();
        if (text.isNotEmpty &&
            text.length > 1 &&
            text.length < 30 &&
            !text.contains(' ') &&
            !text.toLowerCase().contains('follow') &&
            !text.toLowerCase().contains('post') &&
            !text.toLowerCase().contains('video') &&
            !text.toLowerCase().contains('photo') &&
            RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(text)) {
          return text.startsWith('@') ? text : '@$text';
        }
      }
    }
    return '';
  }

  // Extract Instagram publish date
  String _extractInstagramPublishDate(dom.Document document) {
    return _extractFromMeta(document, 'property="article:published_time"') ??
        _extractFromMeta(document, 'property="og:updated_time"') ??
        _extractFromJsonLd(document, 'datePublished') ??
        _extractFromJsonLd(document, 'uploadDate') ??
        '';
  }

  // Extract Instagram engagement data
  Map<String, dynamic> _extractInstagramEngagement(dom.Document document) {
    return {
      'likes': _extractInstagramLikes(document),
      'comments': _extractInstagramComments(document),
      'views': _extractInstagramViews(document),
      'shares': _extractInstagramShares(document),
    };
  }

  // Enhanced Instagram engagement extraction
  String _extractInstagramLikes(dom.Document document) {
    // Try multiple approaches to extract likes
    final likeSelectors = [
      'meta[property="video:likes"]',
      'meta[property="og:video:likes"]',
      'span[title*="like"]',
      'button[aria-label*="like"]',
      'div[data-testid*="like"]',
    ];

    for (String selector in likeSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content =
            element.attributes['content'] ??
            element.attributes['title'] ??
            element.text;
        if (content != null && content.isNotEmpty) {
          final number = _extractNumberFromText(content);
          if (number.isNotEmpty) return number;
        }
      }
    }

    // Try to extract from JSON-LD
    final jsonLikes = _extractFromJsonLd(document, 'interactionStatistic');
    if (jsonLikes != null) {
      // Parse interaction statistics if available
      return _parseInteractionStat(jsonLikes, 'LikeAction');
    }

    return '';
  }

  String _extractInstagramComments(dom.Document document) {
    final commentSelectors = [
      'meta[property="video:comments"]',
      'span[title*="comment"]',
      'button[aria-label*="comment"]',
      'div[data-testid*="comment"]',
    ];

    for (String selector in commentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content =
            element.attributes['content'] ??
            element.attributes['title'] ??
            element.text;
        if (content != null && content.isNotEmpty) {
          final number = _extractNumberFromText(content);
          if (number.isNotEmpty) return number;
        }
      }
    }

    final jsonComments = _extractFromJsonLd(document, 'interactionStatistic');
    if (jsonComments != null) {
      return _parseInteractionStat(jsonComments, 'CommentAction');
    }

    return '';
  }

  String _extractInstagramViews(dom.Document document) {
    final viewSelectors = [
      'meta[property="video:views"]',
      'span[title*="view"]',
      'div[data-testid*="view"]',
    ];

    for (String selector in viewSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content =
            element.attributes['content'] ??
            element.attributes['title'] ??
            element.text;
        if (content != null && content.isNotEmpty) {
          final number = _extractNumberFromText(content);
          if (number.isNotEmpty) return number;
        }
      }
    }

    return '';
  }

  String _extractInstagramShares(dom.Document document) {
    final shareSelectors = [
      'button[aria-label*="share"]',
      'div[data-testid*="share"]',
    ];

    for (String selector in shareSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.text;
        if (content.isNotEmpty) {
          final number = _extractNumberFromText(content);
          if (number.isNotEmpty) return number;
        }
      }
    }

    return '';
  }

  // Extract follower count
  String _extractInstagramFollowers(dom.Document document) {
    final followerSelectors = [
      'meta[property="instapp:followers"]',
      'span[title*="follower"]',
      'div[data-testid*="follower"]',
    ];

    for (String selector in followerSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content =
            element.attributes['content'] ??
            element.attributes['title'] ??
            element.text;
        if (content != null && content.isNotEmpty) {
          final number = _extractNumberFromText(content);
          if (number.isNotEmpty) return number;
        }
      }
    }

    return '';
  }

  // Check if account is verified
  bool _extractInstagramVerification(dom.Document document) {
    final verificationSelectors = [
      'meta[property="instapp:is_verified"]',
      'svg[aria-label*="Verified"]',
      'span[title*="Verified"]',
    ];

    for (String selector in verificationSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'];
        if (content == 'true' || content == '1') return true;
        if (element.attributes['aria-label']?.contains('Verified') == true)
          return true;
        if (element.attributes['title']?.contains('Verified') == true)
          return true;
      }
    }

    return false;
  }

  // Helper method to extract numbers from text
  String _extractNumberFromText(String text) {
    final numberRegex = RegExp(r'([\d,]+\.?\d*[KMB]?)', caseSensitive: false);
    final match = numberRegex.firstMatch(text);
    return match?.group(1) ?? '';
  }

  // Helper method to parse interaction statistics from JSON-LD
  String _parseInteractionStat(String jsonStat, String actionType) {
    try {
      final data = jsonDecode(jsonStat);
      if (data is List) {
        for (var stat in data) {
          if (stat['interactionType'] == actionType) {
            return stat['userInteractionCount']?.toString() ?? '';
          }
        }
      } else if (data is Map && data['interactionType'] == actionType) {
        return data['userInteractionCount']?.toString() ?? '';
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return '';
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

  // Helper methods for content extraction (keeping existing YouTube methods)
  String _extractTitle(dom.Document document) {
    return document.querySelector('title')?.text?.trim() ??
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

  // YouTube-specific helper methods (keeping existing)
  String _extractChannelName(dom.Document document) {
    return document
            .querySelector('span[itemprop="author"] link[itemprop="name"]')
            ?.attributes['content'] ??
        document.querySelector('.ytd-channel-name a')?.text?.trim() ??
        '';
  }

  String _extractViewCount(dom.Document document) {
    return document
            .querySelector('meta[itemprop="interactionCount"]')
            ?.attributes['content'] ??
        document.querySelector('.view-count')?.text?.trim() ??
        '';
  }

  String _extractEngagementCount(dom.Document document, String type) {
    return document
            .querySelector('button[aria-label*="$type"] span')
            ?.text
            ?.trim() ??
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
        document.querySelector('.author')?.text?.trim() ??
        document.querySelector('[rel="author"]')?.text?.trim() ??
        document.querySelector('.byline')?.text?.trim() ??
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

  // Fallback method for URL pattern analysis when content fetching fails
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
      return {
        'title': 'YouTube Video',
        'description': 'Video content from YouTube',
        'author': '',
        'platform': 'YouTube',
        'contentType': 'video',
      };
    } else if (host.contains('instagram.com')) {
      String contentType = 'post';
      if (path.contains('/reel/') || path.contains('/reels/'))
        contentType = 'reel';
      else if (path.contains('/stories/'))
        contentType = 'story';
      else if (path.contains('/tv/'))
        contentType = 'igtv';

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

  Future<Map<String, String>> generateDetailsFromUrl(
    String url, {
    List<String>? existingCollections,
  }) async {
    try {
      print('Testing network connectivity...');

      // Test network first
      bool hasConnection = await _testNetworkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      print('Network connectivity OK');
      print('Fetching and analyzing content from URL: $url');

      // Fetch actual content from URL
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

      // Create detailed prompt with actual content data
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
              // Try to parse the JSON response from Gemini
              final cleanedText = _cleanJsonResponse(generatedText);
              final generatedData = jsonDecode(cleanedText);
              return {
                'tag':
                    generatedData['tag'] ?? _generateFallbackTag(contentData),
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
              // If JSON parsing fails, extract manually or return defaults
              return {
                'tag':
                    _extractTag(generatedText) ??
                    _generateFallbackTag(contentData),
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
          print('API Error 400: ${errorData}');
          // Return fallback data for 400 errors
          return _generateFallbackResponse(contentData, existingCollections);
        } else if (response.statusCode == 403) {
          throw Exception('API Key error: Please check your Gemini API key');
        } else {
          print('HTTP Error ${response.statusCode}: ${response.body}');
          // Return fallback data for other HTTP errors
          return _generateFallbackResponse(contentData, existingCollections);
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      // Fallback to URL pattern analysis for network errors
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    } on TimeoutException catch (e) {
      print('TimeoutException: $e');
      // Fallback to URL pattern analysis for timeout
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    } catch (e) {
      print('General error: $e');
      // Fallback to URL pattern analysis for any other error
      final fallbackData = _analyzeUrlPattern(url);
      return _generateFallbackResponse(fallbackData, existingCollections);
    }
  }

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
    final followers = contentData['followers'] ?? '';
    final isVerified = contentData['isVerified'] ?? false;

    return '''
    Analyze this $contentType from $platform and provide detailed insights:

    URL: $url
    Platform: $platform
    Content Type: $contentType
    Title: $title
    Description: $description
    Author/Creator: $author
    ${isVerified ? 'Verified Account: Yes' : ''}
    ${followers.isNotEmpty ? 'Followers: $followers' : ''}
    Publish Date: $publishDate
    ${duration.isNotEmpty ? 'Duration: $duration' : ''}
    ${viewCount.isNotEmpty ? 'View Count: $viewCount' : ''}
    ${engagement.isNotEmpty ? 'Engagement Data: ${engagement.toString()}' : ''}
    $collectionsContext

    Based on this detailed content information, please provide:
    1. A specific, descriptive tag that captures what this content is about (incorporate the author name if available, e.g., "Cooking Tutorial by Gordon Ramsay", "Instagram Reel by @username", etc.)
    2. A comprehensive description (2-3 sentences) that explains:
       - What the content is about and who created it
       - Key details like duration, view count, engagement metrics, or verification status if available
       - What users can expect when they access this content
    3. A collection name recommendation:
       ${collectionsContext.isNotEmpty ? '- Choose from existing collections if appropriate' : '- Suggest a new collection name'}
       - Collection names should be broad categories that group similar content types

    Please respond in JSON format:
    {
      "tag": "specific_content_tag_with_creator",
      "description": "comprehensive_description_with_details",
      "collection": "recommended_collection_name"
    }
    ''';
  }

  Map<String, String> _generateFallbackResponse(
    Map<String, dynamic> contentData,
    List<String>? existingCollections,
  ) {
    return {
      'tag': _generateFallbackTag(contentData),
      'description': _generateFallbackDescription(contentData),
      'collection': _generateFallbackCollection(
        contentData,
        existingCollections,
      ),
    };
  }

  String _generateFallbackTag(Map<String, dynamic> contentData) {
    final platform = contentData['platform'] ?? 'Web';
    final contentType = contentData['contentType'] ?? 'content';
    final author = contentData['author'] ?? '';
    final title = contentData['title'] ?? '';

    if (author.isNotEmpty && title.isNotEmpty) {
      return '$title by $author';
    } else if (author.isNotEmpty) {
      return '$platform ${_capitalizeFirst(contentType)} by $author';
    } else if (title.isNotEmpty) {
      return title;
    } else {
      return '$platform ${_capitalizeFirst(contentType)}';
    }
  }

  String _generateFallbackDescription(Map<String, dynamic> contentData) {
    final platform = contentData['platform'] ?? 'web platform';
    final contentType = contentData['contentType'] ?? 'content';
    final author = contentData['author'] ?? '';
    final title = contentData['title'] ?? '';
    final description = contentData['description'] ?? '';
    final duration = contentData['duration'] ?? '';
    final viewCount = contentData['viewCount'] ?? '';
    final engagement = contentData['engagement'] ?? {};
    final followers = contentData['followers'] ?? '';
    final isVerified = contentData['isVerified'] ?? false;

    String baseDescription = '';

    if (description.isNotEmpty) {
      baseDescription = description;
    } else if (title.isNotEmpty) {
      baseDescription = 'Content titled "$title"';
    } else {
      baseDescription = 'Content from $platform';
    }

    String creatorInfo = author.isNotEmpty ? ' created by $author' : '';
    if (isVerified && author.isNotEmpty) {
      creatorInfo += ' (verified account)';
    }
    if (followers.isNotEmpty) {
      creatorInfo += ' with $followers followers';
    }

    String additionalInfo = '';
    if (duration.isNotEmpty && viewCount.isNotEmpty) {
      additionalInfo = ' Duration: $duration, Views: $viewCount.';
    } else if (duration.isNotEmpty) {
      additionalInfo = ' Duration: $duration.';
    } else if (viewCount.isNotEmpty) {
      additionalInfo = ' Views: $viewCount.';
    }

    // Add engagement info for Instagram
    if (platform.toLowerCase() == 'instagram' &&
        engagement is Map &&
        engagement.isNotEmpty) {
      final likes = engagement['likes'] ?? '';
      final comments = engagement['comments'] ?? '';
      if (likes.isNotEmpty || comments.isNotEmpty) {
        final engagementParts = <String>[];
        if (likes.isNotEmpty) engagementParts.add('$likes likes');
        if (comments.isNotEmpty) engagementParts.add('$comments comments');
        additionalInfo += ' Engagement: ${engagementParts.join(', ')}.';
      }
    }

    return 'This is $contentType$creatorInfo on $platform.$additionalInfo $baseDescription';
  }

  String _generateFallbackCollection(
    Map<String, dynamic> contentData,
    List<String>? existingCollections,
  ) {
    final contentType = contentData['contentType'] ?? 'content';
    final platform = contentData['platform'] ?? 'Web';

    // First check if there are matching existing collections
    if (existingCollections != null) {
      final validCollections = existingCollections
          .where((c) => c != 'Create New')
          .toList();

      for (String existing in validCollections) {
        final existingLower = existing.toLowerCase();

        // Check for exact or partial matches
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

    // Generate new collection name based on content type and platform
    if (platform.toLowerCase() == 'youtube') {
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

    // Fallback to generic collections
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

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _cleanJsonResponse(String text) {
    // Remove markdown code blocks if present
    text = text.replaceAll('```json', '').replaceAll('```', '');

    // Find the JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');

    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }

    return text;
  }

  String? _extractTag(String text) {
    final tagMatch = RegExp(r'"tag":\s*"([^"]*)"').firstMatch(text);
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
