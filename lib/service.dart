import 'dart:ui';

import 'package:clipper/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static String get userId => FirebaseAuth.instance.currentUser!.uid;

  // Cache Firestore instance
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache collection reference
  static CollectionReference get _userCollectionsRef =>
      _firestore.collection('users').doc(userId).collection('collections');

  // Default fallback values
  static const defaultColors = [
    Color(0xFF4285F4), // Blue
    Color(0xFF34A853), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFFEA4335), // Red
  ];

  // Helper method to parse collection data
  static CollectionModel _parseCollection(
    DocumentSnapshot doc,
    int videosCount,
    int colorIndex,
  ) {
    final data = doc.data() as Map<String, dynamic>?;

    Color collectionColor;
    IconData collectionIcon;

    try {
      final storedColor = data?['selectedColor'];
      collectionColor = storedColor != null && storedColor is int
          ? Color(storedColor)
          : defaultColors[colorIndex % defaultColors.length];

      final storedIcon = data?['selectedIcon'];
      collectionIcon = storedIcon != null && storedIcon is int
          ? IconData(storedIcon, fontFamily: 'MaterialIcons')
          : Icons.bookmark;
    } catch (e) {
      print('Error parsing color/icon for collection ${doc.id}: $e');
      collectionColor = defaultColors[colorIndex % defaultColors.length];
      collectionIcon = Icons.bookmark;
    }

    return CollectionModel(
      id: doc.id,
      name: data?['name'] ?? doc.id,
      itemCount: videosCount,
      color: collectionColor,
      icon: collectionIcon,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Get latest collections (optimized with limit)
  static Future<List<CollectionModel>> getLatestCollections({
    int limit = 4,
  }) async {
    try {
      final querySnapshot = await _userCollectionsRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<CollectionModel> collections = [];

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final videosSnapshot = await doc.reference.collection('videos').get();

        collections.add(_parseCollection(doc, videosSnapshot.docs.length, i));
      }

      return collections;
    } catch (e) {
      print('Error fetching collections: $e');
      return [];
    }
  }

  // Get all collections
  static Future<List<CollectionModel>> getAllCollections() async {
    try {
      final querySnapshot = await _userCollectionsRef
          .orderBy('createdAt', descending: true)
          .get();

      List<CollectionModel> collections = [];

      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        final videosSnapshot = await doc.reference.collection('videos').get();

        collections.add(_parseCollection(doc, videosSnapshot.docs.length, i));
      }

      return collections;
    } catch (e) {
      print('Error fetching all collections: $e');
      return [];
    }
  }

  // Stream for real-time collection updates (optimized)
  static Stream<List<CollectionModel>> getCollectionsStream({int? limit}) {
    Query query = _userCollectionsRef.orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().asyncMap((snapshot) async {
      List<CollectionModel> collections = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final videosSnapshot = await doc.reference.collection('videos').get();

        collections.add(_parseCollection(doc, videosSnapshot.docs.length, i));
      }

      return collections;
    });
  }

  // Helper method to parse video data
  static VideoModel _parseVideo(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return VideoModel(
      id: doc.id,
      name: data?['name'] ?? '',
      platform: data?['platform'] ?? '',
      description: data?['description'] ?? '',
      tags: List<String>.from(data?['tags'] ?? []),
      url: data?['url'] ?? '',
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // OPTIMIZED: Fetch most recent videos - simplified approach
  static Future<List<VideoModel>> getRecentVideos({int limit = 5}) async {
    try {
      List<VideoModel> allVideos = [];

      // Get all collections
      final collectionsSnapshot = await _userCollectionsRef.get();

      // Fetch all videos from all collections
      for (final collectionDoc in collectionsSnapshot.docs) {
        final videosSnapshot = await collectionDoc.reference
            .collection('videos')
            .get();

        allVideos.addAll(videosSnapshot.docs.map(_parseVideo));
      }

      // Sort by creation date and return latest 5
      allVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allVideos.take(limit).toList();
    } catch (e) {
      print('Error fetching recent videos: $e');
      return [];
    }
  }

  // OPTIMIZED: Real-time stream for recent videos
  static Stream<List<VideoModel>> getRecentVideosStream({int limit = 5}) {
    return _userCollectionsRef.snapshots().asyncMap((
      collectionsSnapshot,
    ) async {
      List<VideoModel> allVideos = [];

      // Fetch all videos from all collections
      for (final collectionDoc in collectionsSnapshot.docs) {
        final videosSnapshot = await collectionDoc.reference
            .collection('videos')
            .get();

        allVideos.addAll(videosSnapshot.docs.map(_parseVideo));
      }

      // Sort by creation date and return latest videos
      allVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allVideos.take(limit).toList();
    });
  }

  // Get videos for a specific collection
  static Future<List<VideoModel>> getCollectionVideos(
    String collectionId,
  ) async {
    try {
      final videosSnapshot = await _userCollectionsRef
          .doc(collectionId)
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .get();

      return videosSnapshot.docs.map(_parseVideo).toList();
    } catch (e) {
      print('Error fetching collection videos: $e');
      return [];
    }
  }

  // Stream for collection videos
  static Stream<List<VideoModel>> getCollectionVideosStream(
    String collectionId,
  ) {
    return _userCollectionsRef
        .doc(collectionId)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_parseVideo).toList());
  }
}
