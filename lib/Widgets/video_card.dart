import 'package:clipper/Widgets/edit_content_dailog_box.dart';
import 'package:clipper/firebase_service.dart';
import 'package:clipper/models.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';

class RecentVideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // Callback for when video is deleted

  const RecentVideoCard({
    Key? key,
    required this.video,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  // Extract thumbnail URL from video URL (synchronous for YouTube)
  String? _getThumbnailUrlSync(String url) {
    try {
      // YouTube thumbnails
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          // Use maxresdefault for best quality, fallback to hqdefault
          return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }
    } catch (e) {
      print('Error extracting thumbnail: $e');
    }
    return null;
  }

  // Extract thumbnail URL from video URL (async for Instagram)
  Future<String?> _getThumbnailUrl(String url) async {
    try {
      // YouTube thumbnails (synchronous)
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        return _getThumbnailUrlSync(url);
      }
      // Instagram thumbnails (async fetch)
      else if (url.contains('instagram.com')) {
        return await _fetchInstagramThumbnail(url);
      }
      // TikTok thumbnails (limited support)
      else if (url.contains('tiktok.com')) {
        // TikTok also requires API access for thumbnails
        return null;
      }
    } catch (e) {
      print('Error extracting thumbnail: $e');
    }
    return null;
  }

  // Fetch Instagram thumbnail using multiple strategies
  Future<String?> _fetchInstagramThumbnail(String url) async {
    // Normalize Instagram URL
    String normalizedUrl = _normalizeInstagramUrl(url);
    print('Fetching Instagram thumbnail for: $normalizedUrl');

    // Strategy 1: Try oEmbed service (noembed.com) - most reliable
    String? thumbnail = await _fetchInstagramThumbnailOEmbed(normalizedUrl);
    if (thumbnail != null && thumbnail.isNotEmpty) {
      print('Instagram thumbnail fetched via oEmbed: $thumbnail');
      return thumbnail;
    }

    // Strategy 2: Try direct HTML scraping with og:image
    thumbnail = await _fetchInstagramThumbnailHtml(normalizedUrl);
    if (thumbnail != null && thumbnail.isNotEmpty) {
      print('Instagram thumbnail fetched via HTML: $thumbnail');
      return thumbnail;
    }

    // Strategy 3: Try with mobile user agent
    thumbnail = await _fetchInstagramThumbnailMobile(normalizedUrl);
    if (thumbnail != null && thumbnail.isNotEmpty) {
      print('Instagram thumbnail fetched via mobile: $thumbnail');
      return thumbnail;
    }

    print('Failed to fetch Instagram thumbnail for: $normalizedUrl');
    return null;
  }

  // Normalize Instagram URL to standard format
  String _normalizeInstagramUrl(String url) {
    // Remove query parameters and fragments
    final uri = Uri.parse(url);
    String normalized = '${uri.scheme}://${uri.host}${uri.path}';

    // Ensure www. prefix if missing
    if (!normalized.contains('www.instagram.com') &&
        normalized.contains('instagram.com')) {
      normalized = normalized.replaceFirst(
        'instagram.com',
        'www.instagram.com',
      );
    }

    return normalized;
  }

  // Strategy 1: Use oEmbed service (noembed.com)
  Future<String?> _fetchInstagramThumbnailOEmbed(String url) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(
              'https://noembed.com/embed?url=${Uri.encodeComponent(url)}',
            ),
          )
          .timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data['error'] == null) {
          final thumbnail = data['thumbnail_url']?.toString();
          if (thumbnail != null && thumbnail.isNotEmpty) {
            return thumbnail;
          }
        }
      }
    } catch (e) {
      print('oEmbed thumbnail fetch failed: $e');
    }
    return null;
  }

  // Strategy 2: Direct HTML scraping
  Future<String?> _fetchInstagramThumbnailHtml(String url) async {
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
          .timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        // Check if we got redirected to login page
        if (response.body.contains('"loginPage"') ||
            response.body.contains('not-logged-in') ||
            response.body.contains('Log in to Instagram')) {
          print('Instagram returned login page, skipping HTML fetch');
          return null;
        }

        final document = html_parser.parse(response.body);
        final ogImage = _extractFromMeta(document, 'property="og:image"');

        if (ogImage != null && ogImage.isNotEmpty) {
          // Handle relative URLs
          if (ogImage.startsWith('//')) {
            return 'https:$ogImage';
          } else if (ogImage.startsWith('/')) {
            final uri = Uri.parse(url);
            return '${uri.scheme}://${uri.host}$ogImage';
          }
          return ogImage;
        }
      }
    } catch (e) {
      print('HTML thumbnail fetch failed: $e');
    }
    return null;
  }

  // Strategy 3: Mobile user agent
  Future<String?> _fetchInstagramThumbnailMobile(String url) async {
    try {
      final client = http.Client();
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 10));
      client.close();

      if (response.statusCode == 200) {
        // Check if we got redirected to login page
        if (response.body.contains('"loginPage"') ||
            response.body.contains('not-logged-in') ||
            response.body.contains('Log in to Instagram')) {
          print('Instagram returned login page, skipping mobile fetch');
          return null;
        }

        final document = html_parser.parse(response.body);
        final ogImage = _extractFromMeta(document, 'property="og:image"');

        if (ogImage != null && ogImage.isNotEmpty) {
          if (ogImage.startsWith('//')) {
            return 'https:$ogImage';
          } else if (ogImage.startsWith('/')) {
            final uri = Uri.parse(url);
            return '${uri.scheme}://${uri.host}$ogImage';
          }
          return ogImage;
        }
      }
    } catch (e) {
      print('Mobile thumbnail fetch failed: $e');
    }
    return null;
  }

  // Helper method to extract meta tag content
  String? _extractFromMeta(dom.Document document, String selector) {
    try {
      final element = document.querySelector('meta[$selector]');
      final content = element?.attributes['content']?.trim();
      if (content != null && content.isNotEmpty) {
        return content;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper methods
  IconData _getPlatformIcon(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return Icons.play_circle_fill;
    } else if (url.contains('instagram.com')) {
      return Icons.camera_alt;
    } else if (url.contains('tiktok.com')) {
      return Icons.music_note;
    } else {
      return Icons.video_library;
    }
  }

  String _getPlatformName(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube';
    } else if (url.contains('instagram.com')) {
      return 'Instagram';
    } else if (url.contains('tiktok.com')) {
      return 'TikTok';
    } else {
      return 'Web';
    }
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'web content':
        return const Color(0xFF7C4DFF);
      case 'fitness':
        return const Color(0xFF4CAF50);
      case 'workout':
        return const Color(0xFFFF9800);
      case 'tutorial':
        return const Color(0xFF9C27B0);
      case 'health':
        return const Color(0xFF009688);
      case 'education':
        return const Color(0xFF3F51B5);
      default:
        return const Color(0xFF757575);
    }
  }

  void _showDeleteConfirmation(BuildContext context) async {
    // Find the collection name first
    String? collectionName = await FirestoreService()
        .findVideoCollectionOptimized(
          userId: FirebaseAuth.instance.currentUser!.uid,
          videoId: video.id,
        );

    if (collectionName == null) {
      _showErrorSnackBar(context, 'Could not find video collection');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Video',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this video?',
                style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              Text(
                video.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteVideo(context, collectionName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideo(BuildContext context, String collectionName) async {
    try {
      // Delete the video from Firestore - NO loading dialog
      await FirestoreService().deleteVideo(
        userId: FirebaseAuth.instance.currentUser!.uid,
        collectionName: collectionName,
        videoId: video.id,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Call the onDelete callback to refresh the UI
        onDelete?.call();
      }
    } catch (e) {
      print('Error deleting video: $e');

      // Show error message
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to delete video: $e');
      }
    }
  }

  void _showContentInfo(BuildContext context) async {
    String? collectionName = await FirestoreService()
        .findVideoCollectionOptimized(
          userId: FirebaseAuth.instance.currentUser!.uid,
          videoId: video.id,
        );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final thumbnailUrl = _getThumbnailUrlSync(video.url);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with thumbnail background
                Stack(
                  children: [
                    // Thumbnail or gradient background
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF7C4DFF),
                            const Color(0xFF9C27B0),
                          ],
                        ),
                      ),
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            )
                          : null,
                    ),
                    // Overlay gradient
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Header content
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getPlatformIcon(video.url),
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getPlatformName(video.url),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title at bottom of header
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Text(
                        video.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        _buildInfoSection(
                          icon: Icons.description_outlined,
                          title: 'Description',
                          child: Text(
                            video.description.isNotEmpty
                                ? video.description
                                : 'No description',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Collection & Saved Date Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.folder_outlined,
                                title: 'Collection',
                                value: collectionName ?? 'Unknown',
                                color: const Color(0xFF7C4DFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                icon: Icons.access_time,
                                title: 'Saved',
                                value: _formatDate(video.createdAt),
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tags
                        _buildInfoSection(
                          icon: Icons.label_outlined,
                          title: 'Tags',
                          child: video.tags.isEmpty
                              ? Text(
                                  'No tags',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: video.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getTagColor(tag),
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getTagColor(tag).withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            foregroundColor: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _launchUrl(context, video.url);
                          },
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text('Watch Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF7C4DFF)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C4DFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Build full cover thumbnail for the card
  Widget _buildFullCoverThumbnail(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getThumbnailUrl(video.url),
      builder: (context, snapshot) {
        final thumbnailUrl = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        if (thumbnailUrl != null) {
          return Image.network(
            thumbnailUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildGradientFallback();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildGradientFallback(
                showLoader: true,
                progress: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              );
            },
          );
        } else if (isLoading) {
          return _buildGradientFallback(showLoader: true);
        } else {
          return _buildGradientFallback();
        }
      },
    );
  }

  // Gradient fallback when thumbnail is not available
  Widget _buildGradientFallback({bool showLoader = false, double? progress}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
        ),
      ),
      child: showLoader
          ? Center(
              child: CircularProgressIndicator(
                value: progress,
                color: Colors.white,
              ),
            )
          : Center(
              child: Icon(
                _getPlatformIcon(video.url),
                color: Colors.white.withOpacity(0.7),
                size: 60,
              ),
            ),
    );
  }

  // Build tag chips for overlay (with better contrast)
  Widget _buildOverlayTagChips(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .take(3)
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _getTagColor(tag).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                tag.length > 10 ? '${tag.substring(0, 10)}...' : tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }

  // Build overlay button with better styling
  Widget _buildOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF7C4DFF)
              : Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth * 1.2; // Adaptive aspect ratio

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full cover thumbnail background
              _buildFullCoverThumbnail(context),

              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content overlaid on thumbnail
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04), // Adaptive padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top section: Delete button, Platform indicator, Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Delete button
                        GestureDetector(
                          onTap: () => _showDeleteConfirmation(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Platform and Date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getPlatformName(video.url),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(video.createdAt).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom section: Title, Description, Tags, Action buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          video.name,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045, // Adaptive font size
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          video.description,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Tags
                        _buildOverlayTagChips(video.tags),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Info button
                            _buildOverlayButton(
                              icon: Icons.info_outline,
                              label: 'Info',
                              onTap: () => _showContentInfo(context),
                              isPrimary: false,
                            ),
                            const SizedBox(width: 10),
                            // Edit button
                            _buildOverlayButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              onTap: () async {
                                try {
                                  String? collectionName =
                                      await FirestoreService()
                                          .findVideoCollection(
                                            userId: FirebaseAuth
                                                .instance
                                                .currentUser!
                                                .uid,
                                            videoId: video.id,
                                          );

                                  if (collectionName != null) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditContentDialog(
                                        video: video,
                                        userId: FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .uid,
                                        collectionName: collectionName,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Could not find video collection',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              isPrimary: false,
                            ),
                            const SizedBox(width: 10),
                            // Open button
                            Expanded(
                              child: _buildOverlayButton(
                                icon: Icons.open_in_new,
                                label: 'Open',
                                onTap: () => _launchUrl(context, video.url),
                                isPrimary: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showErrorSnackBar(context, 'No URL available');
      return;
    }

    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        await _launchYouTube(url);
      } else if (url.contains('instagram.com')) {
        await _launchInstagram(url);
      } else {
        await _launchDefault(url);
      }
    } catch (e) {
      print('Launch error: $e');
      _showErrorSnackBar(context, 'Failed to open video');
    }
  }

  Future<void> _launchYouTube(String url) async {
    try {
      String appUrl;

      if (url.contains('/shorts/')) {
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          appUrl = 'vnd.youtube://$videoId';
        } else {
          appUrl = url
              .replaceAll('https://youtube.com', 'vnd.youtube:')
              .replaceAll('https://www.youtube.com', 'vnd.youtube:');
        }
      } else {
        appUrl = url
            .replaceAll('https://youtube.com', 'vnd.youtube:')
            .replaceAll('https://www.youtube.com', 'vnd.youtube:')
            .replaceAll('https://youtu.be/', 'vnd.youtube://');
      }

      Uri appUri = Uri.parse(appUrl);

      if (await canLaunchUrl(appUri)) {
        bool launched = await launchUrl(appUri);
        if (launched) return;
      }

      Uri webUri = Uri.parse(url);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchInstagram(String url) async {
    try {
      String appUrl = url
          .replaceAll('https://instagram.com', 'instagram://')
          .replaceAll('https://www.instagram.com', 'instagram://');

      Uri appUri = Uri.parse(appUrl);

      if (await canLaunchUrl(appUri)) {
        bool launched = await launchUrl(appUri);
        if (launched) return;
      }

      Uri webUri = Uri.parse(url);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchDefault(String url) async {
    String urlToLaunch = url;

    if (!urlToLaunch.startsWith('http://') &&
        !urlToLaunch.startsWith('https://')) {
      urlToLaunch = 'https://$urlToLaunch';
    }

    Uri uri = Uri.parse(urlToLaunch);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    if (url.contains('/shorts/')) {
      final shortsRegExp = RegExp(r'/shorts/([a-zA-Z0-9_-]{11})');
      final match = shortsRegExp.firstMatch(url);
      return match?.group(1);
    }

    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
