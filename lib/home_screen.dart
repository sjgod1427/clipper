import 'dart:async';
import 'package:clipper/Widgets/video_card.dart';
import 'package:clipper/collections.dart';
import 'package:clipper/create_new_collection.dart';
import 'package:clipper/library_screen.dart';
import 'package:clipper/models.dart';
import 'package:clipper/saved_collections.dart';
import 'package:clipper/service.dart';
import 'package:clipper/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SaveSenseApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'SaveSense',
          theme: themeProvider.currentTheme,
          home: MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/login': (context) =>
                MainNavigationScreen(), // Add your login screen here
          },
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [HomeScreen(), LibraryScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF7C4DFF),
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.backgroundColor,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// class _HomeScreenState extends State<HomeScreen> {
//   List<CollectionModel> collections = [];
//   List<VideoModel> recentlyViewed = [];
//   List<CollectionModel> collections_recent = [];
//   bool isLoading = true;
//   StreamSubscription? _recentVideosSubscription;

//   @override
//   void initState() {
//     super.initState();
//     loadData();
//     _startRealtimeListener();
//   }

//   @override
//   void dispose() {
//     _recentVideosSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> loadData() async {
//     try {
//       // Load collections
//       final collectionsData = await FirebaseService.getLatestCollections();

//       // Check if we need to sync recent videos from Firebase
//       final shouldSync = await CacheService.shouldSyncFromFirebase();
//       if (shouldSync) {
//         await CacheService.syncRecentVideosFromFirebase();
//       }

//       // Get recent videos from cache
//       final recentData = await CacheService.getRecentlyViewed();

//       setState(() {
//         collections = collectionsData;
//         recentlyViewed = recentData;
//         isLoading = false;
//       });
//     } catch (e) {
//       print('Error loading data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _startRealtimeListener() {
//     // Listen to real-time updates for recent videos
//     _recentVideosSubscription = FirebaseService.listenToRecentVideos().listen(
//       (videos) async {
//         // Update cache with new Firebase data
//         await CacheService.updateCacheWithFirebaseData(videos);

//         // Update UI
//         if (mounted) {
//           setState(() {
//             recentlyViewed = videos;
//           });
//         }
//       },
//       onError: (error) {
//         print('Error listening to recent videos: $error');
//       },
//     );
//   }

//   Future<void> _refreshData() async {
//     setState(() {
//       isLoading = true;
//     });

//     // Force sync from Firebase
//     await CacheService.syncRecentVideosFromFirebase();
//     await loadData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: SafeArea(
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : RefreshIndicator(
//                 onRefresh: _refreshData,
//                 child: SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Header - Updated for theme support
//                       Row(
//                         children: [
//                           Container(
//                             width: 40,
//                             height: 40,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF7C4DFF),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Icon(
//                               Icons.bookmark_rounded,
//                               color: Colors.white,
//                               size: 24,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'SaveSense',
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.bold,
//                                   color: isDarkMode
//                                       ? Colors.white
//                                       : Colors.black,
//                                 ),
//                               ),
//                               Text(
//                                 '${_getTotalItemsCount()} items saved',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: isDarkMode
//                                       ? Colors.grey[400]
//                                       : Colors.grey[600],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 32),

//                       // Share to Save Card - Enhanced for theme support
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: isDarkMode
//                                 ? [
//                                     const Color(0xFF7C4DFF),
//                                     const Color(0xFF9C6AFF),
//                                   ]
//                                 : [
//                                     const Color(0xFF7C4DFF),
//                                     const Color(0xFF9C6AFF),
//                                   ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(
//                                 isDarkMode ? 0.3 : 0.1,
//                               ),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Share to Save',
//                               style: TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Share any Reel or Short from Instagram or\nYouTube',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.white70,
//                               ),
//                             ),
//                             const SizedBox(height: 20),
//                             ElevatedButton(
//                               onPressed: () {
//                                 _showDemoDialog();
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.white,
//                                 foregroundColor: const Color(0xFF7C4DFF),
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 24,
//                                   vertical: 12,
//                                 ),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 elevation: 0,
//                               ),
//                               child: const Text(
//                                 'Try Demo Share',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 32),

//                       // Collections Section - Enhanced for theme support
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Collections',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: isDarkMode ? Colors.white : Colors.black,
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => SavedCollectionScreen(),
//                                 ),
//                               );
//                             },
//                             child: const Text(
//                               'See All',
//                               style: TextStyle(
//                                 color: Color(0xFF7C4DFF),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),

//                       const SizedBox(height: 16),

//                       // Collections Grid
//                       GridView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         gridDelegate:
//                             const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               crossAxisSpacing: 16,
//                               mainAxisSpacing: 16,
//                               childAspectRatio: 1.2,
//                             ),
//                         itemCount: collections.length > 4
//                             ? 4
//                             : collections.length,
//                         itemBuilder: (context, index) {
//                           final collection = collections[index];
//                           return CollectionCard(
//                             collection: collection,
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => CollectionScreen(
//                                     collectionId: collection.id,
//                                     collectionName: collection.name,
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       ),

//                       const SizedBox(height: 32),

//                       // Recently Saved Section - Enhanced for theme support
//                       if (recentlyViewed.isNotEmpty) ...[
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Recently Saved',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w600,
//                                 color: isDarkMode ? Colors.white : Colors.black,
//                               ),
//                             ),
//                             TextButton(
//                               onPressed: () {
//                                 // Navigate to all recent items
//                               },
//                               child: const Text(
//                                 'View All',
//                                 style: TextStyle(
//                                   color: Color(0xFF7C4DFF),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: recentlyViewed.length,
//                           itemBuilder: (context, index) {
//                             final video = recentlyViewed[index];
//                             return RecentVideoCard(
//                               video: video,
//                               onTap: () {
//                                 // Handle video tap
//                               },
//                             );
//                           },
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),
//       ),
//     );
//   }

//   int _getTotalItemsCount() {
//     return collections.fold(0, (sum, collection) => sum + collection.itemCount);
//   }

//   void showCreateCollectionDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => CreateCollectionDialog(),
//     );
//   }

//   void _showDemoDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Theme.of(context).dialogBackgroundColor,
//         title: Text(
//           'Demo Share',
//           style: TextStyle(
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white
//                 : Colors.black,
//           ),
//         ),
//         content: Text(
//           'This would open the share interface to save videos from Instagram or YouTube.',
//           style: TextStyle(
//             color: Theme.of(context).brightness == Brightness.dark
//                 ? Colors.white70
//                 : Colors.black87,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK', style: TextStyle(color: Color(0xFF7C4DFF))),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class CollectionCard extends StatelessWidget {
//   final CollectionModel collection;
//   final VoidCallback onTap;

//   const CollectionCard({
//     Key? key,
//     required this.collection,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: collection.color,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Icon and item count row
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Icon(
//                   collection.icon,
//                   color: collection.color.computeLuminance() > 0.5
//                       ? Colors.black87
//                       : Colors.white,
//                   size: 28,
//                 ),
//               ],
//             ),

//             const Spacer(),

//             // Collection name at bottom
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   collection.name,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: collection.color.computeLuminance() > 0.5
//                         ? Colors.black87
//                         : Colors.white,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${collection.itemCount} ${collection.itemCount == 1 ? 'item' : 'items'}',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: collection.color.computeLuminance() > 0.5
//                         ? Colors.black54
//                         : Colors.white70,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _HomeScreenState extends State<HomeScreen> {
  List<CollectionModel> collections = [];
  List<VideoModel> recentlyViewed = [];
  List<CollectionModel> collections_recent = [];
  bool isLoading = true;
  StreamSubscription? _recentVideosSubscription;

  @override
  void initState() {
    super.initState();
    loadData();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _recentVideosSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      // Load collections
      final collectionsData = await FirebaseService.getLatestCollections();

      // Check if we need to sync recent videos from Firebase
      final shouldSync = await CacheService.shouldSyncFromFirebase();
      if (shouldSync) {
        await CacheService.syncRecentVideosFromFirebase();
      }

      // Get recent videos from cache
      final recentData = await CacheService.getRecentlyViewed();

      setState(() {
        collections = collectionsData;
        recentlyViewed = recentData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startRealtimeListener() {
    // Listen to real-time updates for recent videos
    _recentVideosSubscription = FirebaseService.listenToRecentVideos().listen(
      (videos) async {
        // Update cache with new Firebase data
        await CacheService.updateCacheWithFirebaseData(videos);

        // Update UI
        if (mounted) {
          setState(() {
            recentlyViewed = videos;
          });
        }
      },
      onError: (error) {
        print('Error listening to recent videos: $error');
      },
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });

    // Force sync from Firebase
    await CacheService.syncRecentVideosFromFirebase();
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - Updated for theme support
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C4DFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bookmark_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SaveSense',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                '${_getTotalItemsCount()} items saved',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Share to Save Card - Enhanced for theme support
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [
                                    const Color(0xFF7C4DFF),
                                    const Color(0xFF9C6AFF),
                                  ]
                                : [
                                    const Color(0xFF7C4DFF),
                                    const Color(0xFF9C6AFF),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDarkMode ? 0.3 : 0.1,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Share to Save',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Share any Reel or Short from Instagram or\nYouTube',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                _showDemoDialog();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF7C4DFF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Try Demo Share',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Collections Section - Enhanced for theme support
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Collections',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SavedCollectionScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                color: Color(0xFF7C4DFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Collections Grid or Empty State
                      collections.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_outlined,
                                    size: 48,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Collections Yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start saving videos to create your first collection',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: collections.length > 4
                                  ? 4
                                  : collections.length,
                              itemBuilder: (context, index) {
                                final collection = collections[index];
                                return CollectionCard(
                                  collection: collection,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CollectionScreen(
                                          collectionId: collection.id,
                                          collectionName: collection.name,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                      const SizedBox(height: 32),

                      // Recently Saved Section - Enhanced for theme support
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recently Saved',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          if (recentlyViewed.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                // Navigate to all recent items
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF7C4DFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Recent Videos List or Empty State
                      recentlyViewed.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[850]
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history_outlined,
                                    size: 48,
                                    color: isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Recent Videos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your recently saved videos will appear here',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentlyViewed.length,
                              itemBuilder: (context, index) {
                                final video = recentlyViewed[index];
                                return RecentVideoCard(
                                  video: video,
                                  onTap: () {
                                    // Handle video tap
                                  },
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  int _getTotalItemsCount() {
    return collections.fold(0, (sum, collection) => sum + collection.itemCount);
  }

  void showCreateCollectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateCollectionDialog(),
    );
  }

  void _showDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Demo Share',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        content: Text(
          'This would open the share interface to save videos from Instagram or YouTube.',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }
}

class CollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final VoidCallback onTap;

  const CollectionCard({
    Key? key,
    required this.collection,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: collection.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and item count row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  collection.icon,
                  color: collection.color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  size: 28,
                ),
              ],
            ),

            const Spacer(),

            // Collection name at bottom
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: collection.color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${collection.itemCount} ${collection.itemCount == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: collection.color.computeLuminance() > 0.5
                        ? Colors.black54
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
