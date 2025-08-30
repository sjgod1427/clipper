// import 'package:clipper/Widgets/video_card.dart';
// import 'package:clipper/add_url_screen.dart';
// import 'package:clipper/models.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({Key? key}) : super(key: key);

//   @override
//   _LibraryScreenState createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   Set<String> _selectedTags = {'All'}; // Changed to Set for multiple selection
//   Set<String> _selectedPlatforms = {'All'}; // Platform filter
//   List<String> _availableTags = ['All'];
//   List<String> _availablePlatforms = [
//     'All',
//     'YouTube',
//     'Instagram',
//   ]; // Platform options
//   List<VideoModel> _allVideos = [];
//   List<VideoModel> _filteredVideos = [];
//   bool _isLoading = true;
//   String _searchQuery = '';

//   // Enhanced tag system with predefined popular tags
//   static const List<String> _predefinedTags = [
//     'All',
//     'Fitness',
//     'Workout',
//     'Tutorial',
//     'Health',
//     'Education',
//     'Entertainment',
//     'Music',
//     'Gaming',
//     'Cooking',
//     'Travel',
//     'Technology',
//     'News',
//     'Sports',
//     'Fashion',
//     'Beauty',
//     'Comedy',
//     'Science',
//     'Art',
//     'Photography',
//     'Business',
//     'Finance',
//     'Motivation',
//     'Lifestyle',
//     'DIY',
//     'Crafts',
//     'Pets',
//     'Nature',
//     'Food',
//     'Recipe',
//     'Review',
//     'Unboxing',
//     'Vlog',
//     'Documentary',
//     'History',
//     'Philosophy',
//     'Psychology',
//     'Medicine',
//     'Yoga',
//     'Meditation',
//     'Dance',
//     'Languages',
//     'Programming',
//     'Design',
//     'Marketing',
//     'Productivity',
//     'Self-help',
//     'Books',
//     'Movies',
//     'TV Shows',
//     'Anime',
//     'Podcasts',
//     'Interview',
//     'Behind the Scenes',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadVideosFromFirebase();
//     _searchController.addListener(_onSearchChanged);
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     setState(() {
//       _searchQuery = _searchController.text.toLowerCase();
//       _applyFilters();
//     });
//   }

//   // Helper method to determine platform from URL
//   String _getPlatformFromUrl(String url) {
//     if (url.contains('youtube.com') || url.contains('youtu.be')) {
//       return 'YouTube';
//     } else if (url.contains('instagram.com')) {
//       return 'Instagram';
//     }
//     return 'Other';
//   }

//   Future<void> _loadVideosFromFirebase() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId == null) {
//         throw Exception('User not authenticated');
//       }

//       List<VideoModel> allVideos = [];
//       Set<String> allTags = {'All'};
//       Set<String> allPlatforms = {'All'};

//       // Get all collections
//       final collectionsSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .get();

//       // Fetch videos from each collection
//       for (final collectionDoc in collectionsSnapshot.docs) {
//         final videosSnapshot = await collectionDoc.reference
//             .collection('videos')
//             .orderBy('createdAt', descending: true)
//             .get();

//         for (final videoDoc in videosSnapshot.docs) {
//           final video = VideoModel.fromFirestore(videoDoc.id, videoDoc.data());

//           // Add tags to the set
//           allTags.addAll(video.tags);

//           // Determine and add platform
//           String platform = _getPlatformFromUrl(video.url);
//           allPlatforms.add(platform);

//           allVideos.add(video);
//         }
//       }

//       // Merge with predefined tags and sort
//       allTags.addAll(_predefinedTags);
//       final sortedTags = allTags.toList()
//         ..sort((a, b) {
//           if (a == 'All') return -1;
//           if (b == 'All') return 1;
//           return a.compareTo(b);
//         });

//       // Sort platforms in specific order: All, YouTube, Instagram, Others
//       final sortedPlatforms = allPlatforms.toList()
//         ..sort((a, b) {
//           // Define the desired order
//           const order = ['All', 'YouTube', 'Instagram', 'Other'];
//           int indexA = order.contains(a) ? order.indexOf(a) : order.length;
//           int indexB = order.contains(b) ? order.indexOf(b) : order.length;
//           return indexA.compareTo(indexB);
//         });

//       setState(() {
//         _allVideos = allVideos;
//         _availableTags = sortedTags;
//         _availablePlatforms = sortedPlatforms;
//         _isLoading = false;
//         _applyFilters();
//       });
//     } catch (e) {
//       print('Error loading videos: $e');
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading videos: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _applyFilters() {
//     List<VideoModel> filtered = _allVideos;

//     // Apply platform filter
//     if (!_selectedPlatforms.contains('All') && _selectedPlatforms.isNotEmpty) {
//       filtered = filtered.where((video) {
//         String videoPlatform = _getPlatformFromUrl(video.url);
//         return _selectedPlatforms.contains(videoPlatform);
//       }).toList();
//     }

//     // Apply tag filter - Updated for multiple tags
//     if (!_selectedTags.contains('All') && _selectedTags.isNotEmpty) {
//       filtered = filtered
//           .where(
//             (video) => _selectedTags.any(
//               (selectedTag) => video.tags.any(
//                 (videoTag) =>
//                     videoTag.toLowerCase() == selectedTag.toLowerCase(),
//               ),
//             ),
//           )
//           .toList();
//     }

//     // Apply search filter
//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where(
//             (video) =>
//                 video.name.toLowerCase().contains(_searchQuery) ||
//                 video.description.toLowerCase().contains(_searchQuery) ||
//                 video.tags.any(
//                   (tag) => tag.toLowerCase().contains(_searchQuery),
//                 ),
//           )
//           .toList();
//     }

//     setState(() {
//       _filteredVideos = filtered;
//     });
//   }

//   void _onTagSelected(String tag) {
//     setState(() {
//       if (tag == 'All') {
//         // If 'All' is selected, clear other selections and select only 'All'
//         _selectedTags = {'All'};
//       } else {
//         // Remove 'All' if it was selected
//         _selectedTags.remove('All');

//         // Toggle the selected tag
//         if (_selectedTags.contains(tag)) {
//           _selectedTags.remove(tag);

//           // If no tags are selected, default to 'All'
//           if (_selectedTags.isEmpty) {
//             _selectedTags.add('All');
//           }
//         } else {
//           _selectedTags.add(tag);
//         }
//       }
//       _applyFilters();
//     });
//   }

//   void _onPlatformSelected(String platform) {
//     setState(() {
//       if (platform == 'All') {
//         // If 'All' is selected, clear other selections and select only 'All'
//         _selectedPlatforms = {'All'};
//       } else {
//         // Remove 'All' if it was selected
//         _selectedPlatforms.remove('All');

//         // Toggle the selected platform
//         if (_selectedPlatforms.contains(platform)) {
//           _selectedPlatforms.remove(platform);

//           // If no platforms are selected, default to 'All'
//           if (_selectedPlatforms.isEmpty) {
//             _selectedPlatforms.add('All');
//           }
//         } else {
//           _selectedPlatforms.add(platform);
//         }
//       }
//       _applyFilters();
//     });
//   }

//   void _clearAllFilters() {
//     setState(() {
//       _selectedTags = {'All'};
//       _selectedPlatforms = {'All'};
//       _applyFilters();
//     });
//   }

//   void _onVideoTap(VideoModel video) {
//     // Navigate to video detail or open video
//     print('Opening video: ${video.name}');
//     // TODO: Implement video opening logic
//     // You could launch the URL here
//     // import 'package:url_launcher/url_launcher.dart';
//     // launchUrl(Uri.parse(video.url));
//   }

//   void _onVideoEdit(VideoModel video) {
//     // Navigate to edit screen
//     print('Editing video: ${video.name}');
//     // TODO: Implement edit functionality
//   }

//   Future<void> _refreshData() async {
//     await _loadVideosFromFirebase();
//   }

//   // Helper method to get platform icon
//   Widget _getPlatformIcon(String platform) {
//     switch (platform) {
//       case 'YouTube':
//         return Icon(Icons.play_circle_fill, size: 16, color: Colors.red);
//       case 'Instagram':
//         return Icon(Icons.camera_alt, size: 16, color: Colors.purple);
//       default:
//         return Icon(Icons.public, size: 16, color: Colors.grey);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   const Text(
//                     'Library',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   Spacer(),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => AddUrlScreen()),
//                       );
//                     },
//                     child: const Text(
//                       'New',
//                       style: TextStyle(
//                         color: Color(0xFF7C4DFF),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Search Bar
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: TextField(
//                   controller: _searchController,
//                   decoration: const InputDecoration(
//                     hintText: 'Search your saved content...',
//                     hintStyle: TextStyle(color: Colors.grey),
//                     prefixIcon: Icon(Icons.search, color: Colors.grey),
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Selected filters summary and clear button
//             if ((_selectedTags.length > 1 || !_selectedTags.contains('All')) ||
//                 (_selectedPlatforms.length > 1 ||
//                     !_selectedPlatforms.contains('All')))
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           if (_selectedPlatforms.length > 1 ||
//                               !_selectedPlatforms.contains('All'))
//                             Text(
//                               'Platforms: ${_selectedPlatforms.where((platform) => platform != 'All').join(', ')}',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           if (_selectedTags.length > 1 ||
//                               !_selectedTags.contains('All'))
//                             Text(
//                               'Tags: ${_selectedTags.where((tag) => tag != 'All').join(', ')}',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[600],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                         ],
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: _clearAllFilters,
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 4,
//                         ),
//                         minimumSize: Size(0, 0),
//                       ),
//                       child: Text(
//                         'Clear All',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Color(0xFF7C4DFF),
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             // Platform Filter Chips
//             Container(
//               height: 60,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Text(
//                       'Platforms',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       scrollDirection: Axis.horizontal,
//                       itemCount: _availablePlatforms.length,
//                       itemBuilder: (context, index) {
//                         final platform = _availablePlatforms[index];
//                         final isSelected = _selectedPlatforms.contains(
//                           platform,
//                         );

//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: FilterChip(
//                             label: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 if (platform != 'All') ...[
//                                   _getPlatformIcon(platform),
//                                   const SizedBox(width: 4),
//                                 ],
//                                 Text(
//                                   platform,
//                                   style: TextStyle(
//                                     color: isSelected
//                                         ? Colors.white
//                                         : Colors.grey[700],
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             selected: isSelected,
//                             selectedColor: const Color(0xFF7C4DFF),
//                             backgroundColor: Colors.grey[200],
//                             onSelected: (_) => _onPlatformSelected(platform),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             elevation: isSelected ? 2 : 0,
//                             shadowColor: const Color(
//                               0xFF7C4DFF,
//                             ).withOpacity(0.3),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 8),

//             // Enhanced Tag Filter Chips with multiple selection
//             Container(
//               height: 60,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Text(
//                       'Tags',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       scrollDirection: Axis.horizontal,
//                       itemCount: _availableTags.length,
//                       itemBuilder: (context, index) {
//                         final tag = _availableTags[index];
//                         final isSelected = _selectedTags.contains(tag);

//                         return Padding(
//                           padding: const EdgeInsets.only(right: 8),
//                           child: FilterChip(
//                             label: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   tag,
//                                   style: TextStyle(
//                                     color: isSelected
//                                         ? Colors.white
//                                         : Colors.grey[700],
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             selected: isSelected,
//                             selectedColor: const Color(0xFF7C4DFF),
//                             backgroundColor: Colors.grey[200],
//                             onSelected: (_) => _onTagSelected(tag),
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 8,
//                             ),
//                             elevation: isSelected ? 2 : 0,
//                             shadowColor: const Color(
//                               0xFF7C4DFF,
//                             ).withOpacity(0.3),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Videos List
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _filteredVideos.isEmpty
//                   ? _buildEmptyState()
//                   : RefreshIndicator(
//                       onRefresh: _refreshData,
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(horizontal: 20),
//                         itemCount: _filteredVideos.length,
//                         itemBuilder: (context, index) {
//                           final video = _filteredVideos[index];
//                           return RecentVideoCard(video: video, onTap: () {});
//                         },
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             _searchQuery.isNotEmpty
//                 ? 'No videos found for "$_searchQuery"'
//                 : (!_selectedTags.contains('All') ||
//                       !_selectedPlatforms.contains('All'))
//                 ? 'No videos found for selected filters'
//                 : 'No videos saved yet',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Start saving videos to see them here',
//             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:clipper/Widgets/video_card.dart';
import 'package:clipper/add_url_screen.dart';
import 'package:clipper/models.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedTags = {'All'}; // Changed to Set for multiple selection
  Set<String> _selectedPlatforms = {'All'}; // Platform filter
  List<String> _availableTags = ['All'];
  List<String> _availablePlatforms = [
    'All',
    'YouTube',
    'Instagram',
  ]; // Platform options
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Enhanced tag system with predefined popular tags
  static const List<String> _predefinedTags = [
    'All',
    'Fitness',
    'Workout',
    'Tutorial',
    'Health',
    'Education',
    'Entertainment',
    'Music',
    'Gaming',
    'Cooking',
    'Travel',
    'Technology',
    'News',
    'Sports',
    'Fashion',
    'Beauty',
    'Comedy',
    'Science',
    'Art',
    'Photography',
    'Business',
    'Finance',
    'Motivation',
    'Lifestyle',
    'DIY',
    'Crafts',
    'Pets',
    'Nature',
    'Food',
    'Recipe',
    'Review',
    'Unboxing',
    'Vlog',
    'Documentary',
    'History',
    'Philosophy',
    'Psychology',
    'Medicine',
    'Yoga',
    'Meditation',
    'Dance',
    'Languages',
    'Programming',
    'Design',
    'Marketing',
    'Productivity',
    'Self-help',
    'Books',
    'Movies',
    'TV Shows',
    'Anime',
    'Podcasts',
    'Interview',
    'Behind the Scenes',
  ];

  @override
  void initState() {
    super.initState();
    _loadVideosFromFirebase();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  // Helper method to determine platform from URL
  String _getPlatformFromUrl(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube';
    } else if (url.contains('instagram.com')) {
      return 'Instagram';
    }
    return 'Other';
  }

  Future<void> _loadVideosFromFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      List<VideoModel> allVideos = [];
      Set<String> allTags = {'All'};
      Set<String> allPlatforms = {'All'};

      // Get all collections
      final collectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .get();

      // Fetch videos from each collection
      for (final collectionDoc in collectionsSnapshot.docs) {
        final videosSnapshot = await collectionDoc.reference
            .collection('videos')
            .orderBy('createdAt', descending: true)
            .get();

        for (final videoDoc in videosSnapshot.docs) {
          final video = VideoModel.fromFirestore(videoDoc.id, videoDoc.data());

          // Add tags to the set
          allTags.addAll(video.tags);

          // Determine and add platform
          String platform = _getPlatformFromUrl(video.url);
          allPlatforms.add(platform);

          allVideos.add(video);
        }
      }

      // Merge with predefined tags and sort
      allTags.addAll(_predefinedTags);
      final sortedTags = allTags.toList()
        ..sort((a, b) {
          if (a == 'All') return -1;
          if (b == 'All') return 1;
          return a.compareTo(b);
        });

      // Sort platforms in specific order: All, YouTube, Instagram, Others
      final sortedPlatforms = allPlatforms.toList()
        ..sort((a, b) {
          // Define the desired order
          const order = ['All', 'YouTube', 'Instagram', 'Other'];
          int indexA = order.contains(a) ? order.indexOf(a) : order.length;
          int indexB = order.contains(b) ? order.indexOf(b) : order.length;
          return indexA.compareTo(indexB);
        });

      setState(() {
        _allVideos = allVideos;
        _availableTags = sortedTags;
        _availablePlatforms = sortedPlatforms;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading videos: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading videos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<VideoModel> filtered = _allVideos;

    // Apply platform filter
    if (!_selectedPlatforms.contains('All') && _selectedPlatforms.isNotEmpty) {
      filtered = filtered.where((video) {
        String videoPlatform = _getPlatformFromUrl(video.url);
        return _selectedPlatforms.contains(videoPlatform);
      }).toList();
    }

    // Apply tag filter - Updated for multiple tags
    if (!_selectedTags.contains('All') && _selectedTags.isNotEmpty) {
      filtered = filtered
          .where(
            (video) => _selectedTags.any(
              (selectedTag) => video.tags.any(
                (videoTag) =>
                    videoTag.toLowerCase() == selectedTag.toLowerCase(),
              ),
            ),
          )
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (video) =>
                video.name.toLowerCase().contains(_searchQuery) ||
                video.description.toLowerCase().contains(_searchQuery) ||
                video.tags.any(
                  (tag) => tag.toLowerCase().contains(_searchQuery),
                ),
          )
          .toList();
    }

    setState(() {
      _filteredVideos = filtered;
    });
  }

  void _onTagSelected(String tag) {
    setState(() {
      if (tag == 'All') {
        // If 'All' is selected, clear other selections and select only 'All'
        _selectedTags = {'All'};
      } else {
        // Remove 'All' if it was selected
        _selectedTags.remove('All');

        // Toggle the selected tag
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);

          // If no tags are selected, default to 'All'
          if (_selectedTags.isEmpty) {
            _selectedTags.add('All');
          }
        } else {
          _selectedTags.add(tag);
        }
      }
      _applyFilters();
    });
  }

  void _onPlatformSelected(String platform) {
    setState(() {
      if (platform == 'All') {
        // If 'All' is selected, clear other selections and select only 'All'
        _selectedPlatforms = {'All'};
      } else {
        // Remove 'All' if it was selected
        _selectedPlatforms.remove('All');

        // Toggle the selected platform
        if (_selectedPlatforms.contains(platform)) {
          _selectedPlatforms.remove(platform);

          // If no platforms are selected, default to 'All'
          if (_selectedPlatforms.isEmpty) {
            _selectedPlatforms.add('All');
          }
        } else {
          _selectedPlatforms.add(platform);
        }
      }
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTags = {'All'};
      _selectedPlatforms = {'All'};
      _applyFilters();
    });
  }

  void _onVideoTap(VideoModel video) {
    // Navigate to video detail or open video
    print('Opening video: ${video.name}');
    // TODO: Implement video opening logic
    // You could launch the URL here
    // import 'package:url_launcher/url_launcher.dart';
    // launchUrl(Uri.parse(video.url));
  }

  void _onVideoEdit(VideoModel video) {
    // Navigate to edit screen
    print('Editing video: ${video.name}');
    // TODO: Implement edit functionality
  }

  Future<void> _refreshData() async {
    await _loadVideosFromFirebase();
  }

  // Helper method to get platform icon
  Widget _getPlatformIcon(String platform) {
    switch (platform) {
      case 'YouTube':
        return Icon(Icons.play_circle_fill, size: 16, color: Colors.red);
      case 'Instagram':
        return Icon(Icons.camera_alt, size: 16, color: Colors.purple);
      default:
        return Icon(Icons.public, size: 16, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Enhanced for dark theme
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Library',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddUrlScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(
                        color: Color(0xFF7C4DFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar - Enhanced for dark theme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: isDarkMode
                      ? Border.all(color: Colors.grey[700]!, width: 1)
                      : null,
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search your saved content...',
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected filters summary and clear button - Enhanced for dark theme
            if ((_selectedTags.length > 1 || !_selectedTags.contains('All')) ||
                (_selectedPlatforms.length > 1 ||
                    !_selectedPlatforms.contains('All')))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF7C4DFF).withOpacity(0.1)
                        : const Color(0xFF7C4DFF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF7C4DFF).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedPlatforms.length > 1 ||
                                !_selectedPlatforms.contains('All'))
                              Text(
                                'Platforms: ${_selectedPlatforms.where((platform) => platform != 'All').join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (_selectedTags.length > 1 ||
                                !_selectedTags.contains('All'))
                              Text(
                                'Tags: ${_selectedTags.where((tag) => tag != 'All').join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _clearAllFilters,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 0),
                        ),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7C4DFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Platform Filter Chips - Enhanced for dark theme
            Container(
              height: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Platforms',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _availablePlatforms.length,
                      itemBuilder: (context, index) {
                        final platform = _availablePlatforms[index];
                        final isSelected = _selectedPlatforms.contains(
                          platform,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (platform != 'All') ...[
                                  _getPlatformIcon(platform),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  platform,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDarkMode
                                              ? Colors.grey[300]
                                              : Colors.grey[700]),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF7C4DFF),
                            backgroundColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            onSelected: (_) => _onPlatformSelected(platform),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            elevation: isSelected ? 2 : 0,
                            shadowColor: const Color(
                              0xFF7C4DFF,
                            ).withOpacity(0.3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Enhanced Tag Filter Chips with multiple selection - Enhanced for dark theme
            Container(
              height: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableTags.length,
                      itemBuilder: (context, index) {
                        final tag = _availableTags[index];
                        final isSelected = _selectedTags.contains(tag);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700]),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF7C4DFF),
                            backgroundColor: isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[200],
                            onSelected: (_) => _onTagSelected(tag),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            elevation: isSelected ? 2 : 0,
                            shadowColor: const Color(
                              0xFF7C4DFF,
                            ).withOpacity(0.3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Videos List - Enhanced for dark theme
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF7C4DFF),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your library...',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredVideos.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: const Color(0xFF7C4DFF),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = _filteredVideos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RecentVideoCard(
                              video: video,
                              onTap: () => {},
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 60,
              color: Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No videos found for "$_searchQuery"'
                : (!_selectedTags.contains('All') ||
                      !_selectedPlatforms.contains('All'))
                ? 'No videos found for selected filters'
                : 'No videos saved yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try searching with different keywords'
                : (!_selectedTags.contains('All') ||
                      !_selectedPlatforms.contains('All'))
                ? 'Try adjusting your filters or clear all filters'
                : 'Start saving videos to see them here',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty &&
              _selectedTags.contains('All') &&
              _selectedPlatforms.contains('All')) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddUrlScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Save Your First Video',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Enhanced Video Card Widget with better dark theme support
