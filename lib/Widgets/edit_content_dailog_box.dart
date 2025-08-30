import 'package:clipper/models.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditContentDialog extends StatefulWidget {
  final VideoModel video; // Pass the entire video model
  final String userId; // Current user's ID
  final String collectionName; // Collection name

  const EditContentDialog({
    Key? key,
    required this.video,
    required this.userId,
    required this.collectionName,
  }) : super(key: key);

  @override
  State<EditContentDialog> createState() => _EditContentDialogState();
}

class _EditContentDialogState extends State<EditContentDialog> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController platformController;
  late TextEditingController tagsController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.video.name);
    descriptionController = TextEditingController(
      text: widget.video.description,
    );
    platformController = TextEditingController(text: widget.video.platform);
    tagsController = TextEditingController(text: widget.video.tags.join(', '));
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    platformController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Prepare updated data
      final updatedData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'platform': platformController.text.trim(),
        'tags': tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the specific video in the user's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('collections')
          .doc(widget.collectionName)
          .collection('videos')
          .doc(widget.video.id)
          .update(updatedData);

      // Update in SharedPreferences cache
      await updateRecentlyViewedCache(widget.video.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video updated successfully'),
            backgroundColor: Color(0xFF7C4DFF),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateRecentlyViewedCache(
    String videoId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getString('recently_viewed_videos');

      if (recentlyViewedJson != null) {
        List<dynamic> recentlyViewed = json.decode(recentlyViewedJson);

        // Find and update the video in the cache
        for (int i = 0; i < recentlyViewed.length; i++) {
          if (recentlyViewed[i]['id'] == videoId) {
            // Update the cached video data
            recentlyViewed[i] = {
              ...recentlyViewed[i],
              ...updatedData,
              'updatedAt': DateTime.now().toIso8601String(),
            };
            break;
          }
        }

        // Save back to SharedPreferences
        await prefs.setString(
          'recently_viewed_videos',
          json.encode(recentlyViewed),
        );
      }
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Content',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    const Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter video name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Platform
                    const Text(
                      'Platform',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: platformController,
                      decoration: InputDecoration(
                        hintText: 'e.g., YouTube, Vimeo, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tags
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        hintText: 'comedy, entertainment, funny',
                        helperText: 'Separate multiple tags with commas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: isLoading ? null : saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w500),
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
