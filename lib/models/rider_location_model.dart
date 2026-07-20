import 'package:cloud_firestore/cloud_firestore.dart';

class RiderLocationModel {
  const RiderLocationModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.heading,
    this.speed,
    this.locationUpdatedAt,
  });

  final String userId;
  final String displayName;
  final String role; // 'leader' or 'member'
  final double? latitude;
  final double? longitude;
  final double? heading;
  final double? speed;
  final DateTime? locationUpdatedAt;
  final bool isOnline;

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
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      locationUpdatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      isOnline: data['isOnline'] as bool? ?? true,
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
      latitude: (data["latitude"] as num?)?.toDouble(),
      longitude: (data["longitude"] as num?)?.toDouble(),
      heading: (data["heading"] as num?)?.toDouble(),
      speed: (data["speed"] as num?)?.toDouble(),
      locationUpdatedAt: timestamp is int
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
          isOnline: data["isOnline"] ?? true,
    );
  }
}
