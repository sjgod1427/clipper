import 'dart:async';
import 'package:clipper/Widgets/video_card.dart';
import 'package:clipper/add_url_screen.dart';
import 'package:clipper/collections.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddUrlScreen()),
          );
        },
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF7C4DFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CollectionModel> collections = [];
  List<VideoModel> recentlyViewed = [];
  bool isLoading = true;
  StreamSubscription? _collectionsSubscription;
  StreamSubscription? _recentVideosSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _collectionsSubscription?.cancel();
    _recentVideosSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Listen to collections in real-time
    _collectionsSubscription = FirebaseService.getCollectionsStream(limit: 4)
        .listen(
          (collectionsData) {
            if (mounted) {
              setState(() {
                collections = collectionsData;
                isLoading = false;
              });
            }
          },
          onError: (error) {
            print('Error listening to collections: $error');
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
        );

    // Listen to recent videos in real-time (simplified - no duplicate subscription needed)
    _recentVideosSubscription = FirebaseService.getRecentVideosStream(limit: 5)
        .listen(
          (videos) {
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
    // No need to set isLoading true - RefreshIndicator shows its own loading
    try {
      // Fetch fresh data from Firebase (streams will update automatically)
      final collectionsData = await FirebaseService.getLatestCollections(
        limit: 4,
      );
      final recentData = await FirebaseService.getRecentVideos(limit: 5);

      if (mounted) {
        setState(() {
          collections = collectionsData;
          recentlyViewed = recentData;
        });
      }
    } catch (e) {
      print('Error refreshing data: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to refresh data'),
            backgroundColor: Colors.red[400],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                      // Header
                      _buildHeader(isDarkMode),

                      const SizedBox(height: 32),

                      // Share to Save Card
                      _buildShareToSaveCard(isDarkMode),

                      const SizedBox(height: 32),

                      // Collections Section
                      _buildCollectionsSection(isDarkMode),

                      const SizedBox(height: 32),

                      // Recently Saved Section
                      _buildRecentlySavedSection(isDarkMode),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
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
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              '${_getTotalItemsCount()} items saved',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareToSaveCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF9C6AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
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
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showDemoDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7C4DFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }

  Widget _buildCollectionsSection(bool isDarkMode) {
    return Column(
      children: [
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
        collections.isEmpty
            ? _buildEmptyState(
                isDarkMode: isDarkMode,
                icon: Icons.folder_outlined,
                title: 'No Collections Yet',
                subtitle: 'Start saving videos to create your first collection',
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: collections.length > 4 ? 4 : collections.length,
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
      ],
    );
  }

  Widget _buildRecentlySavedSection(bool isDarkMode) {
    return Column(
      children: [
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
        recentlyViewed.isEmpty
            ? _buildEmptyState(
                isDarkMode: isDarkMode,
                icon: Icons.history_outlined,
                title: 'No Recent Videos',
                subtitle: 'Your recently saved videos will appear here',
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
    );
  }

  Widget _buildEmptyState({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalItemsCount() {
    return collections.fold(0, (sum, collection) => sum + collection.itemCount);
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
            // Icon row
            Icon(
              collection.icon,
              color: collection.color.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
              size: 28,
            ),

            const Spacer(),

            // Collection info at bottom
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
