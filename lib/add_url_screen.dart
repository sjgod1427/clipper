import 'package:clipper/gemini_service.dart';
import 'package:clipper/firebase_service.dart';
import 'package:clipper/instagram_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AddUrlScreen extends StatefulWidget {
  final String? sharedText;
  final String? collectionId;
  final String? collectionName;

  const AddUrlScreen({
    Key? key,
    this.sharedText,
    this.collectionId,
    this.collectionName,
  }) : super(key: key);

  @override
  State<AddUrlScreen> createState() => _AddUrlScreenState();
}

class _AddUrlScreenState extends State<AddUrlScreen> {
  final TextEditingController urlController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController tagsController = TextEditingController();
  final FirestoreService fs = FirestoreService();

  List<String> collections = [];
  String? selectedCollection;
  bool isLoadingCollections = true;
  bool isAutoGenerating = false;
  bool isAddingUrl = false;
  bool? _isFromThirdParty;

  // Quick add tags
  final List<String> quickTags = [
    'challenge',
    'color',
    'core',
    'creativity',
    'dance',
    'design',
    'fitness',
    'habits',
    'tutorial',
    'education',
    'entertainment',
    'music',
  ];

  Set<String> selectedQuickTags = {};

  @override
  void initState() {
    super.initState();
    if (widget.sharedText != null) {
      urlController.text = widget.sharedText!;
    }
    _loadCollections();
  }

  // Helper method to extract platform from URL
  String _getPlatformFromUrl(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return 'YouTube';
    } else if (url.contains('instagram.com')) {
      return 'Instagram';
    } else if (url.contains('tiktok.com')) {
      return 'TikTok';
    } else if (url.contains('twitter.com') || url.contains('x.com')) {
      return 'Twitter';
    } else if (url.contains('facebook.com')) {
      return 'Facebook';
    } else if (url.contains('linkedin.com')) {
      return 'LinkedIn';
    } else {
      return 'Web';
    }
  }

  bool _isFromThirdPartyApp() {
    if (_isFromThirdParty != null) return _isFromThirdParty!;

    try {
      final modalRoute = ModalRoute.of(context);
      bool isFirstRoute = modalRoute?.isFirst ?? false;
      bool canPop = Navigator.of(context).canPop();
      bool hasSharedText =
          widget.sharedText != null && widget.sharedText!.isNotEmpty;

      _isFromThirdParty =
          (isFirstRoute && hasSharedText) || (!canPop && hasSharedText);
      return _isFromThirdParty!;
    } catch (e) {
      _isFromThirdParty =
          widget.sharedText != null && widget.sharedText!.isNotEmpty;
      return _isFromThirdParty!;
    }
  }

  void _exitScreen() {
    if (_isFromThirdPartyApp()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Returning to previous app...'),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        SystemNavigator.pop();
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _loadCollections() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final collectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collections')
          .get();

      final collectionsList = collectionsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      setState(() {
        collections = collectionsList;
        if (widget.collectionId != null &&
            collectionsList.contains(widget.collectionId)) {
          selectedCollection = widget.collectionId;
        } else if (collectionsList.isNotEmpty) {
          selectedCollection = collectionsList.first;
        }
        isLoadingCollections = false;
      });
    } catch (e) {
      setState(() {
        collections = [];
        isLoadingCollections = false;
      });
    }
  }

  Future<void> _showCreateCollectionDialog() async {
    final TextEditingController collectionNameController =
        TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode
            ? const Color(0xFF1E1E1E)
            : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey.shade500;
        final borderColor = isDarkMode
            ? Colors.grey[600]
            : Colors.grey.shade300;

        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'Create New Collection',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: collectionNameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Enter collection name',
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
              ),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
              onPressed: () async {
                final collectionName = collectionNameController.text.trim();
                if (collectionName.isNotEmpty) {
                  await _createNewCollection(collectionName);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewCollection(String collectionName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if collection already exists
      if (collections.contains(collectionName)) {
        _showSnackBar(
          'Collection "$collectionName" already exists!',
          Colors.orange,
        );
        return;
      }

      // Create the collection in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collections')
          .doc(collectionName)
          .set({
            'name': collectionName,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Update local state
      setState(() {
        collections.add(collectionName);
        selectedCollection = collectionName;
      });

      _showSnackBar(
        'Collection "$collectionName" created successfully!',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('Error creating collection: $e', Colors.red);
    }
  }

  void _addQuickTag(String tag) {
    setState(() {
      selectedQuickTags.add(tag);
      _updateTagsController();
    });
  }

  void _removeQuickTag(String tag) {
    setState(() {
      selectedQuickTags.remove(tag);
      _updateTagsController();
    });
  }

  void _updateTagsController() {
    List<String> existingTags = tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    Set<String> allTags = {...existingTags, ...selectedQuickTags};
    tagsController.text = allTags.join(', ');
  }

  void handleAutoGenerate() async {
    final url = urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('Please enter a URL first', Colors.orange);
      return;
    }

    setState(() {
      isAutoGenerating = true;
    });

    try {
      final existingCollections = collections;
      final geminiService = GeminiService();
      final instagramService = Provider.of<InstagramService>(context, listen: false);
      if (instagramService.isConnected) {
        geminiService.instagramService = instagramService;
      }
      final info = await geminiService.generateDetailsFromUrl(
        url,
        existingCollections: existingCollections,
      );

      setState(() {
        nameController.text = info['name'] ?? info['title'] ?? '';
        descriptionController.text = info['description'] ?? '';

        String suggestedTags = info['tags'] ?? '';
        if (suggestedTags.isNotEmpty) {
          tagsController.text = suggestedTags;
        }

        String recommendedCollection = info['collection'] ?? '';
        if (recommendedCollection.isNotEmpty &&
            collections.contains(recommendedCollection)) {
          selectedCollection = recommendedCollection;
        }
      });

      _showSnackBar('Details generated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error generating details: $e', Colors.red);
    } finally {
      setState(() {
        isAutoGenerating = false;
      });
    }
  }

  void handleSaveContent() async {
    final url = urlController.text.trim();
    final name = nameController.text.trim();
    final desc = descriptionController.text.trim();
    final tagsText = tagsController.text.trim();

    if (url.isEmpty || name.isEmpty) {
      _showSnackBar('Please enter URL and title', Colors.orange);
      return;
    }

    setState(() {
      isAddingUrl = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated', Colors.red);
        return;
      }

      List<String> tags = tagsText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final videoData = {
        'name': name,
        'platform': _getPlatformFromUrl(url),
        'description': desc,
        'tags': tags,
        'url': url,
        'createdAt': FieldValue.serverTimestamp(),
      };

      String collectionToUse = selectedCollection ?? 'Default';

      // Ensure collection exists
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collections')
          .doc(collectionToUse)
          .set({
            'name': collectionToUse,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Add video to collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collections')
          .doc(collectionToUse)
          .collection('videos')
          .add(videoData);

      _showSnackBar(
        _isFromThirdPartyApp()
            ? 'Content saved! Returning...'
            : 'Content added successfully!',
        Colors.green,
      );

      if (_isFromThirdPartyApp()) {
        Future.delayed(const Duration(milliseconds: 1500), _exitScreen);
      } else {
        _exitScreen();
      }
    } catch (e) {
      _showSnackBar('Error adding content: $e', Colors.red);
    } finally {
      setState(() {
        isAddingUrl = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintColor = isDarkMode ? Colors.grey[500] : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.grey[600] : Colors.grey.shade300;
    final focusedBorderColor = isDarkMode
        ? const Color(0xFF7C4DFF)
        : Colors.blue.shade400;
    final secondaryTextColor = isDarkMode
        ? Colors.grey[400]
        : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: _exitScreen,
          icon: Icon(Icons.close, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL Section
            Text(
              'URL *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: urlController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'https://instagram.com/...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: focusedBorderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isAutoGenerating ? null : handleAutoGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF7C4DFF).withOpacity(0.2)
                        : Colors.blue.shade50,
                    foregroundColor: isDarkMode
                        ? const Color(0xFF7C4DFF)
                        : Colors.blue.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isAutoGenerating
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDarkMode
                                ? const Color(0xFF7C4DFF)
                                : Colors.blue.shade600,
                          ),
                        )
                      : const Text(
                          'Auto Generate',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Paste Instagram Reel, Post, YouTube Shorts, or TikTok video URL',
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
            const SizedBox(height: 24),

            // Title Section
            Text(
              'Title *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter content title...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: focusedBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Enter content description...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: focusedBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Collection Section with Create New option
            Text(
              'Collection (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCollection,
                    style: TextStyle(color: textColor),
                    dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                    decoration: InputDecoration(
                      hintText: 'Select a collection...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: focusedBorderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: collections.map((collection) {
                      return DropdownMenuItem<String>(
                        value: collection,
                        child: Text(
                          collection,
                          style: TextStyle(color: textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCollection = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showCreateCollectionDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? const Color(0xFF7C4DFF).withOpacity(0.2)
                        : Colors.green.shade50,
                    foregroundColor: isDarkMode
                        ? const Color(0xFF7C4DFF)
                        : Colors.green.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'New',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tags Section
            Text(
              'Tags (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: tagsController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Add tags separated by commas...',
                hintStyle: TextStyle(color: hintColor),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: focusedBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Tags
            Text(
              'Quick Add:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickTags.map((tag) {
                final isSelected = selectedQuickTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      _removeQuickTag(tag);
                    } else {
                      _addQuickTag(tag);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF7C4DFF)
                          : isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : isDarkMode
                            ? Colors.grey[600]!
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : isDarkMode
                            ? Colors.grey[300]
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _exitScreen,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: borderColor),
                      foregroundColor: textColor,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey[400] : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isAddingUrl ? null : handleSaveContent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: isAddingUrl
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Content',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
