// import 'package:clipper/models.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class EditContentDialog extends StatefulWidget {
//   final VideoModel video; // Pass the entire video model
//   final String userId; // Current user's ID
//   final String collectionName; // Collection name

//   const EditContentDialog({
//     Key? key,
//     required this.video,
//     required this.userId,
//     required this.collectionName,
//   }) : super(key: key);

//   @override
//   State<EditContentDialog> createState() => _EditContentDialogState();
// }

// class _EditContentDialogState extends State<EditContentDialog> {
//   late TextEditingController nameController;
//   late TextEditingController descriptionController;
//   late TextEditingController platformController;
//   late TextEditingController tagsController;

//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     nameController = TextEditingController(text: widget.video.name);
//     descriptionController = TextEditingController(
//       text: widget.video.description,
//     );
//     platformController = TextEditingController(text: widget.video.platform);
//     tagsController = TextEditingController(text: widget.video.tags.join(', '));
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     descriptionController.dispose();
//     platformController.dispose();
//     tagsController.dispose();
//     super.dispose();
//   }

//   Future<void> saveChanges() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       // Prepare updated data
//       final updatedData = {
//         'name': nameController.text.trim(),
//         'description': descriptionController.text.trim(),
//         'platform': platformController.text.trim(),
//         'tags': tagsController.text
//             .split(',')
//             .map((tag) => tag.trim())
//             .where((tag) => tag.isNotEmpty)
//             .toList(),
//         'updatedAt': FieldValue.serverTimestamp(),
//       };

//       // Update the specific video in the user's collection
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.userId)
//           .collection('collections')
//           .doc(widget.collectionName)
//           .collection('videos')
//           .doc(widget.video.id)
//           .update(updatedData);

//       // Update in SharedPreferences cache
//       await updateRecentlyViewedCache(widget.video.id, updatedData);

//       if (mounted) {
//         Navigator.of(context).pop(true); // Return true to indicate success
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Video updated successfully'),
//             backgroundColor: Color(0xFF7C4DFF),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error updating video: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> updateRecentlyViewedCache(
//     String videoId,
//     Map<String, dynamic> updatedData,
//   ) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final recentlyViewedJson = prefs.getString('recently_viewed_videos');

//       if (recentlyViewedJson != null) {
//         List<dynamic> recentlyViewed = json.decode(recentlyViewedJson);

//         // Find and update the video in the cache
//         for (int i = 0; i < recentlyViewed.length; i++) {
//           if (recentlyViewed[i]['id'] == videoId) {
//             // Update the cached video data
//             recentlyViewed[i] = {
//               ...recentlyViewed[i],
//               ...updatedData,
//               'updatedAt': DateTime.now().toIso8601String(),
//             };
//             break;
//           }
//         }

//         // Save back to SharedPreferences
//         await prefs.setString(
//           'recently_viewed_videos',
//           json.encode(recentlyViewed),
//         );
//       }
//     } catch (e) {
//       print('Error updating cache: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         height: MediaQuery.of(context).size.height * 0.8,
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Edit Content',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   icon: const Icon(Icons.close, color: Colors.grey),
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 24),

//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Name
//                     const Text(
//                       'Name',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter video name',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF7C4DFF),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Platform
//                     const Text(
//                       'Platform',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: platformController,
//                       decoration: InputDecoration(
//                         hintText: 'e.g., YouTube, Vimeo, etc.',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF7C4DFF),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Description
//                     const Text(
//                       'Description',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: descriptionController,
//                       maxLines: 4,
//                       decoration: InputDecoration(
//                         hintText: 'Enter description',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF7C4DFF),
//                           ),
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Tags
//                     const Text(
//                       'Tags',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: tagsController,
//                       decoration: InputDecoration(
//                         hintText: 'comedy, entertainment, funny',
//                         helperText: 'Separate multiple tags with commas',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF7C4DFF),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // Action buttons
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: isLoading
//                       ? null
//                       : () => Navigator.of(context).pop(),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(
//                       color: Colors.grey,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),

//                 ElevatedButton(
//                   onPressed: isLoading ? null : saveChanges,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF7C4DFF),
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 24,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: isLoading
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : const Text(
//                           'Save Changes',
//                           style: TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:clipper/models.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditContentDialog extends StatefulWidget {
  final VideoModel video;
  final String userId;
  final String collectionName; // current collection

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

  List<String> collections = [];
  String? selectedCollection;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.video.name);
    descriptionController = TextEditingController(
      text: widget.video.description,
    );
    platformController = TextEditingController(text: widget.video.platform);
    tagsController = TextEditingController(text: widget.video.tags.join(', '));

    selectedCollection = widget.collectionName;
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('collections')
        .get();

    setState(() {
      collections = snapshot.docs.map((d) => d.id).toList();
    });
  }

  /// 🔹 CREATE NEW COLLECTION
  Future<void> _createNewCollection(String name) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('collections')
        .doc(name)
        .set({'name': name, 'createdAt': FieldValue.serverTimestamp()});

    setState(() {
      collections.add(name);
      selectedCollection = name;
    });
  }

  /// 🔹 DIALOG TO CREATE COLLECTION
  Future<void> _showCreateCollectionDialog() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.create_new_folder_outlined,
                color: Color(0xFF7C4DFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'New Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter collection name',
            prefixIcon: const Icon(Icons.folder_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await _createNewCollection(name);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// 🔹 SAVE CHANGES (MOVE VIDEO IF COLLECTION CHANGED)
  Future<void> saveChanges() async {
    setState(() => isLoading = true);

    try {
      final updatedData = {
        'name': nameController.text.trim(),
        'description': descriptionController.text.trim(),
        'platform': platformController.text.trim(),
        'tags': tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'collection': selectedCollection,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final oldRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('collections')
          .doc(widget.collectionName)
          .collection('videos')
          .doc(widget.video.id);

      final newRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('collections')
          .doc(selectedCollection)
          .collection('videos')
          .doc(widget.video.id);

      if (selectedCollection == widget.collectionName) {
        // Same collection → simple update
        await oldRef.update(updatedData);
      } else {
        // Different collection → MOVE
        // Get the original document data to preserve Timestamp format
        final oldDoc = await oldRef.get();
        if (oldDoc.exists) {
          final originalData = oldDoc.data()!;
          // Merge original data with updates, preserving createdAt as Timestamp
          await newRef.set({
            ...originalData,
            ...updatedData,
            // Keep the original createdAt timestamp
            'createdAt': originalData['createdAt'],
          });
          await oldRef.delete();
        }
      }

      await _updateRecentlyViewedCache(widget.video.id, updatedData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video updated successfully'),
            backgroundColor: Color(0xFF7C4DFF),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateRecentlyViewedCache(
    String videoId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('recently_viewed_videos');
      if (jsonStr == null) return;

      final List list = json.decode(jsonStr);

      // Create a cache-safe copy of updatedData (remove FieldValue types)
      final cacheSafeData = <String, dynamic>{};
      updatedData.forEach((key, value) {
        // Skip FieldValue types as they can't be serialized
        if (value is! FieldValue) {
          cacheSafeData[key] = value;
        }
      });
      // Add updatedAt as milliseconds for cache
      cacheSafeData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < list.length; i++) {
        if (list[i]['id'] == videoId) {
          list[i] = {...list[i], ...cacheSafeData};
          break;
        }
      }
      await prefs.setString('recently_viewed_videos', json.encode(list));
    } catch (e) {
      print('Error updating recently viewed cache: $e');
    }
  }

  InputDecoration _inputDecoration(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 580),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
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
                    // Collection Dropdown
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCollection,
                            decoration: _inputDecoration(
                              'Collection',
                              icon: Icons.folder_outlined,
                            ),
                            items: collections
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedCollection = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF7C4DFF),
                            ),
                            onPressed: _showCreateCollectionDialog,
                            tooltip: 'Create new collection',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        'Title',
                        hint: 'Enter video title',
                        icon: Icons.title,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration(
                        'Description',
                        hint: 'Enter description',
                        icon: Icons.description_outlined,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tags Field
                    TextField(
                      controller: tagsController,
                      decoration: _inputDecoration(
                        'Tags',
                        hint: 'fitness, workout, health',
                        icon: Icons.label_outlined,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 6),
                      child: Text(
                        'Separate tags with commas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_outlined, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
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
  }
}
