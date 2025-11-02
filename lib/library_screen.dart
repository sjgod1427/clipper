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
  final FocusNode _searchFocusNode = FocusNode();
  Set<String> _selectedTags = {'All'};
  Set<String> _selectedPlatforms = {'All'};
  List<String> _availableTags = ['All'];
  List<String> _availablePlatforms = ['All', 'YouTube', 'Instagram', 'Other'];
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isTagsExpanded = false;
  bool _isPlatformsExpanded = false;

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
    _searchFocusNode.dispose();
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

  // Helper method to get platform icon
  Widget _getPlatformIcon(String platform, {double size = 16}) {
    switch (platform) {
      case 'YouTube':
        return Icon(Icons.play_circle_fill, size: size, color: Colors.red);
      case 'Instagram':
        return Icon(Icons.camera_alt, size: size, color: Colors.purple);
      default:
        return Icon(Icons.public, size: size, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final searchBackgroundColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _isTagsExpanded = false;
          _isPlatformsExpanded = false;
        });
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Text(
                            'Library',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddUrlScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF7C4DFF,
                              ).withOpacity(0.1),
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

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: searchBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(color: textColor),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search your saved content...',
                            hintStyle: TextStyle(color: secondaryTextColor),
                            prefixIcon: Icon(
                              Icons.search,
                              color: secondaryTextColor,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: secondaryTextColor,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) {
                            _searchFocusNode.unfocus();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filters Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Platform Dropdown
                          Expanded(
                            child: _buildElegantDropdown(
                              title: 'Platform',
                              icon: Icons.devices_rounded,
                              selectedCount: _selectedPlatforms.contains('All')
                                  ? 0
                                  : _selectedPlatforms.length,
                              isExpanded: _isPlatformsExpanded,
                              onTap: () {
                                setState(() {
                                  _isPlatformsExpanded = !_isPlatformsExpanded;
                                  _isTagsExpanded = false;
                                });
                              },
                              isDarkMode: isDarkMode,
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tags Dropdown
                          Expanded(
                            child: _buildElegantDropdown(
                              title: 'Tags',
                              icon: Icons.label_rounded,
                              selectedCount: _selectedTags.contains('All')
                                  ? 0
                                  : _selectedTags.length,
                              isExpanded: _isTagsExpanded,
                              onTap: () {
                                setState(() {
                                  _isTagsExpanded = !_isTagsExpanded;
                                  _isPlatformsExpanded = false;
                                });
                              },
                              isDarkMode: isDarkMode,
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ),
                          // Clear all button
                          if ((_selectedTags.length > 1 ||
                                  !_selectedTags.contains('All')) ||
                              (_selectedPlatforms.length > 1 ||
                                  !_selectedPlatforms.contains('All')))
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.clear_all_rounded),
                                color: const Color(0xFF7C4DFF),
                                tooltip: 'Clear all filters',
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Platform Dropdown Content
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isPlatformsExpanded ? null : 0,
                      child: _isPlatformsExpanded
                          ? _buildPlatformDropdownContent(
                              isDarkMode,
                              textColor,
                              secondaryTextColor,
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Tags Dropdown Content
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: _isTagsExpanded ? null : 0,
                      child: _isTagsExpanded
                          ? _buildTagsDropdownContent(
                              isDarkMode,
                              textColor,
                              secondaryTextColor,
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 16),

                    // Videos List
                    if (_isLoading)
                      Expanded(
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
                                'Loading your library...',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_filteredVideos.isEmpty)
                      Expanded(child: _buildEmptyState())
                    else
                      ..._filteredVideos.map((video) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 12,
                          ),
                          child: RecentVideoCard(video: video, onTap: () => {}),
                        );
                      }).toList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantDropdown({
    required String title,
    required IconData icon,
    required int selectedCount,
    required bool isExpanded,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color textColor,
    required Color? secondaryTextColor,
  }) {
    final bool hasSelection = selectedCount > 0;
    final Color buttonColor = hasSelection
        ? const Color(0xFF7C4DFF).withOpacity(0.15)
        : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!);
    final Color iconColor = hasSelection || isExpanded
        ? const Color(0xFF7C4DFF)
        : secondaryTextColor!;
    final Color titleColor = hasSelection || isExpanded
        ? const Color(0xFF7C4DFF)
        : textColor;

    // Determine what text to display
    String displayText = title;
    if (hasSelection) {
      displayText = '$selectedCount ${title.toLowerCase()}';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFF7C4DFF)
                : (hasSelection
                      ? const Color(0xFF7C4DFF).withOpacity(0.3)
                      : Colors.transparent),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformDropdownContent(
    bool isDarkMode,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Platforms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availablePlatforms.map((platform) {
              final isSelected = _selectedPlatforms.contains(platform);
              return InkWell(
                onTap: () => _onPlatformSelected(platform),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C4DFF)
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (platform != 'All') ...[
                        _getPlatformIcon(platform, size: 18),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        platform,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (isSelected && platform != 'All') ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsDropdownContent(
    bool isDarkMode,
    Color textColor,
    Color? secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Tags',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (_selectedTags.length > 1 || !_selectedTags.contains('All'))
                Text(
                  '${_selectedTags.length} selected',
                  style: TextStyle(fontSize: 12, color: secondaryTextColor),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return InkWell(
                    onTap: () => _onTagSelected(tag),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : (isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (isSelected && tag != 'All') ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
                : 'No videos saved yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: secondaryTextColor,
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
            style: TextStyle(fontSize: 14, color: secondaryTextColor),
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
