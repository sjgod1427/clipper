import 'dart:convert';
import 'dart:ui';

import 'package:clipper/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static String userId = FirebaseAuth.instance.currentUser!.uid;

  static Future<List<CollectionModel>> getLatestCollections() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .orderBy('createdAt', descending: true)
          .get();

      List<CollectionModel> collections = [];

      // Default fallback values
      final defaultColors = [
        const Color(0xFF4285F4), // Blue
        const Color(0xFF34A853), // Green
        const Color(0xFF9C27B0), // Purple
        const Color(0xFFEA4335), // Red
      ];

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final data = doc.data();
        final videosSnapshot = await doc.reference.collection('videos').get();

        // Extract stored color and icon from Firebase
        Color collectionColor;
        IconData collectionIcon;

        try {
          // Get color from stored value
          final storedColor = data['selectedColor'];
          if (storedColor != null && storedColor is int) {
            collectionColor = Color(storedColor);
          } else {
            // Fallback to default color
            collectionColor = defaultColors[i % defaultColors.length];
          }

          // Get icon from stored value
          final storedIcon = data['selectedIcon'];
          if (storedIcon != null && storedIcon is int) {
            collectionIcon = IconData(storedIcon, fontFamily: 'MaterialIcons');
          } else {
            // Fallback to default icon
            collectionIcon = Icons.bookmark;
          }
        } catch (e) {
          print('Error parsing color/icon for collection ${doc.id}: $e');
          collectionColor = defaultColors[i % defaultColors.length];
          collectionIcon = Icons.bookmark;
        }

        collections.add(
          CollectionModel(
            id: doc.id,
            name: data['name'] ?? doc.id,
            itemCount: videosSnapshot.docs.length,
            color: collectionColor,
            icon: collectionIcon,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }

      return collections;
    } catch (e) {
      print('Error fetching collections: $e');
      return [];
    }
  }

  // Get all collections (not just latest 4)
  static Future<List<CollectionModel>> getAllCollections() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .orderBy('createdAt', descending: true)
          .get();

      List<CollectionModel> collections = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final videosSnapshot = await doc.reference.collection('videos').get();

        // Extract stored color and icon from Firebase
        Color collectionColor;
        IconData collectionIcon;

        try {
          // Get color from stored value
          final storedColor = data['selectedColor'];
          if (storedColor != null && storedColor is int) {
            collectionColor = Color(storedColor);
          } else {
            collectionColor = const Color(0xFF4285F4); // Default blue
          }

          // Get icon from stored value
          final storedIcon = data['selectedIcon'];
          if (storedIcon != null && storedIcon is int) {
            collectionIcon = IconData(storedIcon, fontFamily: 'MaterialIcons');
          } else {
            collectionIcon = Icons.bookmark; // Default icon
          }
        } catch (e) {
          print('Error parsing color/icon for collection ${doc.id}: $e');
          collectionColor = const Color(0xFF4285F4);
          collectionIcon = Icons.bookmark;
        }

        collections.add(
          CollectionModel(
            id: doc.id,
            name: data['name'] ?? doc.id,
            itemCount: videosSnapshot.docs.length,
            color: collectionColor,
            icon: collectionIcon,
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ),
        );
      }

      return collections;
    } catch (e) {
      print('Error fetching all collections: $e');
      return [];
    }
  }

  // Stream for real-time collection updates
  static Stream<List<CollectionModel>> getCollectionsStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('collections')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<CollectionModel> collections = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final videosSnapshot = await doc.reference
                .collection('videos')
                .get();

            // Extract stored color and icon from Firebase
            Color collectionColor;
            IconData collectionIcon;

            try {
              // Get color from stored value
              final storedColor = data['selectedColor'];
              if (storedColor != null && storedColor is int) {
                collectionColor = Color(storedColor);
              } else {
                collectionColor = const Color(0xFF4285F4); // Default blue
              }

              // Get icon from stored value
              final storedIcon = data['selectedIcon'];
              if (storedIcon != null && storedIcon is int) {
                collectionIcon = IconData(
                  storedIcon,
                  fontFamily: 'MaterialIcons',
                );
              } else {
                collectionIcon = Icons.bookmark; // Default icon
              }
            } catch (e) {
              print('Error parsing color/icon for collection ${doc.id}: $e');
              collectionColor = const Color(0xFF4285F4);
              collectionIcon = Icons.bookmark;
            }

            collections.add(
              CollectionModel(
                id: doc.id,
                name: data['name'] ?? doc.id,
                itemCount: videosSnapshot.docs.length,
                color: collectionColor,
                icon: collectionIcon,
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              ),
            );
          }

          return collections;
        });
  }

  // Fetch most recent videos from all collections
  static Future<List<VideoModel>> getRecentVideosFromFirebase() async {
    try {
      List<VideoModel> allVideos = [];

      // Get all collections first
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
          final data = videoDoc.data();
          allVideos.add(
            VideoModel(
              id: videoDoc.id,
              name: data['name'] ?? '',
              platform: data['platform'] ?? '',
              description: data['description'] ?? '',
              tags: List<String>.from(data['tags'] ?? []),
              url: data['url'] ?? '',
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
          );
        }
      }

      // Sort all videos by creation date and return top 5
      allVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allVideos.take(5).toList();
    } catch (e) {
      print('Error fetching recent videos from Firebase: $e');
      return [];
    }
  }

  // Listen to real-time updates for new videos
  static Stream<List<VideoModel>> listenToRecentVideos() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('collections')
        .snapshots()
        .asyncMap((collectionsSnapshot) async {
          List<VideoModel> allVideos = [];

          for (final collectionDoc in collectionsSnapshot.docs) {
            final videosSnapshot = await collectionDoc.reference
                .collection('videos')
                .orderBy('createdAt', descending: true)
                .get();

            for (final videoDoc in videosSnapshot.docs) {
              final data = videoDoc.data();
              allVideos.add(
                VideoModel(
                  id: videoDoc.id,
                  name: data['name'] ?? '',
                  platform: data['platform'] ?? '',
                  description: data['description'] ?? '',
                  tags: List<String>.from(data['tags'] ?? []),
                  url: data['url'] ?? '',
                  createdAt:
                      (data['createdAt'] as Timestamp?)?.toDate() ??
                      DateTime.now(),
                ),
              );
            }
          }

          // Sort by creation date and return top 5
          allVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allVideos.take(5).toList();
        });
  }
}

class CacheService {
  static const String recentlyViewedKey = 'recently_viewed_videos';
  static const String collectionsKey = 'cached_collections';
  static const String lastSyncKey = 'last_sync_timestamp';

  // Cache collections
  static Future<void> cacheCollections(
    List<CollectionModel> collections,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = collections
        .map((collection) => json.encode(collection.toJson()))
        .toList();
    await prefs.setStringList(collectionsKey, collectionsJson);
  }

  // Get cached collections
  static Future<List<CollectionModel>> getCachedCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getStringList(collectionsKey) ?? [];

    return collectionsJson.map((item) {
      final collectionData = json.decode(item);
      return CollectionModel.fromJson(collectionData);
    }).toList();
  }

  // Update cache with Firebase data
  static Future<void> syncRecentVideosFromFirebase() async {
    try {
      final firebaseVideos =
          await FirebaseService.getRecentVideosFromFirebase();
      await updateCacheWithFirebaseData(firebaseVideos);

      // Update last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error syncing recent videos from Firebase: $e');
    }
  }

  // Private method to update cache with Firebase data
  static Future<void> updateCacheWithFirebaseData(
    List<VideoModel> firebaseVideos,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVideosJson = firebaseVideos
        .map((video) => json.encode(video.toJson()))
        .toList();
    await prefs.setStringList(recentlyViewedKey, cachedVideosJson);
  }

  // Add a new video to recently viewed (called when user opens a video)
  static Future<void> addRecentlyViewed(VideoModel video) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentVideos = prefs.getStringList(recentlyViewedKey) ?? [];

    // Remove if already exists to avoid duplicates
    recentVideos.removeWhere((item) {
      final videoData = json.decode(item);
      return videoData['id'] == video.id;
    });

    // Add to beginning
    recentVideos.insert(0, json.encode(video.toJson()));

    // Keep only last 5
    if (recentVideos.length > 5) {
      recentVideos = recentVideos.take(5).toList();
    }

    await prefs.setStringList(recentlyViewedKey, recentVideos);
  }

  // Get recently viewed videos from cache
  static Future<List<VideoModel>> getRecentlyViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final recentVideos = prefs.getStringList(recentlyViewedKey) ?? [];

    return recentVideos.map((item) {
      final videoData = json.decode(item);
      return VideoModel.fromJson(videoData);
    }).toList();
  }

  // Check if we need to sync from Firebase (every 5 minutes)
  static Future<bool> shouldSyncFromFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fiveMinutes = 5 * 60 * 1000; // 5 minutes in milliseconds

    return (now - lastSync) > fiveMinutes;
  }

  // Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(lastSyncKey);
    return lastSync != null
        ? DateTime.fromMillisecondsSinceEpoch(lastSync)
        : null;
  }
}
