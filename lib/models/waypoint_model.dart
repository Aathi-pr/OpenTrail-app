import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum WaypointCategory { food, fuel, hotel, viewpoint, rest, checkpoint, custom }

class WaypointModel {
  const WaypointModel({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.stopMinutes,
    required this.order,
    required this.category,
    required this.completed,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;

  final double latitude;
  final double longitude;

  final String locationName;

  final int stopMinutes;

  final int order;

  final WaypointCategory category;

  final bool completed;

  final String creatorId;
  final String creatorName;

  final DateTime createdAt;

  LatLng get location => LatLng(latitude, longitude);

  String get categoryLabel {
    switch (category) {
      case WaypointCategory.food:
        return 'Food';

      case WaypointCategory.fuel:
        return 'Fuel';

      case WaypointCategory.hotel:
        return 'Hotel';

      case WaypointCategory.viewpoint:
        return 'Viewpoint';

      case WaypointCategory.rest:
        return 'Rest';

      case WaypointCategory.checkpoint:
        return 'Checkpoint';

      case WaypointCategory.custom:
        return 'Custom';
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case WaypointCategory.food:
        return Icons.restaurant;

      case WaypointCategory.fuel:
        return Icons.local_gas_station;

      case WaypointCategory.hotel:
        return Icons.hotel;

      case WaypointCategory.viewpoint:
        return Icons.camera_alt;

      case WaypointCategory.rest:
        return CupertinoIcons.bed_double_fill;

      case WaypointCategory.checkpoint:
        return Icons.flag;

      case WaypointCategory.custom:
        return Icons.place;
    }
  }

  Color get categoryColor {
    switch (category) {
      case WaypointCategory.food:
        return Colors.orange;

      case WaypointCategory.fuel:
        return Colors.green;

      case WaypointCategory.hotel:
        return Colors.blue;

      case WaypointCategory.viewpoint:
        return Colors.purple;

      case WaypointCategory.rest:
        return Colors.teal;

      case WaypointCategory.checkpoint:
        return Colors.red;

      case WaypointCategory.custom:
        return Colors.white;
    }
  }

  factory WaypointModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final categoryName =
        (data['category'] as String?) ?? (data['type'] as String?) ?? '';

    final createdAt = data['createdAt'];

    DateTime parsedDate;

    if (createdAt is Timestamp) {
      parsedDate = createdAt.toDate();
    } else if (createdAt is String) {
      parsedDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WaypointModel(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),

      title: (data['title'] as String?) ?? (data['name'] as String?) ?? '',

      description: data['description'] as String? ?? '',

      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,

      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,

      locationName: data['locationName'] as String? ?? '',

      stopMinutes: (data['stopMinutes'] as num?)?.toInt() ?? 0,

      order: (data['order'] as num?)?.toInt() ?? 0,

      category: WaypointCategory.values.firstWhere(
        (entry) => entry.name == categoryName,
        orElse: () => WaypointCategory.custom,
      ),

      completed:
          (data['completed'] as bool?) ?? (data['isReached'] as bool?) ?? false,

      creatorId:
          (data['creatorId'] as String?) ??
          (data['createdBy'] as String?) ??
          '',

      creatorName:
          (data['creatorName'] as String?) ??
          (data['createdByName'] as String?) ??
          'Unknown rider',

      createdAt: parsedDate,
    );
  }

  factory WaypointModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return WaypointModel.fromMap(doc.data() ?? <String, dynamic>{}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'stopMinutes': stopMinutes,
      'order': order,
      'category': category.name,
      'completed': completed,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdBy': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  WaypointModel copyWith({
    String? id,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? locationName,
    int? stopMinutes,
    int? order,
    WaypointCategory? category,
    bool? completed,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
  }) {
    return WaypointModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      stopMinutes: stopMinutes ?? this.stopMinutes,
      order: order ?? this.order,
      category: category ?? this.category,
      completed: completed ?? this.completed,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
