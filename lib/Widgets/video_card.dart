// import 'package:clipper/Widgets/edit_content_dailog_box.dart';
// import 'package:clipper/firebase_service.dart';
// import 'package:clipper/models.dart';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

// class RecentVideoCard extends StatelessWidget {
//   final VideoModel video;
//   final VoidCallback onTap;

//   const RecentVideoCard({Key? key, required this.video, required this.onTap})
//     : super(key: key);

//   // Extract thumbnail URL from video URL
//   String? _getThumbnailUrl(String url) {
//     try {
//       // YouTube thumbnails
//       if (url.contains('youtube.com') || url.contains('youtu.be')) {
//         String? videoId = _extractYouTubeVideoId(url);
//         if (videoId != null) {
//           // Use maxresdefault for best quality, fallback to hqdefault
//           return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
//         }
//       }
//       // Instagram thumbnails (limited support - Instagram blocks direct image access)
//       else if (url.contains('instagram.com')) {
//         // Instagram doesn't allow direct thumbnail extraction
//         // You would need to use Instagram's API for this
//         return null;
//       }
//       // TikTok thumbnails (limited support)
//       else if (url.contains('tiktok.com')) {
//         // TikTok also requires API access for thumbnails
//         return null;
//       }
//     } catch (e) {
//       print('Error extracting thumbnail: $e');
//     }
//     return null;
//   }

//   // Helper methods
//   IconData _getPlatformIcon(String url) {
//     if (url.contains('youtube.com') || url.contains('youtu.be')) {
//       return Icons.play_circle_fill;
//     } else if (url.contains('instagram.com')) {
//       return Icons.camera_alt;
//     } else if (url.contains('tiktok.com')) {
//       return Icons.music_note;
//     } else {
//       return Icons.video_library;
//     }
//   }

//   String _getPlatformName(String url) {
//     if (url.contains('youtube.com') || url.contains('youtu.be')) {
//       return 'YouTube';
//     } else if (url.contains('instagram.com')) {
//       return 'Instagram';
//     } else if (url.contains('tiktok.com')) {
//       return 'TikTok';
//     } else {
//       return 'Web';
//     }
//   }

//   Color _getTagColor(String tag) {
//     switch (tag.toLowerCase()) {
//       case 'web content':
//         return const Color(0xFF7C4DFF);
//       case 'fitness':
//         return const Color(0xFF4CAF50);
//       case 'workout':
//         return const Color(0xFFFF9800);
//       case 'tutorial':
//         return const Color(0xFF9C27B0);
//       case 'health':
//         return const Color(0xFF009688);
//       case 'education':
//         return const Color(0xFF3F51B5);
//       default:
//         return const Color(0xFF757575);
//     }
//   }

//   void _showContentInfo(BuildContext context) async {
//     String? collectionName = await FirestoreService()
//         .findVideoCollectionOptimized(
//           userId: FirebaseAuth.instance.currentUser!.uid,
//           videoId: video.id,
//         );
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.9,
//             constraints: const BoxConstraints(maxHeight: 600),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       const Text(
//                         'Content Info',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFF1F2937),
//                         ),
//                       ),
//                       const Spacer(),
//                       IconButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         icon: const Icon(Icons.close),
//                         color: Colors.grey[600],
//                       ),
//                     ],
//                   ),
//                 ),
//                 // Content
//                 Flexible(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Title
//                         Text(
//                           video.name,
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         // Summary
//                         const Text(
//                           'Summary',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           video.description,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // Platform
//                         const Text(
//                           'Platform',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           _getPlatformName(video.url),
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // Collection
//                         const Text(
//                           'Collection',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           collectionName ?? "",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // Tags
//                         const Text(
//                           'Tags',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 8,
//                           children: video.tags
//                               .map(
//                                 (tag) => Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 12,
//                                     vertical: 6,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: _getTagColor(tag),
//                                     borderRadius: BorderRadius.circular(16),
//                                   ),
//                                   child: Text(
//                                     tag,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                         ),
//                         const SizedBox(height: 20),
//                         // Saved
//                         const Text(
//                           'Saved',
//                           style: TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1F2937),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           _formatDate(video.createdAt),
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Footer buttons
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: const BoxDecoration(
//                     border: Border(
//                       top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.of(context).pop(),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             side: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           child: Text(
//                             'Close',
//                             style: TextStyle(
//                               color: Colors.grey[700],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.of(context).pop();
//                             _launchUrl(context, video.url);
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFF7C4DFF),
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: const Text(
//                             'Open Link',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildTagChips(List<String> tags) {
//     if (tags.isEmpty) return const SizedBox.shrink();

//     return Wrap(
//       spacing: 8,
//       runSpacing: 4,
//       children: tags
//           .take(3)
//           .map(
//             (tag) => Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: _getTagColor(tag),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Text(
//                 tag,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           )
//           .toList(),
//     );
//   }

//   // Build thumbnail widget with fallback gradient
//   Widget _buildThumbnail() {
//     final thumbnailUrl = _getThumbnailUrl(video.url);

//     return Container(
//       height: 180,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//         gradient: thumbnailUrl == null
//             ? LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
//               )
//             : null,
//       ),
//       child: Stack(
//         children: [
//           // Thumbnail image (if available)
//           if (thumbnailUrl != null)
//             ClipRRect(
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//               child: Image.network(
//                 thumbnailUrl,
//                 width: double.infinity,
//                 height: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   // Fallback to gradient if image fails to load
//                   return Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           const Color(0xFF7C4DFF),
//                           const Color(0xFF9C27B0),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           const Color(0xFF7C4DFF),
//                           const Color(0xFF9C27B0),
//                         ],
//                       ),
//                     ),
//                     child: Center(
//                       child: CircularProgressIndicator(
//                         value: loadingProgress.expectedTotalBytes != null
//                             ? loadingProgress.cumulativeBytesLoaded /
//                                   loadingProgress.expectedTotalBytes!
//                             : null,
//                         color: Colors.white,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           // Dark overlay for better text visibility
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.black.withOpacity(0.3),
//                   Colors.black.withOpacity(0.1),
//                 ],
//               ),
//             ),
//           ),
//           // Play overlay
//           Center(
//             child: Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.6),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 _getPlatformIcon(video.url),
//                 color: Colors.white,
//                 size: 30,
//               ),
//             ),
//           ),
//           // Platform indicator
//           Positioned(
//             top: 12,
//             right: 12,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: Text(
//                 _getPlatformName(video.url),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               spreadRadius: 0,
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Thumbnail section with real thumbnails
//             _buildThumbnail(),
//             // Content section
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Title
//                   Text(
//                     video.name,
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Color(0xFF1A1A1A),
//                       height: 1.3,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),
//                   // Description
//                   Text(
//                     video.description,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                       height: 1.4,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 12),
//                   // Tags
//                   _buildTagChips(video.tags),
//                   const SizedBox(height: 16),
//                   // Bottom row with date and action buttons
//                   Row(
//                     children: [
//                       // Date
//                       Text(
//                         _formatDate(video.createdAt).toUpperCase(),
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey[500],
//                           fontWeight: FontWeight.w500,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const Spacer(),
//                       // Action buttons
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Info button
//                           GestureDetector(
//                             onTap: () => _showContentInfo(context),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey[300]!),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 'Info',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // Edit button
//                           ElevatedButton(
//                             onPressed: () async {
//                               try {
//                                 String? collectionName =
//                                     await FirestoreService()
//                                         .findVideoCollection(
//                                           userId: FirebaseAuth
//                                               .instance
//                                               .currentUser!
//                                               .uid,
//                                           videoId: video.id,
//                                         );

//                                 if (collectionName != null) {
//                                   showDialog(
//                                     context: context,
//                                     builder: (context) => EditContentDialog(
//                                       video: video,
//                                       userId: FirebaseAuth
//                                           .instance
//                                           .currentUser!
//                                           .uid,
//                                       collectionName: collectionName,
//                                     ),
//                                   );
//                                 } else {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text(
//                                         'Could not find video collection',
//                                       ),
//                                       backgroundColor: Colors.red,
//                                     ),
//                                   );
//                                 }
//                               } catch (e) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text('Error: $e'),
//                                     backgroundColor: Colors.red,
//                                   ),
//                                 );
//                               }
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               foregroundColor: Colors.grey[700],
//                               side: BorderSide(color: Colors.grey[300]!),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               elevation: 0,
//                               minimumSize: Size.zero,
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             ),
//                             child: const Text(
//                               'Edit',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           // Open button
//                           ElevatedButton(
//                             onPressed: () async {
//                               _launchUrl(context, video.url);
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF7C4DFF),
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               elevation: 0,
//                               minimumSize: Size.zero,
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             ),
//                             child: const Text(
//                               'Open',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDate(DateTime createdAt) {
//     final now = DateTime.now();
//     final difference = now.difference(createdAt);

//     if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }

//   Future<void> _launchUrl(BuildContext context, String? url) async {
//     if (url == null || url.isEmpty) {
//       _showErrorSnackBar(context, 'No URL available');
//       return;
//     }

//     try {
//       if (url.contains('youtube.com') || url.contains('youtu.be')) {
//         await _launchYouTube(url);
//       } else if (url.contains('instagram.com')) {
//         await _launchInstagram(url);
//       } else {
//         await _launchDefault(url);
//       }
//     } catch (e) {
//       print('Launch error: $e');
//       _showErrorSnackBar(context, 'Failed to open video');
//     }
//   }

//   Future<void> _launchYouTube(String url) async {
//     try {
//       String appUrl;

//       if (url.contains('/shorts/')) {
//         String? videoId = _extractYouTubeVideoId(url);
//         if (videoId != null) {
//           appUrl = 'vnd.youtube://$videoId';
//         } else {
//           appUrl = url
//               .replaceAll('https://youtube.com', 'vnd.youtube:')
//               .replaceAll('https://www.youtube.com', 'vnd.youtube:');
//         }
//       } else {
//         appUrl = url
//             .replaceAll('https://youtube.com', 'vnd.youtube:')
//             .replaceAll('https://www.youtube.com', 'vnd.youtube:')
//             .replaceAll('https://youtu.be/', 'vnd.youtube://');
//       }

//       Uri appUri = Uri.parse(appUrl);

//       if (await canLaunchUrl(appUri)) {
//         bool launched = await launchUrl(appUri);
//         if (launched) return;
//       }

//       Uri webUri = Uri.parse(url);
//       await launchUrl(webUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       Uri uri = Uri.parse(url);
//       await launchUrl(uri, mode: LaunchMode.platformDefault);
//     }
//   }

//   Future<void> _launchInstagram(String url) async {
//     try {
//       String appUrl = url
//           .replaceAll('https://instagram.com', 'instagram://')
//           .replaceAll('https://www.instagram.com', 'instagram://');

//       Uri appUri = Uri.parse(appUrl);

//       if (await canLaunchUrl(appUri)) {
//         bool launched = await launchUrl(appUri);
//         if (launched) return;
//       }

//       Uri webUri = Uri.parse(url);
//       await launchUrl(webUri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       Uri uri = Uri.parse(url);
//       await launchUrl(uri, mode: LaunchMode.platformDefault);
//     }
//   }

//   Future<void> _launchDefault(String url) async {
//     String urlToLaunch = url;

//     if (!urlToLaunch.startsWith('http://') &&
//         !urlToLaunch.startsWith('https://')) {
//       urlToLaunch = 'https://$urlToLaunch';
//     }

//     Uri uri = Uri.parse(urlToLaunch);

//     try {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } catch (e) {
//       try {
//         await launchUrl(uri, mode: LaunchMode.platformDefault);
//       } catch (e2) {
//         await launchUrl(uri, mode: LaunchMode.inAppWebView);
//       }
//     }
//   }

//   String? _extractYouTubeVideoId(String url) {
//     if (url.contains('/shorts/')) {
//       final shortsRegExp = RegExp(r'/shorts/([a-zA-Z0-9_-]{11})');
//       final match = shortsRegExp.firstMatch(url);
//       return match?.group(1);
//     }

//     final regExp = RegExp(
//       r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
//       caseSensitive: false,
//     );
//     final match = regExp.firstMatch(url);
//     return match?.group(1);
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
// }

import 'package:clipper/Widgets/edit_content_dailog_box.dart';
import 'package:clipper/firebase_service.dart';
import 'package:clipper/models.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Extract thumbnail URL from video URL
  String? _getThumbnailUrl(String url) {
    try {
      // YouTube thumbnails
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          // Use maxresdefault for best quality, fallback to hqdefault
          return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
        }
      }
      // Instagram thumbnails (limited support - Instagram blocks direct image access)
      else if (url.contains('instagram.com')) {
        // Instagram doesn't allow direct thumbnail extraction
        // You would need to use Instagram's API for this
        return null;
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      );

      // Delete the video from Firestore
      await FirestoreService().deleteVideo(
        userId: FirebaseAuth.instance.currentUser!.uid,
        collectionName: collectionName,
        videoId: video.id,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
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
      if (onDelete != null) {
        onDelete!();
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error message
      _showErrorSnackBar(context, 'Failed to delete video: $e');
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
                        // Collection
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
                          onPressed: () {
                            Navigator.of(context).pop();
                            _launchUrl(context, video.url);
                          },
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

  // Build thumbnail widget with fallback gradient
  // Widget _buildThumbnail() {
  //   final thumbnailUrl = _getThumbnailUrl(video.url);

  //   return Container(
  //     height: 180,
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       borderRadius: const BorderRadius.only(
  //         topLeft: Radius.circular(12),
  //         topRight: Radius.circular(12),
  //       ),
  //       gradient: thumbnailUrl == null
  //           ? LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
  //             )
  //           : null,
  //     ),
  //     child: Stack(
  //       children: [
  //         // Thumbnail image (if available)
  //         if (thumbnailUrl != null)
  //           ClipRRect(
  //             borderRadius: const BorderRadius.only(
  //               topLeft: Radius.circular(12),
  //               topRight: Radius.circular(12),
  //             ),
  //             child: Image.network(
  //               thumbnailUrl,
  //               width: double.infinity,
  //               height: double.infinity,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) {
  //                 // Fallback to gradient if image fails to load
  //                 return Container(
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                       colors: [
  //                         const Color(0xFF7C4DFF),
  //                         const Color(0xFF9C27B0),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               },
  //               loadingBuilder: (context, child, loadingProgress) {
  //                 if (loadingProgress == null) return child;
  //                 return Container(
  //                   decoration: BoxDecoration(
  //                     gradient: LinearGradient(
  //                       begin: Alignment.topLeft,
  //                       end: Alignment.bottomRight,
  //                       colors: [
  //                         const Color(0xFF7C4DFF),
  //                         const Color(0xFF9C27B0),
  //                       ],
  //                     ),
  //                   ),
  //                   child: Center(
  //                     child: CircularProgressIndicator(
  //                       value: loadingProgress.expectedTotalBytes != null
  //                           ? loadingProgress.cumulativeBytesLoaded /
  //                                 loadingProgress.expectedTotalBytes!
  //                           : null,
  //                       color: Colors.white,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         // Dark overlay for better text visibility
  //         Container(
  //           decoration: BoxDecoration(
  //             borderRadius: const BorderRadius.only(
  //               topLeft: Radius.circular(12),
  //               topRight: Radius.circular(12),
  //             ),
  //             gradient: LinearGradient(
  //               begin: Alignment.topCenter,
  //               end: Alignment.bottomCenter,
  //               colors: [
  //                 Colors.black.withOpacity(0.3),
  //                 Colors.black.withOpacity(0.1),
  //               ],
  //             ),
  //           ),
  //         ),
  //         // Play overlay
  //         Center(
  //           child: Container(
  //             width: 60,
  //             height: 60,
  //             decoration: BoxDecoration(
  //               color: Colors.black.withOpacity(0.6),
  //               shape: BoxShape.circle,
  //             ),
  //             child: Icon(
  //               _getPlatformIcon(video.url),
  //               color: Colors.white,
  //               size: 30,
  //             ),
  //           ),
  //         ),
  //         // Platform indicator
  //         Positioned(
  //           top: 12,
  //           right: 12,
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: Colors.black.withOpacity(0.7),
  //               borderRadius: BorderRadius.circular(4),
  //             ),
  //             child: Text(
  //               _getPlatformName(video.url),
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 10,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Build thumbnail widget with fallback gradient
  Widget _buildThumbnail(BuildContext context) {
    final thumbnailUrl = _getThumbnailUrl(video.url);

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: thumbnailUrl == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF7C4DFF), const Color(0xFF9C27B0)],
              )
            : null,
      ),
      child: Stack(
        children: [
          // Thumbnail image (if available)
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                thumbnailUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient if image fails to load
                  return Container(
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
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
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
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          // Dark overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),
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
          // Delete button - Top left
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
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
                  size: 20,
                ),
              ),
            ),
          ),
          // Platform indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
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
            // Thumbnail section with real thumbnails
            _buildThumbnail(context),
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
                          ElevatedButton(
                            onPressed: () async {
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
