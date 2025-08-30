// VideoModel class definition
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    return VideoModel(
      id: id,
      name: data['name'] ?? '',
      platform: data['platform'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      url: data['url'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
