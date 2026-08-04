import 'package:cloud_firestore/cloud_firestore.dart';

class RiderLocationModel {
  const RiderLocationModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.isOnline,
    this.isSOS = false,
    this.photoUrl, // Added photoUrl
    this.latitude,
    this.longitude,
    this.heading,
    this.speed,
    this.locationUpdatedAt,
  });

  final String userId;
  final String displayName;
  final String role; // 'leader' or 'member'
  final String? photoUrl; // Google / User Profile Avatar URL
  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? speed;
  final DateTime? locationUpdatedAt;
  final bool isOnline;
  final bool isSOS;

  bool get hasLocation => latitude != null && longitude != null;

  factory RiderLocationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final updatedAt = data['locationUpdatedAt'];

    return RiderLocationModel(
      userId: data['userId'] as String? ?? document.id,
      displayName: data['displayName'] as String? ?? 'Rider',
      role: data['role'] as String? ?? 'member',
      photoUrl: data['photoUrl'] as String?, // Parsed from Firestore
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      locationUpdatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      isOnline: data['isOnline'] as bool? ?? true,
      isSOS: data['isSOS'] as bool? ?? false,
    );
  }

  factory RiderLocationModel.fromRealtime(
    String userId,
    Map<dynamic, dynamic> data,
  ) {
    final timestamp = data["updatedAt"];

    return RiderLocationModel(
      userId: data["userId"] ?? userId,
      displayName: data["displayName"] ?? "Rider",
      role: data["role"] ?? "member",
      photoUrl: data["photoUrl"] as String?, // Parsed from Realtime DB
      latitude: (data["latitude"] as num?)?.toDouble(),
      longitude: (data["longitude"] as num?)?.toDouble(),
      heading: (data["heading"] as num?)?.toDouble(),
      speed: (data["speed"] as num?)?.toDouble(),
      locationUpdatedAt: timestamp is int
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
      isOnline: data["isOnline"] as bool? ?? true,
      isSOS: data["isSOS"] as bool? ?? false,
    );
  }

  /// Helper to convert model to Map when writing to Firestore/Realtime DB
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'role': role,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'locationUpdatedAt': locationUpdatedAt != null
          ? Timestamp.fromDate(locationUpdatedAt!)
          : null,
      'isOnline': isOnline,
      'isSOS': isSOS,
    };
  }

  RiderLocationModel copyWith({bool? isSOS}) {
    return RiderLocationModel(
      userId: userId,
      displayName: displayName,
      role: role,
      photoUrl: photoUrl,
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speed: speed,
      locationUpdatedAt: locationUpdatedAt,
      isOnline: isOnline,
      isSOS: isSOS ?? this.isSOS,
    );
  }
}
