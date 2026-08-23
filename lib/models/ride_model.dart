import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_trail/models/waypoint_model.dart';

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

    this.meetingPoint,
    this.meetingPointLatitude,
    this.meetingPointLongitude,

    this.createdAt,
    this.waypoints,

    this.isCommunityRide = false,
    this.communityRideDocumentId,
    this.communityRideTitle,
  });

  final String documentId;
  final String rideId;

  final String leaderId;
  final String leaderName;

  final String? destination;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final String? meetingPoint;

  final double? meetingPointLatitude;
  final double? meetingPointLongitude;

  final DateTime? createdAt;

  final String status;

  final int memberCount;

  final bool isNavigating;

  final List<WaypointModel>? waypoints;

  final bool isCommunityRide;

  final String? communityRideDocumentId;

  final String? communityRideTitle;

  bool get isActive => status == RideStatus.active;

  bool get hasMeetingPoint =>
      isCommunityRide &&
      meetingPointLatitude != null &&
      meetingPointLongitude != null;

  bool get hasDestination =>
      destinationLatitude != null && destinationLongitude != null;

  factory RideModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final createdAt = data['createdAt'];

    final rawWaypoints = data['waypoints'] as List<dynamic>?;

    return RideModel(
      documentId: document.id,

      rideId: data['rideId'] as String? ?? '',

      leaderId: data['leaderId'] as String? ?? '',

      leaderName: data['leaderName'] as String? ?? 'Unknown rider',

      destination: data['destination'] as String?,

      destinationLatitude: (data['destinationLatitude'] as num?)?.toDouble(),

      destinationLongitude: (data['destinationLongitude'] as num?)?.toDouble(),

      meetingPoint: data['meetingPoint'] as String?,

      meetingPointLatitude: (data['meetingPointLatitude'] as num?)?.toDouble(),

      meetingPointLongitude: (data['meetingPointLongitude'] as num?)
          ?.toDouble(),

      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,

      status: data['status'] as String? ?? RideStatus.active,

      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,

      isNavigating: data['isNavigating'] as bool? ?? false,

      isCommunityRide: data['isCommunityRide'] as bool? ?? false,

      communityRideDocumentId: data['communityRideDocumentId'] as String?,

      communityRideTitle: data['communityRideTitle'] as String?,

      waypoints: rawWaypoints?.map<WaypointModel>((w) {
        if (w is Map<String, dynamic>) {
          return WaypointModel.fromMap(w);
        }

        return WaypointModel(
          id: '',
          title: w.toString(),
          description: '',
          latitude: 0.0,
          longitude: 0.0,
          locationName: w.toString(),
          stopMinutes: 0,
          order: 0,
          category: WaypointCategory.custom,
          completed: false,
          creatorId: '',
          creatorName: '',
          createdAt: DateTime.now(),
        );
      }).toList(),
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

      'meetingPoint': meetingPoint,

      'meetingPointLatitude': meetingPointLatitude,

      'meetingPointLongitude': meetingPointLongitude,

      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),

      'status': status,

      'memberCount': memberCount,

      'isNavigating': isNavigating,

      'waypoints': waypoints?.map((w) => w.toMap()).toList(),

      'isCommunityRide': isCommunityRide,

      'communityRideDocumentId': communityRideDocumentId,

      'communityRideTitle': communityRideTitle,
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

    String? meetingPoint,
    double? meetingPointLatitude,
    double? meetingPointLongitude,

    DateTime? createdAt,
    String? status,
    int? memberCount,
    bool? isNavigating,

    List<WaypointModel>? waypoints,

    bool? isCommunityRide,
    String? communityRideDocumentId,
    String? communityRideTitle,
  }) {
    return RideModel(
      documentId: documentId ?? this.documentId,

      rideId: rideId ?? this.rideId,

      leaderId: leaderId ?? this.leaderId,

      leaderName: leaderName ?? this.leaderName,

      destination: destination ?? this.destination,

      destinationLatitude: destinationLatitude ?? this.destinationLatitude,

      destinationLongitude: destinationLongitude ?? this.destinationLongitude,

      meetingPoint: meetingPoint ?? this.meetingPoint,

      meetingPointLatitude: meetingPointLatitude ?? this.meetingPointLatitude,

      meetingPointLongitude:
          meetingPointLongitude ?? this.meetingPointLongitude,

      createdAt: createdAt ?? this.createdAt,

      status: status ?? this.status,

      memberCount: memberCount ?? this.memberCount,

      isNavigating: isNavigating ?? this.isNavigating,

      waypoints: waypoints ?? this.waypoints,

      isCommunityRide: isCommunityRide ?? this.isCommunityRide,

      communityRideDocumentId:
          communityRideDocumentId ?? this.communityRideDocumentId,

      communityRideTitle: communityRideTitle ?? this.communityRideTitle,
    );
  }
}
