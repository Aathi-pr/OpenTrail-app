import 'package:cloud_firestore/cloud_firestore.dart';

class RideStatus {
  static const active = 'active';
  static const ended = 'ended';
}

class RideModel {
  const RideModel({
    required this.documentId,
    required this.rideId,
    required this.leaderId,
    required this.leaderName,
    required this.status,
    required this.memberCount,
    required this.isNavigating,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.createdAt,
  });

  final String documentId;
  final String rideId;
  final String leaderId;
  final String leaderName;

  final String? destination;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final DateTime? createdAt;
  final String status;
  final int memberCount;

  /// True when the leader has started navigation.
  final bool isNavigating;

  bool get isActive => status == RideStatus.active;

  factory RideModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];

    return RideModel(
      documentId: document.id,
      rideId: data['rideId'] as String? ?? '',
      leaderId: data['leaderId'] as String? ?? '',
      leaderName: data['leaderName'] as String? ?? 'Unknown rider',
      destination: data['destination'] as String?,
      destinationLatitude: (data['destinationLatitude'] as num?)?.toDouble(),
      destinationLongitude: (data['destinationLongitude'] as num?)?.toDouble(),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      status: data['status'] as String? ?? RideStatus.active,
      memberCount: data['memberCount'] as int? ?? 0,
      isNavigating: data['isNavigating'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'destination': destination,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'status': status,
      'memberCount': memberCount,
      'isNavigating': isNavigating,
    };
  }

  RideModel copyWith({
    String? documentId,
    String? rideId,
    String? leaderId,
    String? leaderName,
    String? destination,
    double? destinationLatitude,
    double? destinationLongitude,
    DateTime? createdAt,
    String? status,
    int? memberCount,
    bool? isNavigating,
  }) {
    return RideModel(
      documentId: documentId ?? this.documentId,
      rideId: rideId ?? this.rideId,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      destination: destination ?? this.destination,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      isNavigating: isNavigating ?? this.isNavigating,
    );
  }
}
