// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/material.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   // Google Sign-In Methods
//   Future<User?> signInWithGoogle() async {
//     try {
//       // Trigger the authentication flow
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         // User canceled the sign-in
//         return null;
//       }

//       // Obtain the auth details from the request
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // Create a new credential
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase with the Google credential
//       final UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );
//       final User? user = userCredential.user;

//       if (user != null) {
//         // Create or update user document in Firestore
//         await _createOrUpdateUserDocument(user);
//       }

//       return user;
//     } catch (e) {
//       print("Error signing in with Google: $e");
//       rethrow;
//     }
//   }

//   Future<void> signOut() async {
//     try {
//       await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
//     } catch (e) {
//       print("Error signing out: $e");
//       rethrow;
//     }
//   }

//   Future<void> _createOrUpdateUserDocument(User user) async {
//     try {
//       final userDoc = _db.collection('users').doc(user.uid);
//       final docSnapshot = await userDoc.get();

//       final userData = {
//         'email': user.email,
//         'displayName': user.displayName,
//         'photoURL': user.photoURL,
//         'lastSignIn': FieldValue.serverTimestamp(),
//       };

//       if (!docSnapshot.exists) {
//         // New user - create document with additional fields
//         userData.addAll({
//           'createdAt': FieldValue.serverTimestamp(),
//           'isFirstTime': true,
//         });
//         await userDoc.set(userData);
//       } else {
//         // Existing user - update document
//         await userDoc.update(userData);
//       }
//     } catch (e) {
//       print("Error creating/updating user document: $e");
//       rethrow;
//     }
//   }

//   // Auth state stream
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Get current user
//   User? get currentUser => _auth.currentUser;

//   // Check if user is signed in
//   bool get isSignedIn => _auth.currentUser != null;

//   // Get user data from Firestore
//   Future<DocumentSnapshot?> getUserData(String userId) async {
//     try {
//       return await _db.collection('users').doc(userId).get();
//     } catch (e) {
//       print("Error getting user data: $e");
//       return null;
//     }
//   }

//   // Stream user data
//   Stream<DocumentSnapshot> getUserDataStream(String userId) {
//     return _db.collection('users').doc(userId).snapshots();
//   }

//   Future<void> createCollection(
//     String userId,
//     String name,
//     Color selectedColor,
//     IconData selectedIcon,
//   ) async {
//     try {
//       print("Creating collection: $name for user: $userId");

//       await _db
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .doc(name)
//           .set({
//             'name': name,
//             'createdAt': FieldValue.serverTimestamp(),
//             // Convert IconData to int (codePoint) for storage
//             'selectedIcon': selectedIcon.codePoint,
//             // Convert Color to hex string for storage
//             'selectedColor': selectedColor.value,
//           });

//       print("Collection created successfully!");
//     } catch (e) {
//       print("Error creating collection: $e");
//       rethrow; // Re-throw so the UI can handle the error
//     }
//   }

//   Future<String?> findVideoCollection({
//     required String userId,
//     required String videoId,
//   }) async {
//     try {
//       // Get all collections for the user
//       final collectionsSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .get();

//       // Search through each collection for the video
//       for (final collectionDoc in collectionsSnapshot.docs) {
//         final collectionName = collectionDoc.id;

//         // Check if the video exists in this collection
//         final videoDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userId)
//             .collection('collections')
//             .doc(collectionName)
//             .collection('videos')
//             .doc(videoId)
//             .get();

//         if (videoDoc.exists) {
//           return collectionName;
//         }
//       }

//       // Video not found in any collection
//       return null;
//     } catch (e) {
//       print('Error finding video collection: $e');
//       return null;
//     }
//   }

//   /// Alternative optimized version using batch queries
//   /// This version queries all collections simultaneously for better performance
//   Future<String?> findVideoCollectionOptimized({
//     required String userId,
//     required String videoId,
//   }) async {
//     try {
//       // Get all collections for the user
//       final collectionsSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .get();

//       // Create a list of futures to check all collections simultaneously
//       final List<Future<DocumentSnapshot>> videoCheckFutures = [];
//       final List<String> collectionNames = [];

//       for (final collectionDoc in collectionsSnapshot.docs) {
//         final collectionName = collectionDoc.id;
//         collectionNames.add(collectionName);

//         videoCheckFutures.add(
//           FirebaseFirestore.instance
//               .collection('users')
//               .doc(userId)
//               .collection('collections')
//               .doc(collectionName)
//               .collection('videos')
//               .doc(videoId)
//               .get(),
//         );
//       }

//       // Wait for all queries to complete
//       final results = await Future.wait(videoCheckFutures);

//       // Find which collection has the video
//       for (int i = 0; i < results.length; i++) {
//         if (results[i].exists) {
//           return collectionNames[i];
//         }
//       }

//       // Video not found in any collection
//       return null;
//     } catch (e) {
//       print('Error finding video collection: $e');
//       return null;
//     }
//   }

//   Stream<QuerySnapshot> getCollections(String userId) {
//     return _db
//         .collection('users')
//         .doc(userId)
//         .collection('collections')
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   Future<void> addVideo(
//     String userId,
//     String collectionId,
//     Map<String, dynamic> videoData,
//   ) async {
//     try {
//       await _db
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .doc(collectionId)
//           .collection('videos')
//           .add(videoData);
//     } catch (e) {
//       print("Error adding video: $e");
//       rethrow;
//     }
//   }

//   Stream<QuerySnapshot> getVideos(String userId, String collectionId) {
//     return _db
//         .collection('users')
//         .doc(userId)
//         .collection('collections')
//         .doc(collectionId)
//         .collection('videos')
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Delete collection
//   Future<void> deleteCollection(String userId, String collectionId) async {
//     try {
//       // First delete all videos in the collection
//       final videosSnapshot = await _db
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .doc(collectionId)
//           .collection('videos')
//           .get();

//       final batch = _db.batch();

//       for (final videoDoc in videosSnapshot.docs) {
//         batch.delete(videoDoc.reference);
//       }

//       // Then delete the collection document
//       batch.delete(
//         _db
//             .collection('users')
//             .doc(userId)
//             .collection('collections')
//             .doc(collectionId),
//       );

//       await batch.commit();
//     } catch (e) {
//       print("Error deleting collection: $e");
//       rethrow;
//     }
//   }

//   // Delete video
//   Future<void> deleteVideo(
//     String userId,
//     String collectionId,
//     String videoId,
//   ) async {
//     try {
//       await _db
//           .collection('users')
//           .doc(userId)
//           .collection('collections')
//           .doc(collectionId)
//           .collection('videos')
//           .doc(videoId)
//           .delete();
//     } catch (e) {
//       print("Error deleting video: $e");
//       rethrow;
//     }
//   }

//   // Update user profile
//   Future<void> updateUserProfile({
//     required String userId,
//     String? displayName,
//     String? photoURL,
//     Map<String, dynamic>? additionalData,
//   }) async {
//     try {
//       final updateData = <String, dynamic>{
//         'lastUpdated': FieldValue.serverTimestamp(),
//       };

//       if (displayName != null) updateData['displayName'] = displayName;
//       if (photoURL != null) updateData['photoURL'] = photoURL;
//       if (additionalData != null) updateData.addAll(additionalData);

//       await _db.collection('users').doc(userId).update(updateData);
//     } catch (e) {
//       print("Error updating user profile: $e");
//       rethrow;
//     }
//   }

//   // Helper method to convert stored data back to Color
//   Color getColorFromValue(int colorValue) {
//     return Color(colorValue);
//   }

//   // Helper method to convert stored data back to IconData
//   IconData getIconFromCodePoint(int codePoint) {
//     return IconData(codePoint, fontFamily: 'MaterialIcons');
//   }

//   // Check if this is user's first time
//   Future<bool> isFirstTimeUser(String userId) async {
//     try {
//       final userDoc = await _db.collection('users').doc(userId).get();
//       if (userDoc.exists) {
//         return userDoc.data()?['isFirstTime'] ?? false;
//       }
//       return true;
//     } catch (e) {
//       print("Error checking first time user: $e");
//       return false;
//     }
//   }

//   // Mark user as not first time anymore
//   Future<void> markUserAsReturning(String userId) async {
//     try {
//       await _db.collection('users').doc(userId).update({
//         'isFirstTime': false,
//         'onboardingCompleted': FieldValue.serverTimestamp(),
//       });
//     } catch (e) {
//       print("Error marking user as returning: $e");
//       rethrow;
//     }
//   }
// }

import 'package:clipper/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In Methods
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // Create or update user document in Firestore
        await _createOrUpdateUserDocument(user);
      }

      return user;
    } catch (e) {
      print("Error signing in with Google: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      print("Error signing out: $e");
      rethrow;
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      final userDoc = _db.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      final userData = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSignIn': FieldValue.serverTimestamp(),
      };

      if (!docSnapshot.exists) {
        // New user - create document with additional fields
        userData.addAll({
          'createdAt': FieldValue.serverTimestamp(),
          'isFirstTime': true,
        });
        await userDoc.set(userData);
      } else {
        // Existing user - update document
        await userDoc.update(userData);
      }
    } catch (e) {
      print("Error creating/updating user document: $e");
      rethrow;
    }
  }

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get user data from Firestore
  Future<DocumentSnapshot?> getUserData(String userId) async {
    try {
      return await _db.collection('users').doc(userId).get();
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Stream user data
  Stream<DocumentSnapshot> getUserDataStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<void> createCollection(
    String userId,
    String name,
    Color selectedColor,
    IconData selectedIcon,
  ) async {
    try {
      print("Creating collection: $name for user: $userId");

      await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(name)
          .set({
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
            // Convert IconData to int (codePoint) for storage
            'selectedIcon': selectedIcon.codePoint,
            // Convert Color to hex string for storage
            'selectedColor': selectedColor.value,
          });

      print("Collection created successfully!");
    } catch (e) {
      print("Error creating collection: $e");
      rethrow; // Re-throw so the UI can handle the error
    }
  }

  Future<String?> findVideoCollection({
    required String userId,
    required String videoId,
  }) async {
    try {
      // Get all collections for the user
      final collectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .get();

      // Search through each collection for the video
      for (final collectionDoc in collectionsSnapshot.docs) {
        final collectionName = collectionDoc.id;

        // Check if the video exists in this collection
        final videoDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('collections')
            .doc(collectionName)
            .collection('videos')
            .doc(videoId)
            .get();

        if (videoDoc.exists) {
          return collectionName;
        }
      }

      // Video not found in any collection
      return null;
    } catch (e) {
      print('Error finding video collection: $e');
      return null;
    }
  }

  /// Alternative optimized version using batch queries
  /// This version queries all collections simultaneously for better performance
  Future<String?> findVideoCollectionOptimized({
    required String userId,
    required String videoId,
  }) async {
    try {
      // Get all collections for the user
      final collectionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('collections')
          .get();

      // Create a list of futures to check all collections simultaneously
      final List<Future<DocumentSnapshot>> videoCheckFutures = [];
      final List<String> collectionNames = [];

      for (final collectionDoc in collectionsSnapshot.docs) {
        final collectionName = collectionDoc.id;
        collectionNames.add(collectionName);

        videoCheckFutures.add(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('collections')
              .doc(collectionName)
              .collection('videos')
              .doc(videoId)
              .get(),
        );
      }

      // Wait for all queries to complete
      final results = await Future.wait(videoCheckFutures);

      // Find which collection has the video
      for (int i = 0; i < results.length; i++) {
        if (results[i].exists) {
          return collectionNames[i];
        }
      }

      // Video not found in any collection
      return null;
    } catch (e) {
      print('Error finding video collection: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> getCollections(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('collections')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addVideo(
    String userId,
    String collectionId,
    Map<String, dynamic> videoData,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionId)
          .collection('videos')
          .add(videoData);
    } catch (e) {
      print("Error adding video: $e");
      rethrow;
    }
  }

  Stream<QuerySnapshot> getVideos(String userId, String collectionId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('collections')
        .doc(collectionId)
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete collection
  Future<void> deleteCollection(String userId, String collectionId) async {
    try {
      // First delete all videos in the collection
      final videosSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionId)
          .collection('videos')
          .get();

      final batch = _db.batch();

      for (final videoDoc in videosSnapshot.docs) {
        batch.delete(videoDoc.reference);
      }

      // Then delete the collection document
      batch.delete(
        _db
            .collection('users')
            .doc(userId)
            .collection('collections')
            .doc(collectionId),
      );

      await batch.commit();
    } catch (e) {
      print("Error deleting collection: $e");
      rethrow;
    }
  }

  // Delete video - Updated to support both positional and named parameters
  Future<void> deleteVideo({
    required String userId,
    required String collectionName,
    required String videoId,
  }) async {
    try {
      print("Deleting video: $videoId from collection: $collectionName");

      await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionName)
          .collection('videos')
          .doc(videoId)
          .delete();

      print("Video deleted successfully!");
    } catch (e) {
      print("Error deleting video: $e");
      rethrow;
    }
  }

  // Update video
  Future<void> updateVideo({
    required String userId,
    required String collectionName,
    required String videoId,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      print("Updating video: $videoId in collection: $collectionName");

      // Add lastUpdated timestamp
      updateData['lastUpdated'] = FieldValue.serverTimestamp();

      await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionName)
          .collection('videos')
          .doc(videoId)
          .update(updateData);

      print("Video updated successfully!");
    } catch (e) {
      print("Error updating video: $e");
      rethrow;
    }
  }

  // Get single video
  Future<DocumentSnapshot?> getVideo({
    required String userId,
    required String collectionName,
    required String videoId,
  }) async {
    try {
      return await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .doc(collectionName)
          .collection('videos')
          .doc(videoId)
          .get();
    } catch (e) {
      print("Error getting video: $e");
      return null;
    }
  }

  // Get all videos across all collections for a user (for recent videos)
  Future<List<Map<String, dynamic>>> getAllUserVideos({
    required String userId,
    int? limit,
  }) async {
    try {
      final List<Map<String, dynamic>> allVideos = [];

      // Get all collections for the user
      final collectionsSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('collections')
          .get();

      // Get videos from each collection
      for (final collectionDoc in collectionsSnapshot.docs) {
        final collectionName = collectionDoc.id;

        var videosQuery = _db
            .collection('users')
            .doc(userId)
            .collection('collections')
            .doc(collectionName)
            .collection('videos')
            .orderBy('createdAt', descending: true);

        final videosSnapshot = await videosQuery.get();

        for (final videoDoc in videosSnapshot.docs) {
          allVideos.add({
            ...videoDoc.data(),
            'id': videoDoc.id,
            'collectionName': collectionName,
          });
        }
      }

      // Sort all videos by createdAt
      allVideos.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Apply limit if specified
      if (limit != null && allVideos.length > limit) {
        return allVideos.sublist(0, limit);
      }

      return allVideos;
    } catch (e) {
      print("Error getting all user videos: $e");
      return [];
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (additionalData != null) updateData.addAll(additionalData);

      await _db.collection('users').doc(userId).update(updateData);
    } catch (e) {
      print("Error updating user profile: $e");
      rethrow;
    }
  }

  // Helper method to convert stored data back to Color
  Color getColorFromValue(int colorValue) {
    return Color(colorValue);
  }

  // Helper method to convert stored data back to IconData
  IconData getIconFromCodePoint(int codePoint) {
    return getIconFromCode(codePoint);
  }

  // Check if this is user's first time
  Future<bool> isFirstTimeUser(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data()?['isFirstTime'] ?? false;
      }
      return true;
    } catch (e) {
      print("Error checking first time user: $e");
      return false;
    }
  }

  // Mark user as not first time anymore
  Future<void> markUserAsReturning(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isFirstTime': false,
        'onboardingCompleted': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error marking user as returning: $e");
      rethrow;
    }
  }
}
