import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class VideoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;
  final String videoId;
  final String collectionName;

  const VideoDetailScreen({
    super.key,
    required this.videoData,
    required this.videoId,
    required this.collectionName,
  });

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Returns YouTube thumbnail URL - uses hqdefault as it's more reliable
  String _getYouTubeThumbnail(String url) {
    final videoId = _extractYouTubeVideoId(url);
    if (videoId != null) {
      // Use hqdefault as it's available for all videos
      // maxresdefault may not exist for older/lower quality videos
      return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    }
    return '';
  }

  bool _isInstagram(String url) {
    return url.contains('instagram.com') || url.contains('instagr.am');
  }

  bool _isYouTube(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  /// Gets the thumbnail URL from various sources
  /// Priority: 1. Stored thumbnail in data, 2. YouTube generated, 3. Empty (will show gradient)
  String _getThumbnailUrl(String url, Map<String, dynamic> videoData) {
    // First check if thumbnail is stored in the data
    final storedThumbnail = videoData['thumbnail']?.toString() ??
                            videoData['thumbnailUrl']?.toString() ??
                            videoData['image']?.toString() ??
                            videoData['imageUrl']?.toString() ?? '';
    if (storedThumbnail.isNotEmpty) {
      debugPrint('Using stored thumbnail: $storedThumbnail');
      return storedThumbnail;
    }

    // Generate YouTube thumbnail dynamically
    if (_isYouTube(url)) {
      final ytThumb = _getYouTubeThumbnail(url);
      debugPrint('Generated YouTube thumbnail: $ytThumb');
      return ytThumb;
    }

    debugPrint('No thumbnail available for: $url');
    return '';
  }

  /// Returns platform-specific gradient colors
  List<Color> _getPlatformGradient(String url) {
    if (_isYouTube(url)) {
      return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
    } else if (_isInstagram(url)) {
      return [
        const Color(0xFFF58529), // Orange
        const Color(0xFFDD2A7B), // Pink
        const Color(0xFF8134AF), // Purple
        const Color(0xFF515BD4), // Blue
      ];
    }
    return [const Color(0xFF7C4DFF), const Color(0xFF5E35B1)];
  }

  /// Returns platform name for badge
  String _getPlatformName(String url) {
    if (_isYouTube(url)) return 'YouTube';
    if (_isInstagram(url)) return 'Instagram';
    return 'Web Link';
  }

  /// Returns platform icon
  IconData _getPlatformIcon(String url) {
    if (_isYouTube(url)) return Icons.play_circle_filled;
    if (_isInstagram(url)) return Icons.camera_alt_rounded;
    return Icons.link_rounded;
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
    final url = widget.videoData['url'] ?? '';
    final title = widget.videoData['name'] ?? widget.videoData['tag'] ?? 'No Title';
    final description = widget.videoData['description'] ?? '';
    final createdAt = widget.videoData['createdAt'];
    final tags = List<String>.from(widget.videoData['tags'] ?? []);

    // Platform detection
    final isYouTube = _isYouTube(url);
    final isInstagram = _isInstagram(url);
    final thumbnailUrl = _getThumbnailUrl(url, widget.videoData);
    final platformGradient = _getPlatformGradient(url);
    final platformName = _getPlatformName(url);
    final platformIcon = _getPlatformIcon(url);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);
    final isSmallScreen = screenWidth < 360;

    // Colors
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Header with Thumbnail
          SliverAppBar(
            expandedHeight: screenHeight * 0.35,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildGlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
                isSmallScreen: isSmallScreen,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildGlassButton(
                  icon: Icons.share_rounded,
                  onTap: () => _shareVideo(context, url, title),
                  isSmallScreen: isSmallScreen,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                child: _buildGlassButton(
                  icon: Icons.more_vert_rounded,
                  onTap: () => _showOptionsSheet(context, url),
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient or thumbnail
                  if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      cacheWidth: 800,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        // Show gradient with loading indicator while loading
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildGradientBackground(platformGradient, isInstagram),
                            Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white.withOpacity(0.7),
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Thumbnail load error: $error');
                        return _buildGradientBackground(platformGradient, isInstagram);
                      },
                    )
                  else
                    _buildGradientBackground(platformGradient, isInstagram),
                  // Gradient overlay for readability
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
                  // Play button overlay for video platforms
                  if (isYouTube || isInstagram)
                    Center(
                      child: GestureDetector(
                        onTap: () => _launchUrl(context, url),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: isInstagram
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFF58529),
                                      Color(0xFFDD2A7B),
                                      Color(0xFF8134AF),
                                    ],
                                  )
                                : null,
                            color: isYouTube ? Colors.red : null,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: (isInstagram
                                        ? const Color(0xFFDD2A7B)
                                        : Colors.red)
                                    .withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isInstagram
                                ? Icons.play_arrow_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  // Bottom info overlay
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Platform badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: isInstagram
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFF58529),
                                      Color(0xFFDD2A7B),
                                    ],
                                  )
                                : null,
                            color: isInstagram
                                ? null
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: isInstagram
                                ? null
                                : Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                platformIcon,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                platformName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12 * textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (isSmallScreen ? 20 : 24) * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary action button
                      _buildPrimaryActionButton(
                        context,
                        url: url,
                        isSmallScreen: isSmallScreen,
                        textScaleFactor: textScaleFactor,
                      ),
                      const SizedBox(height: 20),

                      // Collection & Date info card
                      _buildInfoCard(
                        context,
                        cardColor: cardColor,
                        isDark: isDark,
                        isSmallScreen: isSmallScreen,
                        textScaleFactor: textScaleFactor,
                        children: [
                          _buildInfoRow(
                            icon: Icons.folder_rounded,
                            iconColor: const Color(0xFF7C4DFF),
                            label: 'Collection',
                            value: widget.collectionName,
                            textColor: textColor,
                            subtitleColor: subtitleColor!,
                            isSmallScreen: isSmallScreen,
                            textScaleFactor: textScaleFactor,
                          ),
                          if (createdAt != null) ...[
                            Divider(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              height: 24,
                            ),
                            _buildInfoRow(
                              icon: Icons.access_time_rounded,
                              iconColor: const Color(0xFF00BCD4),
                              label: 'Saved',
                              value: _formatDate(createdAt),
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isSmallScreen: isSmallScreen,
                              textScaleFactor: textScaleFactor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tags section
                      if (tags.isNotEmpty) ...[
                        _buildTagsCard(
                          context,
                          tags: tags,
                          cardColor: cardColor,
                          isDark: isDark,
                          textColor: textColor,
                          isSmallScreen: isSmallScreen,
                          textScaleFactor: textScaleFactor,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description section
                      if (description.isNotEmpty) ...[
                        _buildDescriptionCard(
                          context,
                          description: description,
                          cardColor: cardColor,
                          isDark: isDark,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          isSmallScreen: isSmallScreen,
                          textScaleFactor: textScaleFactor,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quick actions
                      _buildQuickActionsCard(
                        context,
                        url: url,
                        cardColor: cardColor,
                        isDark: isDark,
                        textColor: textColor,
                        isSmallScreen: isSmallScreen,
                        textScaleFactor: textScaleFactor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground(List<Color> colors, bool isInstagram) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isInstagram ? Alignment.topLeft : Alignment.topLeft,
          end: isInstagram ? Alignment.bottomRight : Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: isInstagram
          ? Center(
              child: Icon(
                Icons.camera_alt_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.2),
              ),
            )
          : null,
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: isSmallScreen ? 36 : 40,
          height: isSmallScreen ? 36 : 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              borderRadius: BorderRadius.circular(12),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context, {
    required String url,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    final isYouTube = _isYouTube(url);
    final isInstagram = _isInstagram(url);

    // Determine button colors and text based on platform
    List<Color> buttonGradient;
    Color shadowColor;
    IconData buttonIcon;
    String buttonText;

    if (isYouTube) {
      buttonGradient = [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      shadowColor = Colors.red;
      buttonIcon = Icons.play_arrow_rounded;
      buttonText = 'Watch on YouTube';
    } else if (isInstagram) {
      buttonGradient = [
        const Color(0xFFF58529),
        const Color(0xFFDD2A7B),
        const Color(0xFF8134AF),
      ];
      shadowColor = const Color(0xFFDD2A7B);
      buttonIcon = Icons.play_arrow_rounded;
      buttonText = 'View on Instagram';
    } else {
      buttonGradient = [const Color(0xFF7C4DFF), const Color(0xFF5E35B1)];
      shadowColor = const Color(0xFF7C4DFF);
      buttonIcon = Icons.open_in_new_rounded;
      buttonText = 'Open Link';
    }

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 52 : 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: buttonGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _launchUrl(context, url);
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                buttonIcon,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
              const SizedBox(width: 12),
              Text(
                buttonText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (isSmallScreen ? 15 : 17) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required Color cardColor,
    required bool isDark,
    required bool isSmallScreen,
    required double textScaleFactor,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    return Row(
      children: [
        Container(
          width: isSmallScreen ? 36 : 40,
          height: isSmallScreen ? 36 : 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: (isSmallScreen ? 11 : 12) * textScaleFactor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: (isSmallScreen ? 14 : 15) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsCard(
    BuildContext context, {
    required List<String> tags,
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 40,
                height: isSmallScreen ? 36 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: const Color(0xFFE91E63),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Tags',
                style: TextStyle(
                  color: textColor,
                  fontSize: (isSmallScreen ? 15 : 16) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final tagColor = _getTagColor(tag);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      tagColor,
                      tagColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: tagColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (isSmallScreen ? 12 : 13) * textScaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(
    BuildContext context, {
    required String description,
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required Color subtitleColor,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 40,
                height: isSmallScreen ? 36 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notes_rounded,
                  color: const Color(0xFF2196F3),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Description',
                style: TextStyle(
                  color: textColor,
                  fontSize: (isSmallScreen ? 15 : 16) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              color: subtitleColor,
              fontSize: (isSmallScreen ? 13 : 14) * textScaleFactor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(
    BuildContext context, {
    required String url,
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 40,
                height: isSmallScreen ? 36 : 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.flash_on_rounded,
                  color: const Color(0xFF4CAF50),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: textColor,
                  fontSize: (isSmallScreen ? 15 : 16) * textScaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.copy_rounded,
                  label: 'Copy URL',
                  color: const Color(0xFF2196F3),
                  onTap: () => _copyUrl(context, url),
                  isDark: isDark,
                  isSmallScreen: isSmallScreen,
                  textScaleFactor: textScaleFactor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.open_in_browser_rounded,
                  label: 'Browser',
                  color: const Color(0xFF9C27B0),
                  onTap: () => _launchInBrowser(context, url),
                  isDark: isDark,
                  isSmallScreen: isSmallScreen,
                  textScaleFactor: textScaleFactor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required bool isSmallScreen,
    required double textScaleFactor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 14,
              horizontal: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 18 : 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: (isSmallScreen ? 12 : 13) * textScaleFactor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsSheet(BuildContext context, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildSheetOption(
              context,
              icon: Icons.copy_rounded,
              label: 'Copy URL',
              onTap: () {
                Navigator.pop(context);
                _copyUrl(context, url);
              },
              isDark: isDark,
            ),
            _buildSheetOption(
              context,
              icon: Icons.open_in_browser_rounded,
              label: 'Open in Browser',
              onTap: () {
                Navigator.pop(context);
                _launchInBrowser(context, url);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.grey[800],
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showSnackBar(context, 'No URL available', isError: true);
      return;
    }

    try {
      String urlToLaunch = url;

      // Handle YouTube URLs
      if (_isYouTube(url)) {
        String? videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          try {
            final youtubeUri = Uri.parse('vnd.youtube:$videoId');
            if (await canLaunchUrl(youtubeUri)) {
              await launchUrl(youtubeUri);
              return;
            }
          } catch (e) {
            debugPrint('YouTube app URL failed: $e');
          }
          urlToLaunch = 'https://www.youtube.com/watch?v=$videoId';
        }
      }

      // Handle Instagram URLs - try to open in Instagram app first
      if (_isInstagram(url)) {
        try {
          // Try Instagram app deep link
          final instagramUri = Uri.parse(url.replaceFirst('https://', 'instagram://'));
          if (await canLaunchUrl(instagramUri)) {
            await launchUrl(instagramUri);
            return;
          }
        } catch (e) {
          debugPrint('Instagram app URL failed: $e');
        }
      }

      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }

      final uri = Uri.parse(urlToLaunch);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar(context, 'Failed to open video', isError: true);
    }
  }

  Future<void> _launchInBrowser(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showSnackBar(context, 'No URL available', isError: true);
      return;
    }

    try {
      String urlToLaunch = url;
      if (!urlToLaunch.startsWith('http://') &&
          !urlToLaunch.startsWith('https://')) {
        urlToLaunch = 'https://$urlToLaunch';
      }

      final uri = Uri.parse(urlToLaunch);
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      _showSnackBar(context, 'Failed to open browser', isError: true);
    }
  }

  void _copyUrl(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showSnackBar(context, 'URL copied to clipboard');
  }

  void _shareVideo(BuildContext context, String url, String title) {
    Clipboard.setData(ClipboardData(text: '$title\n$url'));
    _showSnackBar(context, 'Link copied for sharing');
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp == null) return 'Unknown';

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

      if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      } else if (difference.inDays > 7) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
