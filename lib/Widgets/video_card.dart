import 'package:clipper/Widgets/edit_content_dailog_box.dart';
import 'package:clipper/firebase_service.dart';
import 'package:clipper/models.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecentVideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const RecentVideoCard({Key? key, required this.video, required this.onTap})
    : super(key: key);

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

  void _showContentInfo(BuildContext context) async {
    String? collectionName = await FirestoreService()
        .findVideoCollectionOptimized(
          userId: FirebaseAuth.instance.currentUser!.uid,
          videoId: video.id,
        );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Content Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          video.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Summary
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          video.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Platform
                        const Text(
                          'Platform',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getPlatformName(video.url),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Collection (placeholder)
                        const Text(
                          'Collection',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          collectionName ?? "",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tags
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
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
                                    borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 20),
                        // Saved
                        const Text(
                          'Saved',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(video.createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Open Link',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildTagChips(List<String> tags) {
    print("${tags} Hi");
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags
          .take(3)
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getTagColor(tag),
                borderRadius: BorderRadius.circular(16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
                ),
              ),
              child: Stack(
                children: [
                  // Play overlay
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getPlatformIcon(video.url),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  // Platform indicator
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getPlatformName(video.url),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    video.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  _buildTagChips(video.tags),
                  const SizedBox(height: 16),
                  // Bottom row with date and action buttons
                  Row(
                    children: [
                      // Date
                      Text(
                        _formatDate(video.createdAt).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Info button
                          GestureDetector(
                            onTap: () => _showContentInfo(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Info',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Edit button
                          // Replace the Edit button onPressed with this fixed version:
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                // Find the collection name
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
                                  // Show edit dialog
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
                                  // Show error message
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
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Open button
                          ElevatedButton(
                            onPressed: () async {
                              print(video.url);
                              _launchUrl(context, video.url);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: 0,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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

    print('Original URL: $url');

    try {
      // Handle YouTube URLs
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        await _launchYouTube(url);
      }
      // Handle Instagram URLs
      else if (url.contains('instagram.com')) {
        await _launchInstagram(url);
      }
      // Handle other URLs
      else {
        await _launchDefault(url);
      }
    } catch (e) {
      print('Launch error: $e');
      _showErrorSnackBar(context, 'Failed to open video');
    }
  }

  Future<void> _launchYouTube(String url) async {
    try {
      // First try to open in YouTube app with the original URL format
      String appUrl;

      if (url.contains('/shorts/')) {
        // For YouTube Shorts, try to extract the video ID and convert to regular format
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          appUrl = 'vnd.youtube://$videoId';
        } else {
          appUrl = url
              .replaceAll('https://youtube.com', 'vnd.youtube:')
              .replaceAll('https://www.youtube.com', 'vnd.youtube:');
        }
      } else {
        // For regular YouTube URLs
        appUrl = url
            .replaceAll('https://youtube.com', 'vnd.youtube:')
            .replaceAll('https://www.youtube.com', 'vnd.youtube:')
            .replaceAll('https://youtu.be/', 'vnd.youtube://');
      }

      Uri appUri = Uri.parse(appUrl);
      print('Trying YouTube app URL: $appUrl');

      if (await canLaunchUrl(appUri)) {
        bool launched = await launchUrl(appUri);
        if (launched) return;
      }

      // Fallback: Open original URL in browser
      print('Falling back to browser with original URL: $url');
      Uri webUri = Uri.parse(url);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('YouTube launch error: $e');
      // Final fallback: try original URL
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchInstagram(String url) async {
    try {
      // Try Instagram app first
      String appUrl = url
          .replaceAll('https://instagram.com', 'instagram://')
          .replaceAll('https://www.instagram.com', 'instagram://');

      Uri appUri = Uri.parse(appUrl);

      if (await canLaunchUrl(appUri)) {
        bool launched = await launchUrl(appUri);
        if (launched) return;
      }

      // Fallback to browser
      Uri webUri = Uri.parse(url);
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Instagram launch error: $e');
      Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _launchDefault(String url) async {
    String urlToLaunch = url;

    // Ensure URL has proper protocol
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

  // Updated YouTube video ID extraction for Shorts support
  String? _extractYouTubeVideoId(String url) {
    // Handle YouTube Shorts
    if (url.contains('/shorts/')) {
      final shortsRegExp = RegExp(r'/shorts/([a-zA-Z0-9_-]{11})');
      final match = shortsRegExp.firstMatch(url);
      return match?.group(1);
    }

    // Handle regular YouTube URLs
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
