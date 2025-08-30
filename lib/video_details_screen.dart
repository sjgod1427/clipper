// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter/services.dart';

// class VideoDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> videoData;
//   final String videoId;
//   final String collectionName;

//   const VideoDetailScreen({
//     super.key,
//     required this.videoData,
//     required this.videoId,
//     required this.collectionName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final url = videoData['url'] ?? '';
//     final title = videoData['tag'] ?? 'No Title';
//     final description = videoData['description'] ?? '';
//     final createdAt = videoData['createdAt'];
//     final isYouTube = url.contains('youtube.com') || url.contains('youtu.be');

//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: CustomScrollView(
//         slivers: [
//           // Beautiful App Bar with Video Theme
//           SliverAppBar(
//             expandedHeight: 200.0,
//             floating: false,
//             pinned: true,
//             elevation: 0,
//             backgroundColor: Colors.transparent,
//             leading: Container(
//               margin: const EdgeInsets.only(left: 16, top: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//               ),
//             ),
//             actions: [
//               Container(
//                 margin: const EdgeInsets.only(right: 16, top: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: PopupMenuButton<String>(
//                   icon: const Icon(
//                     Icons.more_vert_rounded,
//                     color: Colors.white,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   itemBuilder: (context) => [
//                     const PopupMenuItem(
//                       value: 'copy_url',
//                       child: Row(
//                         children: [
//                           Icon(Icons.copy_rounded, size: 20),
//                           SizedBox(width: 12),
//                           Text('Copy URL'),
//                         ],
//                       ),
//                     ),
//                     const PopupMenuItem(
//                       value: 'share',
//                       child: Row(
//                         children: [
//                           Icon(Icons.share_rounded, size: 20),
//                           SizedBox(width: 12),
//                           Text('Share'),
//                         ],
//                       ),
//                     ),
//                   ],
//                   onSelected: (value) {
//                     if (value == 'copy_url') {
//                       _copyUrl(context, url);
//                     } else if (value == 'share') {
//                       _shareVideo(context);
//                     }
//                   },
//                 ),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: isYouTube
//                         ? [
//                             Colors.red.shade600,
//                             Colors.pink.shade500,
//                             Colors.orange.shade400,
//                           ]
//                         : [
//                             Colors.purple.shade600,
//                             Colors.indigo.shade500,
//                             Colors.blue.shade400,
//                           ],
//                   ),
//                 ),
//                 child: SafeArea(
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         // Video type indicator
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 isYouTube
//                                     ? Icons.play_circle_filled
//                                     : Icons.video_library_rounded,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 isYouTube ? 'YouTube Video' : 'Video',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // Collection context
//                         Text(
//                           'From $collectionName',
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.8),
//                             fontSize: 14,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 4),

//                         // Video title
//                         Text(
//                           title,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Video Details Content
//           SliverPadding(
//             padding: const EdgeInsets.all(20.0),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 // Main Action Button
//                 Container(
//                   width: double.infinity,
//                   height: 60,
//                   margin: const EdgeInsets.only(bottom: 24),
//                   child: ElevatedButton.icon(
//                     onPressed: () => _launchUrl(context, url),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isYouTube
//                           ? Colors.red.shade600
//                           : Colors.indigo.shade600,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       elevation: 0,
//                     ),
//                     icon: Icon(
//                       isYouTube
//                           ? Icons.play_arrow_rounded
//                           : Icons.open_in_new_rounded,
//                       size: 28,
//                     ),
//                     label: Text(
//                       isYouTube ? 'Watch on YouTube' : 'Open Video',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Description Section
//                 if (description.isNotEmpty) ...[
//                   _buildInfoSection(
//                     'Description',
//                     Icons.description_rounded,
//                     Colors.blue,
//                     description,
//                   ),
//                   const SizedBox(height: 20),
//                 ],

//                 // URL Section
//                 _buildInfoSection(
//                   'Video URL',
//                   Icons.link_rounded,
//                   Colors.green,
//                   url,
//                   isUrl: true,
//                   onTap: () => _copyUrl(context, url),
//                 ),
//                 const SizedBox(height: 20),

//                 // Video ID Section
//                 _buildInfoSection(
//                   'Video ID',
//                   Icons.fingerprint_rounded,
//                   Colors.orange,
//                   videoId,
//                   isMonospace: true,
//                 ),
//                 const SizedBox(height: 20),

//                 // Date Added Section
//                 if (createdAt != null) ...[
//                   _buildInfoSection(
//                     'Date Added',
//                     Icons.calendar_today_rounded,
//                     Colors.purple,
//                     _formatDate(createdAt),
//                   ),
//                   const SizedBox(height: 20),
//                 ],

//                 // Additional Actions
//                 _buildActionsSection(context, url, title),
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInfoSection(
//     String title,
//     IconData icon,
//     Color color,
//     String content, {
//     bool isUrl = false,
//     bool isMonospace = false,
//     VoidCallback? onTap,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Icon(icon, color: color, size: 20),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     if (onTap != null) ...[
//                       const Spacer(),
//                       Icon(
//                         Icons.copy_rounded,
//                         size: 16,
//                         color: Colors.grey.shade400,
//                       ),
//                     ],
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 SelectableText(
//                   content,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey.shade700,
//                     height: 1.5,
//                     fontFamily: isMonospace ? 'monospace' : null,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildActionsSection(BuildContext context, String url, String title) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.indigo.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Icon(
//                     Icons.settings_rounded,
//                     color: Colors.indigo.shade600,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   'Quick Actions',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // Action buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildActionButton(
//                     'Copy URL',
//                     Icons.copy_rounded,
//                     Colors.blue,
//                     () => _copyUrl(context, url),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildActionButton(
//                     'Share',
//                     Icons.share_rounded,
//                     Colors.green,
//                     () => _shareVideo(context),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActionButton(
//     String label,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return OutlinedButton.icon(
//       onPressed: onPressed,
//       style: OutlinedButton.styleFrom(
//         foregroundColor: color,
//         side: BorderSide(color: color.withOpacity(0.3)),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         padding: const EdgeInsets.symmetric(vertical: 12),
//       ),
//       icon: Icon(icon, size: 18),
//       label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
//     );
//   }

//   Future<void> _launchUrl(BuildContext context, String? url) async {
//     print(url);
//     if (url == null || url.isEmpty) {
//       _showErrorSnackBar(context, 'No URL available');
//       return;
//     }

//     try {
//       String urlToLaunch = url;

//       // Handle YouTube URLs specifically
//       if (url.contains('youtube.com') || url.contains('youtu.be')) {
//         String? videoId = _extractYouTubeVideoId(url);
//         if (videoId != null) {
//           try {
//             final youtubeUri = Uri.parse('vnd.youtube:$videoId');
//             if (await canLaunchUrl(youtubeUri)) {
//               await launchUrl(youtubeUri);
//               return;
//             }
//           } catch (e) {
//             print('YouTube app URL failed: $e');
//           }
//           urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
//         }
//       }

//       if (!urlToLaunch.startsWith('http://') &&
//           !urlToLaunch.startsWith('https://')) {
//         urlToLaunch = 'https://$urlToLaunch';
//       }

//       final uri = Uri.parse(urlToLaunch);

//       try {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } catch (e) {
//         try {
//           await launchUrl(uri, mode: LaunchMode.platformDefault);
//         } catch (e2) {
//           await launchUrl(uri, mode: LaunchMode.inAppWebView);
//         }
//       }
//     } catch (e) {
//       _showErrorSnackBar(context, 'Failed to open video');
//     }
//   }

//   String? _extractYouTubeVideoId(String url) {
//     final regExp = RegExp(
//       r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
//       caseSensitive: false,
//     );
//     final match = regExp.firstMatch(url);
//     return match?.group(1);
//   }

//   void _copyUrl(BuildContext context, String url) {
//     Clipboard.setData(ClipboardData(text: url));
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('URL copied to clipboard'),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _shareVideo(BuildContext context) {
//     // Implementation would depend on your sharing package
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Share functionality not implemented yet'),
//         backgroundColor: Colors.orange,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   void _showErrorSnackBar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   String _formatDate(dynamic timestamp) {
//     try {
//       if (timestamp == null) return 'Unknown';

//       // Handle Firestore Timestamp
//       DateTime date;
//       if (timestamp.runtimeType.toString().contains('Timestamp')) {
//         date = timestamp.toDate();
//       } else if (timestamp is DateTime) {
//         date = timestamp;
//       } else {
//         return 'Unknown';
//       }

//       final now = DateTime.now();
//       final difference = now.difference(date);

//       if (difference.inDays > 7) {
//         return '${date.day}/${date.month}/${date.year}';
//       } else if (difference.inDays > 0) {
//         return '${difference.inDays} days ago';
//       } else if (difference.inHours > 0) {
//         return '${difference.inHours} hours ago';
//       } else if (difference.inMinutes > 0) {
//         return '${difference.inMinutes} minutes ago';
//       } else {
//         return 'Just now';
//       }
//     } catch (e) {
//       return 'Unknown';
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class VideoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> videoData;
  final String videoId;
  final String collectionName;

  const VideoDetailScreen({
    super.key,
    required this.videoData,
    required this.videoId,
    required this.collectionName,
  });

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
      case 'entertainment':
        return const Color(0xFFE91E63);
      case 'music':
        return const Color(0xFFFF5722);
      case 'gaming':
        return const Color(0xFF795548);
      case 'tech':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = videoData['url'] ?? '';
    final title = videoData['name'] ?? videoData['tag'] ?? 'No Title';
    final description = videoData['description'] ?? '';
    final createdAt = videoData['createdAt'];
    final tags = List<String>.from(videoData['tags'] ?? []);
    final isYouTube = url.contains('youtube.com') || url.contains('youtu.be');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with Video Theme
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.only(left: 16, top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy_url',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Copy URL'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Share'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'copy_url') {
                      _copyUrl(context, url);
                    } else if (value == 'share') {
                      _shareVideo(context);
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isYouTube
                        ? [
                            Colors.red.shade600,
                            Colors.pink.shade500,
                            Colors.orange.shade400,
                          ]
                        : [
                            Colors.purple.shade600,
                            Colors.indigo.shade500,
                            Colors.blue.shade400,
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Video type indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isYouTube
                                    ? Icons.play_circle_filled
                                    : Icons.video_library_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isYouTube ? 'YouTube Video' : 'Video',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Collection context
                        Text(
                          'From $collectionName',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Video title
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Video Details Content
          SliverPadding(
            padding: const EdgeInsets.all(20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Main Action Button
                Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(context, url),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isYouTube
                          ? Colors.red.shade600
                          : Colors.indigo.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      isYouTube
                          ? Icons.play_arrow_rounded
                          : Icons.open_in_new_rounded,
                      size: 28,
                    ),
                    label: Text(
                      isYouTube ? 'Watch on YouTube' : 'Open Video',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Tags Section
                if (tags.isNotEmpty) ...[
                  _buildTagsSection(tags),
                  const SizedBox(height: 20),
                ],

                // Description Section
                if (description.isNotEmpty) ...[
                  _buildInfoSection(
                    'Description',
                    Icons.description_rounded,
                    Colors.blue,
                    description,
                  ),
                  const SizedBox(height: 20),
                ],

                // URL Section
                _buildInfoSection(
                  'Video URL',
                  Icons.link_rounded,
                  Colors.green,
                  url,
                  isUrl: true,
                  onTap: () => _copyUrl(context, url),
                ),
                const SizedBox(height: 20),

                // Video ID Section
                _buildInfoSection(
                  'Video ID',
                  Icons.fingerprint_rounded,
                  Colors.orange,
                  videoId,
                  isMonospace: true,
                ),
                const SizedBox(height: 20),

                // Date Added Section
                if (createdAt != null) ...[
                  _buildInfoSection(
                    'Date Added',
                    Icons.calendar_today_rounded,
                    Colors.purple,
                    _formatDate(createdAt),
                  ),
                  const SizedBox(height: 20),
                ],

                // Additional Actions
                _buildActionsSection(context, url, title),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(List<String> tags) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: Colors.pink.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tags.length} tag${tags.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getTagColor(tag),
                        borderRadius: BorderRadius.circular(16),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    String content, {
    bool isUrl = false,
    bool isMonospace = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, String url, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: Colors.indigo.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Copy URL',
                    Icons.copy_rounded,
                    Colors.blue,
                    () => _copyUrl(context, url),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Share',
                    Icons.share_rounded,
                    Colors.green,
                    () => _shareVideo(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    print(url);
    if (url == null || url.isEmpty) {
      _showErrorSnackBar(context, 'No URL available');
      return;
    }

    try {
      String urlToLaunch = url;

      // Handle YouTube URLs specifically
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          try {
            final youtubeUri = Uri.parse('vnd.youtube:$videoId');
            if (await canLaunchUrl(youtubeUri)) {
              await launchUrl(youtubeUri);
              return;
            }
          } catch (e) {
            print('YouTube app URL failed: $e');
          }
          urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
        }
      }

      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }

      final uri = Uri.parse(urlToLaunch);

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
        }
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open video');
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL copied to clipboard'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareVideo(BuildContext context) {
    // Implementation would depend on your sharing package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality not implemented yet'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';

      // Handle Firestore Timestamp
      DateTime date;
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Unknown';
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
