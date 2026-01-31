import 'package:clipper/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CollectionCard extends StatelessWidget {
  final CollectionModel collection;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // Callback for when collection is deleted

  const CollectionCard({
    Key? key,
    required this.collection,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Collection',
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
                'Are you sure you want to delete this collection?',
                style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              Text(
                collection.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'This will delete ${collection.itemCount} ${collection.itemCount == 1 ? 'item' : 'items'}.',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteCollection(context);
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

  Future<void> _deleteCollection(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final collectionName = collection.name;

      // Delete the collection document from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionName)
          .delete();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Collection deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Call the onDelete callback to refresh the UI
        onDelete?.call();
      }
    } catch (e) {
      print('Error deleting collection: $e');

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete collection: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = collection.color.computeLuminance() > 0.5;
    final Color textColor = isLight ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showDeleteConfirmation(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              collection.color.withOpacity(0.7),
              collection.color.withOpacity(0.5),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: collection.color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Glassy background blur effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(
                          255,
                          105,
                          104,
                          104,
                        ).withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // Top row: count on left, delete on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item count
                        Text(
                          '${collection.itemCount} ${collection.itemCount == 1 ? 'item' : 'items'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                        // Delete button
                        GestureDetector(
                          onTap: () => _showDeleteConfirmation(context),
                          child: Icon(
                            Icons.delete_outline,
                            color: textColor.withOpacity(0.7),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    // Centered icon
                    Expanded(
                      child: Center(
                        child: Icon(
                          collection.icon,
                          color: textColor,
                          size: 36,
                        ),
                      ),
                    ),
                    // Collection name at bottom center
                    Text(
                      collection.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
