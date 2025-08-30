import 'package:clipper/add_url_screen.dart';

import 'package:clipper/video_details_screen.dart';
import 'package:clipper/models.dart';
import 'package:clipper/Widgets/video_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionScreen extends StatefulWidget {
  final String collectionId;
  final String collectionName;

  const CollectionScreen({
    super.key,
    required this.collectionId,
    required this.collectionName,
  });

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedTags = {'All'};
  Set<String> _selectedPlatforms = {'All'};
  List<String> _availableTags = ['All'];
  List<String> _availablePlatforms = ['All', 'YouTube', 'Instagram', 'Other'];
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

      // Get videos from this specific collection
      final videosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(widget.collectionId)
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

    // Apply tag filter
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
        _selectedTags = {'All'};
      } else {
        _selectedTags.remove('All');
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);
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
        _selectedPlatforms = {'All'};
      } else {
        _selectedPlatforms.remove('All');
        if (_selectedPlatforms.contains(platform)) {
          _selectedPlatforms.remove(platform);
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
    // Get theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final searchBackgroundColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with Collection Theme
          SliverAppBar(
            expandedHeight: 120.0,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            Colors.deepPurple.shade700,
                            Colors.purple.shade600,
                            Colors.indigo.shade600,
                          ]
                        : [
                            Colors.indigo.shade600,
                            Colors.blue.shade500,
                            Colors.cyan.shade400,
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
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.collections_bookmark_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.collectionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Search and Filters Section
          SliverToBoxAdapter(
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: searchBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search videos in this collection...',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          prefixIcon: Icon(
                            Icons.search,
                            color: secondaryTextColor,
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

                  // Selected filters summary and clear button
                  if ((_selectedTags.length > 1 ||
                          !_selectedTags.contains('All')) ||
                      (_selectedPlatforms.length > 1 ||
                          !_selectedPlatforms.contains('All')))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                      color: secondaryTextColor,
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
                                      color: secondaryTextColor,
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

                  // Platform Filter Chips
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
                              color: secondaryTextColor,
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
                                              : textColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF7C4DFF),
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                                  onSelected: (_) =>
                                      _onPlatformSelected(platform),
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

                  // Tag Filter Chips
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
                              color: secondaryTextColor,
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
                                          : textColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF7C4DFF),
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
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
                ],
              ),
            ),
          ),

          // Videos Content
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF7C4DFF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading videos...',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _filteredVideos.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final video = _filteredVideos[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RecentVideoCard(
                          video: video,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        VideoDetailScreen(
                                          videoData: {
                                            'name': video.name,
                                            'description': video.description,
                                            'url': video.url,
                                            'tags': video.tags,
                                            'createdAt': video.createdAt,
                                          },
                                          videoId: video.id,
                                          collectionName: widget.collectionName,
                                        ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return SlideTransition(
                                        position:
                                            Tween<Offset>(
                                              begin: const Offset(1, 0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                        ),
                      );
                    }, childCount: _filteredVideos.length),
                  ),
                ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDarkMode ? Colors.deepPurple : Colors.indigo)
                  .withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AddUrlScreen(
                    collectionId: widget.collectionId,
                    collectionName: widget.collectionName,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                      child: child,
                    );
                  },
            ),
          ),
          backgroundColor: isDarkMode
              ? Colors.deepPurple.shade600
              : Colors.indigo.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Add Video',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkMode
        ? Colors.deepPurple.shade400
        : Colors.indigo.shade400;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 60,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No videos found for "$_searchQuery"'
                : (!_selectedTags.contains('All') ||
                      !_selectedPlatforms.contains('All'))
                ? 'No videos found for selected filters'
                : 'No videos yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ||
                    (!_selectedTags.contains('All') ||
                        !_selectedPlatforms.contains('All'))
                ? 'Try adjusting your search or filters'
                : 'Tap the + button to add your first video',
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
