import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_trail/models/waypoint_model.dart';

class CommunityRide {
  const CommunityRide({
    required this.documentId,
    required this.rideId,

    required this.title,
    required this.description,

    required this.destination,
    this.destinationLatitude,
    this.destinationLongitude,

    required this.meetingPoint,
    this.meetingPointLatitude,
    this.meetingPointLongitude,

    this.waypoints = const [],

    required this.leaderUid,
    required this.leaderName,
    this.leaderPhotoUrl,

    required this.departureTime,
    this.returnTime,
    required this.createdAt,
    required this.category,
    required this.visibility,
    required this.status,
    required this.maxMembers,

    required this.members,
    this.memberDetails = const {},

    required this.joinRequests,
    this.joinRequestDetails = const {},

    this.estimatedDistanceKm,
    this.estimatedDurationMinutes,

    this.difficulty,
    this.terrain,
    this.isRoundTrip = false,

    this.vehicleType = 'Motorcycle',
    this.vehicleRequirement = '',

    this.fuelCost = 0,
    this.tollCost = 0,
    this.parkingCost = 0,
    this.accommodationCost = 0,
    this.otherCost = 0,

    this.helmetRequired = true,
    this.licenceRequired = true,

    this.additionalInstructions = '',

    this.isFeatured = false,
    this.operationalRideDocumentId,
  });

  final String documentId;
  final String rideId;

  final String title;
  final String description;

  final String destination;
  final double? destinationLatitude;
  final double? destinationLongitude;

  final String meetingPoint;
  final double? meetingPointLatitude;
  final double? meetingPointLongitude;

  final List<WaypointModel> waypoints;

  final String leaderUid;
  final String leaderName;
  final String? leaderPhotoUrl;

  final DateTime departureTime;
  final DateTime? returnTime;
  final DateTime createdAt;

  final String category;
  final String visibility;
  final String status;

  final int maxMembers;

  final List<String> members;

  final Map<String, MemberDetails> memberDetails;

  final List<String> joinRequests;

  final Map<String, JoinRequestDetails> joinRequestDetails;

  final double? estimatedDistanceKm;

  final int? estimatedDurationMinutes;

  final String? difficulty;
  final String? terrain;

  final bool isRoundTrip;

  final String vehicleType;

  final String vehicleRequirement;

  final double fuelCost;
  final double tollCost;
  final double parkingCost;
  final double accommodationCost;
  final double otherCost;

  final bool helmetRequired;

  final bool licenceRequired;

  final String additionalInstructions;

  final bool isFeatured;

  final String? operationalRideDocumentId;

  bool get isFull {
    return members.length >= maxMembers;
  }

  bool hasMember(String uid) {
    return members.contains(uid);
  }

  bool hasJoinRequest(String uid) {
    return joinRequests.contains(uid);
  }

  MemberDetails? memberDetailsFor(String uid) {
    return memberDetails[uid];
  }

  JoinRequestDetails? requestDetailsFor(String uid) {
    return joinRequestDetails[uid];
  }

  bool get hasDestination {
    return destination.trim().isNotEmpty &&
        destinationLatitude != null &&
        destinationLongitude != null;
  }

  bool get hasDestinationCoordinates {
    return destinationLatitude != null && destinationLongitude != null;
  }

  bool get hasMeetingPoint {
    return meetingPoint.trim().isNotEmpty &&
        meetingPointLatitude != null &&
        meetingPointLongitude != null;
  }

  bool get hasMeetingPointCoordinates {
    return meetingPointLatitude != null && meetingPointLongitude != null;
  }

  double? get routeDistanceKm {
    return estimatedDistanceKm;
  }

  int? get routeDurationMinutes {
    return estimatedDurationMinutes;
  }

  bool get hasCalculatedRoute {
    return estimatedDistanceKm != null &&
        estimatedDistanceKm! > 0 &&
        estimatedDurationMinutes != null &&
        estimatedDurationMinutes! > 0;
  }

  double get totalEstimatedCost {
    return fuelCost + tollCost + parkingCost + accommodationCost + otherCost;
  }

  double get estimatedCost {
    return totalEstimatedCost;
  }

  double get estimatedCostPerMember {
    if (members.isEmpty) {
      return totalEstimatedCost;
    }

    return totalEstimatedCost / members.length;
  }

  double get estimatedCostPerMaximumRider {
    if (maxMembers <= 0) {
      return totalEstimatedCost;
    }

    return totalEstimatedCost / maxMembers;
  }

  bool get isPublished {
    return status == 'published';
  }

  bool get isActive {
    return status == 'active';
  }

  bool get isCompleted {
    return status == 'completed';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  String memberNameFor(String uid) {
    final details = memberDetails[uid];

    if (details != null &&
        details.displayName.trim().isNotEmpty &&
        details.displayName.trim() != 'Rider') {
      return details.displayName.trim();
    }

    final requestDetails = joinRequestDetails[uid];

    if (requestDetails != null &&
        requestDetails.displayName.trim().isNotEmpty &&
        requestDetails.displayName.trim() != 'Rider') {
      return requestDetails.displayName.trim();
    }

    if (uid == leaderUid && leaderName.trim().isNotEmpty) {
      return leaderName.trim();
    }

    return 'Rider';
  }

  String? memberPhotoFor(String uid) {
    final details = memberDetails[uid];

    if (details != null) {
      final photo = details.photoUrl?.trim();

      if (photo != null && photo.isNotEmpty) {
        return photo;
      }
    }

    final requestDetails = joinRequestDetails[uid];

    if (requestDetails != null) {
      final photo = requestDetails.photoUrl?.trim();

      if (photo != null && photo.isNotEmpty) {
        return photo;
      }
    }

    if (uid == leaderUid) {
      final photo = leaderPhotoUrl?.trim();

      if (photo != null && photo.isNotEmpty) {
        return photo;
      }
    }

    return null;
  }

  factory CommunityRide.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final parsedMemberDetails = <String, MemberDetails>{};

    final rawMemberDetails = data['memberDetails'];

    if (rawMemberDetails is Map) {
      rawMemberDetails.forEach((key, value) {
        if (key is String && value is Map) {
          parsedMemberDetails[key] = MemberDetails.fromFirestore(
            key,
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final parsedRequestDetails = <String, JoinRequestDetails>{};

    final rawRequestDetails = data['joinRequestDetails'];

    if (rawRequestDetails is Map) {
      rawRequestDetails.forEach((key, value) {
        if (key is String && value is Map) {
          parsedRequestDetails[key] = JoinRequestDetails.fromFirestore(
            key,
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final parsedMembers = _readStringList(data['members']);

    final parsedJoinRequests = _readStringList(data['joinRequests']);

    final parsedWaypoints = <WaypointModel>[];

    final rawWaypoints = data['waypoints'];

    if (rawWaypoints is List) {
      for (int index = 0; index < rawWaypoints.length; index++) {
        final value = rawWaypoints[index];

        if (value is Map) {
          final waypointData = Map<String, dynamic>.from(value);

          parsedWaypoints.add(
            WaypointModel.fromMap(
              waypointData,
              id:
                  waypointData['id'] is String &&
                      (waypointData['id'] as String).trim().isNotEmpty
                  ? waypointData['id'] as String
                  : 'waypoint_$index',
            ),
          );
        }
      }
    }

    parsedWaypoints.sort((a, b) => a.order.compareTo(b.order));

    return CommunityRide(
      documentId: document.id,

      rideId: data['rideId'] as String? ?? document.id,

      title: data['title'] as String? ?? '',

      description: data['description'] as String? ?? '',

      destination: data['destination'] as String? ?? '',

      destinationLatitude: _readDouble(data['destinationLatitude']),

      destinationLongitude: _readDouble(data['destinationLongitude']),

      meetingPoint: data['meetingPoint'] as String? ?? '',

      meetingPointLatitude: _readDouble(data['meetingPointLatitude']),

      meetingPointLongitude: _readDouble(data['meetingPointLongitude']),

      waypoints: List<WaypointModel>.unmodifiable(parsedWaypoints),

      leaderUid: data['leaderUid'] as String? ?? '',

      leaderName: data['leaderName'] as String? ?? 'Unknown Rider',

      leaderPhotoUrl: data['leaderPhotoUrl'] as String?,

      departureTime: _dateFromFirestore(data['departureTime']),

      returnTime: _nullableDateFromFirestore(data['returnTime']),

      createdAt: _dateFromFirestore(data['createdAt']),

      category: data['category'] as String? ?? 'Adventure',

      visibility: data['visibility'] as String? ?? 'public',

      status: data['status'] as String? ?? 'published',

      maxMembers: _readInt(data['maxMembers']) ?? 20,

      members: parsedMembers,

      memberDetails: parsedMemberDetails,

      joinRequests: parsedJoinRequests,

      joinRequestDetails: parsedRequestDetails,

      estimatedDistanceKm: _readDouble(data['estimatedDistanceKm']),

      estimatedDurationMinutes: _readInt(data['estimatedDurationMinutes']),

      difficulty: data['difficulty'] as String?,

      terrain: data['terrain'] as String?,

      isRoundTrip: data['isRoundTrip'] as bool? ?? false,

      vehicleType: data['vehicleType'] as String? ?? 'Motorcycle',

      vehicleRequirement: data['vehicleRequirement'] as String? ?? '',

      fuelCost: _readDouble(data['fuelCost']) ?? 0,

      tollCost: _readDouble(data['tollCost']) ?? 0,

      parkingCost: _readDouble(data['parkingCost']) ?? 0,

      accommodationCost: _readDouble(data['accommodationCost']) ?? 0,

      otherCost: _readDouble(data['otherCost']) ?? 0,

      helmetRequired: data['helmetRequired'] as bool? ?? true,

      licenceRequired: data['licenceRequired'] as bool? ?? true,

      additionalInstructions: data['additionalInstructions'] as String? ?? '',

      isFeatured: data['isFeatured'] as bool? ?? false,

      operationalRideDocumentId: data['operationalRideDocumentId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideId': rideId,

      'title': title,
      'description': description,

      'destination': destination,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,

      'meetingPoint': meetingPoint,
      'meetingPointLatitude': meetingPointLatitude,
      'meetingPointLongitude': meetingPointLongitude,

      'waypoints': waypoints.map((waypoint) => waypoint.toMap()).toList(),

      'leaderUid': leaderUid,
      'leaderName': leaderName,
      'leaderPhotoUrl': leaderPhotoUrl,

      'departureTime': Timestamp.fromDate(departureTime),

      'returnTime': returnTime == null ? null : Timestamp.fromDate(returnTime!),

      'createdAt': Timestamp.fromDate(createdAt),

      'category': category,
      'visibility': visibility,
      'status': status,
      'maxMembers': maxMembers,

      'members': members,

      'memberDetails': {
        for (final entry in memberDetails.entries)
          entry.key: entry.value.toFirestore(),
      },

      'joinRequests': joinRequests,

      'joinRequestDetails': {
        for (final entry in joinRequestDetails.entries)
          entry.key: entry.value.toFirestore(),
      },

      'estimatedDistanceKm': estimatedDistanceKm,

      'estimatedDurationMinutes': estimatedDurationMinutes,

      'difficulty': difficulty,
      'terrain': terrain,
      'isRoundTrip': isRoundTrip,

      'vehicleType': vehicleType,
      'vehicleRequirement': vehicleRequirement,

      'fuelCost': fuelCost,
      'tollCost': tollCost,
      'parkingCost': parkingCost,
      'accommodationCost': accommodationCost,
      'otherCost': otherCost,

      'helmetRequired': helmetRequired,

      'licenceRequired': licenceRequired,

      'additionalInstructions': additionalInstructions,

      'isFeatured': isFeatured,

      'operationalRideDocumentId': operationalRideDocumentId,
    };
  }

  static DateTime _dateFromFirestore(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  static DateTime? _nullableDateFromFirestore(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  CommunityRide copyWith({
    String? documentId,
    String? rideId,

    String? title,
    String? description,

    String? destination,
    double? destinationLatitude,
    double? destinationLongitude,

    String? meetingPoint,
    double? meetingPointLatitude,
    double? meetingPointLongitude,

    List<WaypointModel>? waypoints,

    String? leaderUid,
    String? leaderName,
    String? leaderPhotoUrl,

    DateTime? departureTime,
    DateTime? returnTime,
    DateTime? createdAt,

    String? category,
    String? visibility,
    String? status,

    int? maxMembers,

    List<String>? members,
    Map<String, MemberDetails>? memberDetails,

    List<String>? joinRequests,
    Map<String, JoinRequestDetails>? joinRequestDetails,

    double? estimatedDistanceKm,
    int? estimatedDurationMinutes,

    String? difficulty,
    String? terrain,
    bool? isRoundTrip,

    String? vehicleType,
    String? vehicleRequirement,

    double? fuelCost,
    double? tollCost,
    double? parkingCost,
    double? accommodationCost,
    double? otherCost,

    bool? helmetRequired,
    bool? licenceRequired,

    String? additionalInstructions,

    bool? isFeatured,

    String? operationalRideDocumentId,
  }) {
    return CommunityRide(
      documentId: documentId ?? this.documentId,

      rideId: rideId ?? this.rideId,

      title: title ?? this.title,

      description: description ?? this.description,

      destination: destination ?? this.destination,

      destinationLatitude: destinationLatitude ?? this.destinationLatitude,

      destinationLongitude: destinationLongitude ?? this.destinationLongitude,

      meetingPoint: meetingPoint ?? this.meetingPoint,

      meetingPointLatitude: meetingPointLatitude ?? this.meetingPointLatitude,

      meetingPointLongitude:
          meetingPointLongitude ?? this.meetingPointLongitude,

      waypoints: waypoints ?? this.waypoints,

      leaderUid: leaderUid ?? this.leaderUid,

      leaderName: leaderName ?? this.leaderName,

      leaderPhotoUrl: leaderPhotoUrl ?? this.leaderPhotoUrl,

      departureTime: departureTime ?? this.departureTime,

      returnTime: returnTime ?? this.returnTime,

      createdAt: createdAt ?? this.createdAt,

      category: category ?? this.category,

      visibility: visibility ?? this.visibility,

      status: status ?? this.status,

      maxMembers: maxMembers ?? this.maxMembers,

      members: members ?? this.members,

      memberDetails: memberDetails ?? this.memberDetails,

      joinRequests: joinRequests ?? this.joinRequests,

      joinRequestDetails: joinRequestDetails ?? this.joinRequestDetails,

      estimatedDistanceKm: estimatedDistanceKm ?? this.estimatedDistanceKm,

      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,

      difficulty: difficulty ?? this.difficulty,

      terrain: terrain ?? this.terrain,

      isRoundTrip: isRoundTrip ?? this.isRoundTrip,

      vehicleType: vehicleType ?? this.vehicleType,

      vehicleRequirement: vehicleRequirement ?? this.vehicleRequirement,

      fuelCost: fuelCost ?? this.fuelCost,

      tollCost: tollCost ?? this.tollCost,

      parkingCost: parkingCost ?? this.parkingCost,

      accommodationCost: accommodationCost ?? this.accommodationCost,

      otherCost: otherCost ?? this.otherCost,

      helmetRequired: helmetRequired ?? this.helmetRequired,

      licenceRequired: licenceRequired ?? this.licenceRequired,

      additionalInstructions:
          additionalInstructions ?? this.additionalInstructions,

      isFeatured: isFeatured ?? this.isFeatured,

      operationalRideDocumentId:
          operationalRideDocumentId ?? this.operationalRideDocumentId,
    );
  }
}

class MemberDetails {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? username;
  final DateTime? joinedAt;

  const MemberDetails({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.username,
    this.joinedAt,
  });

  factory MemberDetails.fromFirestore(String uid, Map<String, dynamic> data) {
    return MemberDetails(
      uid: uid,
      displayName: _readName(data),
      photoUrl: _readPhoto(data),
      username: _readUsername(data),
      joinedAt: _readDate(data['joinedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoURL': photoUrl,
      'username': username,
      'joinedAt': joinedAt == null ? null : Timestamp.fromDate(joinedAt!),
    };
  }

  static String _readName(Map<String, dynamic> data) {
    const keys = [
      'displayName',
      'display_name',
      'fullName',
      'full_name',
      'name',
      'username',
      'userName',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Rider';
  }

  static String? _readUsername(Map<String, dynamic> data) {
    const keys = ['username', 'userName'];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static String? _readPhoto(Map<String, dynamic> data) {
    const keys = [
      'photoURL',
      'photoUrl',
      'profilePhoto',
      'profilePhotoUrl',
      'profileImage',
      'profileImageUrl',
      'avatar',
      'avatarUrl',
      'imageUrl',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}

class JoinRequestDetails {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? username;
  final DateTime? requestedAt;

  const JoinRequestDetails({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.username,
    this.requestedAt,
  });

  MemberDetails toMemberDetails() {
    return MemberDetails(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      username: username,
      joinedAt: requestedAt,
    );
  }

  factory JoinRequestDetails.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return JoinRequestDetails(
      uid: uid,
      displayName: _readName(data),
      photoUrl: _readPhoto(data),
      username: _readUsername(data),
      requestedAt: _readDate(data['requestedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'photoURL': photoUrl,
      'username': username,
      'requestedAt': requestedAt == null
          ? null
          : Timestamp.fromDate(requestedAt!),
    };
  }

  static String _readName(Map<String, dynamic> data) {
    const keys = [
      'displayName',
      'display_name',
      'fullName',
      'full_name',
      'name',
      'username',
      'userName',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Rider';
  }

  static String? _readUsername(Map<String, dynamic> data) {
    const keys = ['username', 'userName'];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static String? _readPhoto(Map<String, dynamic> data) {
    const keys = [
      'photoURL',
      'photoUrl',
      'profilePhoto',
      'profilePhotoUrl',
      'profileImage',
      'profileImageUrl',
      'avatar',
      'avatarUrl',
      'imageUrl',
    ];

    for (final key in keys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
