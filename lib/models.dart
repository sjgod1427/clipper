// VideoModel class definition
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Predefined icons available for selection
const List<IconData> kSelectableIcons = [
  Icons.bookmark,
  Icons.favorite,
  Icons.star,
  Icons.home,
  Icons.work,
  Icons.school,
  Icons.fitness_center,
  Icons.restaurant,
  Icons.movie,
  Icons.music_note,
  Icons.camera_alt,
  Icons.travel_explore,
  Icons.shopping_bag,
  Icons.sports_soccer,
  Icons.games,
  Icons.palette,
  Icons.book,
  Icons.science,
];

IconData getIconFromCode(int codePoint) {
  for (final icon in kSelectableIcons) {
    if (icon.codePoint == codePoint) {
      return icon;
    }
  }
  return Icons.bookmark;
}

class VideoModel {
  final String id;
  final String name;
  final String platform;
  final String description;
  final List<String> tags;
  final String url;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.description,
    required this.tags,
    required this.url,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'description': description,
      'tags': tags,
      'url': url,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Convert to Firestore-compatible format (uses Timestamp for dates)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'platform': platform,
      'description': description,
      'tags': tags,
      'url': url,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      name: json['name'],
      platform: json['platform'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      url: json['url'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }

  factory VideoModel.fromFirestore(String id, Map<String, dynamic> data) {
    // Handle createdAt which can be Timestamp, int, or null
    DateTime createdAtDate;
    final createdAtValue = data['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAtDate = createdAtValue.toDate();
    } else if (createdAtValue is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else {
      createdAtDate = DateTime.now();
    }

    return VideoModel(
      id: id,
      name: data['name'] ?? '',
      platform: data['platform'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      url: data['url'] ?? '',
      createdAt: createdAtDate,
    );
  }
}

class CollectionModel {
  final String id;
  final String name;
  final int itemCount;
  final Color color;
  final IconData icon;
  final DateTime createdAt;

  CollectionModel({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  // Convert to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemCount': itemCount,
      'color': color.value,
      'icon': icon.codePoint,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON for caching
  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'],
      name: json['name'],
      itemCount: json['itemCount'],
      color: Color(json['color']),
      icon: getIconFromCode(json['icon']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
