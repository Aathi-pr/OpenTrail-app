import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import 'package:open_trail/models/community_ride.dart';
import 'package:open_trail/models/navigation_route.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/route_service.dart';

class CommunityRideService {
  CommunityRideService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    RouteService? routeService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _routeService = routeService ?? RouteService();

  final FirebaseFirestore _firestore;

  final FirebaseAuth _auth;

  final RouteService _routeService;

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('community_rides');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String? get currentUserId => _auth.currentUser?.uid;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('You must be signed in.');
    }

    return user;
  }

  Future<CommunityRide> createCommunityRide({
    required String title,
    required String description,

    required String meetingPoint,
    required double? meetingPointLatitude,
    required double? meetingPointLongitude,

    required String destination,
    required double? destinationLatitude,
    required double? destinationLongitude,

    required List<WaypointModel> waypoints,

    double? estimatedDistanceKm,
    int? estimatedDurationMinutes,

    double fuelCost = 0,
    double tollCost = 0,
    double parkingCost = 0,
    double accommodationCost = 0,
    double otherCost = 0,

    required DateTime departureTime,
    DateTime? returnTime,
    bool isRoundTrip = false,

    required String category,
    required String difficulty,
    required String terrain,
    required int maxMembers,

    bool isPublic = true,

    bool helmetRequired = true,
    bool licenceRequired = true,

    String vehicleType = 'Motorcycle',

    String vehicleRequirement = '',

    String additionalInstructions = '',
  }) async {
    final user = _currentUser;

    if (title.trim().isEmpty) {
      throw Exception('Ride name is required.');
    }

    if (meetingPoint.trim().isEmpty) {
      throw Exception('Starting point is required.');
    }

    if (destination.trim().isEmpty) {
      throw Exception('Destination is required.');
    }

    if (meetingPointLatitude == null || meetingPointLongitude == null) {
      throw Exception('Starting point coordinates are missing.');
    }

    if (destinationLatitude == null || destinationLongitude == null) {
      throw Exception('Destination coordinates are missing.');
    }

    if (departureTime.isBefore(DateTime.now())) {
      throw Exception('Departure time must be in the future.');
    }

    if (isRoundTrip) {
      if (returnTime == null) {
        throw Exception('Return date and time are required for a round trip.');
      }

      if (!returnTime.isAfter(departureTime)) {
        throw Exception('Return time must be after departure time.');
      }
    }

    if (maxMembers < 2) {
      throw Exception('At least 2 riders are required.');
    }

    final sortedWaypoints = [...waypoints]
      ..sort((a, b) => a.order.compareTo(b.order));

    final routeCoordinates = <LatLng>[
      LatLng(meetingPointLatitude, meetingPointLongitude),

      ...sortedWaypoints.map((waypoint) => waypoint.location),

      LatLng(destinationLatitude, destinationLongitude),
    ];

    if (isRoundTrip) {
      routeCoordinates.add(LatLng(meetingPointLatitude, meetingPointLongitude));
    }

    final calculatedRoute = await _routeService.getRoute(
      coordinates: routeCoordinates,
    );

    final totalStopMinutes = sortedWaypoints.fold<int>(
      0,
      (total, waypoint) => total + waypoint.stopMinutes,
    );

    final calculatedDistanceKm = calculatedRoute.distanceMeters / 1000.0;

    final calculatedDrivingMinutes = (calculatedRoute.durationSeconds / 60)
        .ceil();

    final calculatedTotalMinutes = calculatedDrivingMinutes + totalStopMinutes;

    final document = _ridesCollection.doc();

    final rideId = 'OT-${document.id.substring(0, 6).toUpperCase()}';

    final now = DateTime.now();

    final profile = await _getUserProfileModel(user.uid);

    final leaderName = _bestDisplayName(user: user, profile: profile);

    final leaderPhoto = _bestPhotoUrl(user: user, profile: profile);

    final ride = CommunityRide(
      documentId: document.id,

      rideId: rideId,

      title: title.trim(),

      description: description.trim(),

      meetingPoint: meetingPoint.trim(),

      meetingPointLatitude: meetingPointLatitude,

      meetingPointLongitude: meetingPointLongitude,

      destination: destination.trim(),

      destinationLatitude: destinationLatitude,

      destinationLongitude: destinationLongitude,

      waypoints: List<WaypointModel>.unmodifiable(sortedWaypoints),

      estimatedDistanceKm: calculatedDistanceKm,

      estimatedDurationMinutes: calculatedTotalMinutes,

      leaderUid: user.uid,

      leaderName: leaderName,

      leaderPhotoUrl: leaderPhoto,

      departureTime: departureTime,

      returnTime: returnTime,

      createdAt: now,

      isRoundTrip: isRoundTrip,

      category: category.trim(),

      difficulty: difficulty.trim(),

      terrain: terrain.trim(),

      visibility: isPublic ? 'public' : 'private',

      status: 'published',

      maxMembers: maxMembers,

      fuelCost: fuelCost,

      tollCost: tollCost,

      parkingCost: parkingCost,

      accommodationCost: accommodationCost,

      otherCost: otherCost,

      helmetRequired: helmetRequired,

      licenceRequired: licenceRequired,

      vehicleType: vehicleType.trim().isEmpty
          ? 'Motorcycle'
          : vehicleType.trim(),

      vehicleRequirement: vehicleRequirement.trim(),

      additionalInstructions: additionalInstructions.trim(),

      members: [user.uid],

      memberDetails: {
        user.uid: MemberDetails(
          uid: user.uid,
          displayName: leaderName,
          photoUrl: leaderPhoto,
          username: profile?.username,
          joinedAt: now,
        ),
      },

      joinRequests: const [],

      joinRequestDetails: const {},

      isFeatured: false,
    );

    await document.set(ride.toFirestore());

    return ride;
  }

  Future<CommunityRideRoutePreview> calculateRoutePreview({
    required LatLng start,
    required LatLng destination,
    required List<WaypointModel> waypoints,
    bool isRoundTrip = false,
  }) async {
    final sortedWaypoints = [...waypoints]
      ..sort((a, b) => a.order.compareTo(b.order));

    final coordinates = <LatLng>[
      start,

      ...sortedWaypoints.map((waypoint) => waypoint.location),

      destination,
    ];

    if (isRoundTrip) {
      coordinates.add(start);
    }

    final route = await _routeService.getRoute(coordinates: coordinates);

    final stopMinutes = sortedWaypoints.fold<int>(
      0,
      (total, waypoint) => total + waypoint.stopMinutes,
    );

    final drivingMinutes = (route.durationSeconds / 60).ceil();

    final totalMinutes = drivingMinutes + stopMinutes;

    return CommunityRideRoutePreview(
      route: route,

      distanceKm: route.distanceMeters / 1000.0,

      drivingMinutes: drivingMinutes,

      stopMinutes: stopMinutes,

      totalMinutes: totalMinutes,
    );
  }

  Stream<List<CommunityRide>> watchPublicRides() {
    return _ridesCollection
        .where('visibility', isEqualTo: 'public')
        .where('status', isEqualTo: 'published')
        .orderBy('departureTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CommunityRide.fromFirestore).toList(),
        );
  }

  Stream<List<CommunityRide>> watchMyCreatedRides() {
    final user = _currentUser;

    return _ridesCollection
        .where('leaderUid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(CommunityRide.fromFirestore).toList(),
        );
  }

  Future<CommunityRide?> getRide(String documentId) async {
    final document = await _ridesCollection.doc(documentId).get();

    if (!document.exists) {
      return null;
    }

    return CommunityRide.fromFirestore(document);
  }

  Stream<CommunityRide?> watchRide(String documentId) {
    return _ridesCollection.doc(documentId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return CommunityRide.fromFirestore(snapshot);
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  Future<Map<String, UserProfile>> getRiderProfiles(
    List<String> userIds,
  ) async {
    final uniqueIds = userIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList();

    if (uniqueIds.isEmpty) {
      return {};
    }

    final result = <String, UserProfile>{};

    const chunkSize = 30;

    for (int start = 0; start < uniqueIds.length; start += chunkSize) {
      final end = (start + chunkSize > uniqueIds.length)
          ? uniqueIds.length
          : start + chunkSize;

      final chunk = uniqueIds.sublist(start, end);

      final snapshot = await _usersCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final document in snapshot.docs) {
        result[document.id] = UserProfile.fromFirestore(
          document.id,
          document.data(),
        );
      }
    }

    return result;
  }

  Future<void> requestToJoin(String documentId) async {
    final user = _currentUser;

    final profile = await _getUserProfileModel(user.uid);

    final displayName = _bestDisplayName(user: user, profile: profile);

    final photoUrl = _bestPhotoUrl(user: user, profile: profile);

    final requestDetails = JoinRequestDetails(
      uid: user.uid,

      displayName: displayName,

      photoUrl: photoUrl,

      username: profile?.username,

      requestedAt: DateTime.now(),
    );

    final rideReference = _ridesCollection.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final ride = CommunityRide.fromFirestore(snapshot);

      if (ride.leaderUid == user.uid) {
        throw Exception('You are already the ride leader.');
      }

      if (ride.status != 'published') {
        throw Exception('This ride is no longer accepting requests.');
      }

      if (ride.isFull) {
        throw Exception('This ride is already full.');
      }

      if (ride.hasMember(user.uid)) {
        throw Exception('You have already joined this ride.');
      }

      if (ride.hasJoinRequest(user.uid)) {
        throw Exception('Join request already sent.');
      }

      final updatedRequestDetails = <String, dynamic>{
        for (final entry in ride.joinRequestDetails.entries)
          entry.key: entry.value.toFirestore(),
      };

      updatedRequestDetails[user.uid] = requestDetails.toFirestore();

      transaction.update(rideReference, {
        'joinRequests': FieldValue.arrayUnion([user.uid]),

        'joinRequestDetails': updatedRequestDetails,
      });
    });
  }

  Future<void> cancelJoinRequest(String documentId) async {
    final user = _currentUser;

    final rideReference = _ridesCollection.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final ride = CommunityRide.fromFirestore(snapshot);

      final updatedRequestDetails = <String, dynamic>{
        for (final entry in ride.joinRequestDetails.entries)
          if (entry.key != user.uid) entry.key: entry.value.toFirestore(),
      };

      transaction.update(rideReference, {
        'joinRequests': FieldValue.arrayRemove([user.uid]),

        'joinRequestDetails': updatedRequestDetails,
      });
    });
  }

  Future<void> acceptJoinRequest({
    required String documentId,
    required String userId,
  }) async {
    final currentUser = _currentUser;

    final rideReference = _ridesCollection.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final ride = CommunityRide.fromFirestore(snapshot);

      if (ride.leaderUid != currentUser.uid) {
        throw Exception('Only the ride leader can accept requests.');
      }

      if (!ride.hasJoinRequest(userId)) {
        throw Exception('Join request not found.');
      }

      if (ride.isFull) {
        throw Exception('The ride is already full.');
      }

      final request = ride.joinRequestDetails[userId];

      if (request == null) {
        throw Exception(
          'Rider profile information is missing from this request.',
        );
      }

      final acceptedMember = MemberDetails(
        uid: request.uid,

        displayName: request.displayName,

        photoUrl: request.photoUrl,

        username: request.username,

        joinedAt: request.requestedAt,
      );

      final updatedMemberDetails = <String, dynamic>{
        for (final entry in ride.memberDetails.entries)
          entry.key: entry.value.toFirestore(),
      };

      updatedMemberDetails[userId] = acceptedMember.toFirestore();

      final updatedRequestDetails = <String, dynamic>{
        for (final entry in ride.joinRequestDetails.entries)
          if (entry.key != userId) entry.key: entry.value.toFirestore(),
      };

      transaction.update(rideReference, {
        'members': FieldValue.arrayUnion([userId]),

        'joinRequests': FieldValue.arrayRemove([userId]),

        'memberDetails': updatedMemberDetails,

        'joinRequestDetails': updatedRequestDetails,
      });
    });
  }

  Future<void> rejectJoinRequest({
    required String documentId,
    required String userId,
  }) async {
    final currentUser = _currentUser;

    final rideReference = _ridesCollection.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final ride = CommunityRide.fromFirestore(snapshot);

      if (ride.leaderUid != currentUser.uid) {
        throw Exception('Only the ride leader can reject requests.');
      }

      if (!ride.hasJoinRequest(userId)) {
        throw Exception('Join request not found.');
      }

      final updatedJoinRequests = ride.joinRequests
          .where((uid) => uid != userId)
          .toList();

      final updatedDetails = <String, dynamic>{
        for (final entry in ride.joinRequestDetails.entries)
          if (entry.key != userId) entry.key: entry.value.toFirestore(),
      };

      transaction.update(rideReference, {
        'joinRequests': updatedJoinRequests,

        'joinRequestDetails': updatedDetails,
      });
    });
  }

  Future<void> leaveRide(String documentId) async {
    final user = _currentUser;

    final rideReference = _ridesCollection.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final ride = CommunityRide.fromFirestore(snapshot);

      if (ride.leaderUid == user.uid) {
        throw Exception('The ride leader cannot leave the expedition.');
      }

      final updatedMembers = ride.members
          .where((uid) => uid != user.uid)
          .toList();

      final updatedMemberDetails = <String, dynamic>{
        for (final entry in ride.memberDetails.entries)
          if (entry.key != user.uid) entry.key: entry.value.toFirestore(),
      };

      transaction.update(rideReference, {
        'members': updatedMembers,

        'memberDetails': updatedMemberDetails,
      });
    });
  }

  Future<void> cancelRide(String documentId) async {
    final user = _currentUser;

    final rideReference = _ridesCollection.doc(documentId);

    final snapshot = await rideReference.get();

    if (!snapshot.exists) {
      throw Exception('Ride no longer exists.');
    }

    final ride = CommunityRide.fromFirestore(snapshot);

    if (ride.leaderUid != user.uid) {
      throw Exception('Only the ride leader can cancel this ride.');
    }

    if (ride.status == 'active') {
      throw Exception('An active expedition cannot be cancelled.');
    }

    await rideReference.update({'status': 'cancelled'});
  }

  Future<String> startRide(String documentId) async {
    final user = _currentUser;

    final communityRideReference = _ridesCollection.doc(documentId);

    final operationalRideReference = _firestore.collection('rides').doc();

    final initialSnapshot = await communityRideReference.get();

    if (!initialSnapshot.exists) {
      throw Exception('Ride no longer exists.');
    }

    final ride = CommunityRide.fromFirestore(initialSnapshot);

    if (ride.leaderUid != user.uid) {
      throw Exception('Only the ride leader can start the expedition.');
    }

    if (ride.status != 'published') {
      throw Exception('This expedition has already been started.');
    }

    if (ride.members.isEmpty) {
      throw Exception('At least one rider is required.');
    }

    if (!ride.hasDestination) {
      throw Exception('Destination coordinates are missing.');
    }

    if (!ride.hasMeetingPoint) {
      throw Exception('Starting point coordinates are missing.');
    }

    final fallbackProfiles = await getRiderProfiles(ride.members);

    fallbackProfiles[ride.leaderUid] = UserProfile(
      uid: ride.leaderUid,

      displayName: ride.leaderName,

      photoUrl: ride.leaderPhotoUrl,

      username: null,
    );

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(communityRideReference);

      if (!snapshot.exists) {
        throw Exception('Ride no longer exists.');
      }

      final currentRide = CommunityRide.fromFirestore(snapshot);

      if (currentRide.leaderUid != user.uid) {
        throw Exception('Only the ride leader can start the expedition.');
      }

      if (currentRide.status != 'published') {
        throw Exception('This expedition has already been started.');
      }

      transaction.set(operationalRideReference, {
        'rideId': currentRide.rideId,

        'leaderId': currentRide.leaderUid,

        'leaderName': currentRide.leaderName,

        'leaderPhotoUrl': currentRide.leaderPhotoUrl,

        'destination': currentRide.destination,

        'destinationLatitude': currentRide.destinationLatitude,

        'destinationLongitude': currentRide.destinationLongitude,

        'meetingPoint': currentRide.meetingPoint,

        'meetingPointLatitude': currentRide.meetingPointLatitude,

        'meetingPointLongitude': currentRide.meetingPointLongitude,

        'waypoints': currentRide.waypoints
            .map((waypoint) => waypoint.toMap())
            .toList(),

        'estimatedDistanceKm': currentRide.estimatedDistanceKm,

        'estimatedDurationMinutes': currentRide.estimatedDurationMinutes,

        'category': currentRide.category,

        'difficulty': currentRide.difficulty,

        'terrain': currentRide.terrain,

        'departureTime': Timestamp.fromDate(currentRide.departureTime),

        'returnTime': currentRide.returnTime == null
            ? null
            : Timestamp.fromDate(currentRide.returnTime!),

        'isRoundTrip': currentRide.isRoundTrip,

        'fuelCost': currentRide.fuelCost,

        'tollCost': currentRide.tollCost,

        'parkingCost': currentRide.parkingCost,

        'accommodationCost': currentRide.accommodationCost,

        'otherCost': currentRide.otherCost,

        'helmetRequired': currentRide.helmetRequired,

        'licenceRequired': currentRide.licenceRequired,

        'vehicleType': currentRide.vehicleType,

        'vehicleRequirement': currentRide.vehicleRequirement,

        'additionalInstructions': currentRide.additionalInstructions,

        'isNavigating': false,

        'createdAt': FieldValue.serverTimestamp(),

        'status': RideStatus.active,

        'memberCount': currentRide.members.length,

        'isCommunityRide': true,

        'communityRideDocumentId': currentRide.documentId,

        'communityRideTitle': currentRide.title,
      });

      for (final memberUid in currentRide.members) {
        final isLeader = memberUid == currentRide.leaderUid;

        final storedMember = currentRide.memberDetails[memberUid];

        final fallbackProfile = fallbackProfiles[memberUid];

        String memberName;

        if (storedMember != null &&
            storedMember.displayName.trim().isNotEmpty &&
            storedMember.displayName.trim() != 'Rider') {
          memberName = storedMember.displayName.trim();
        } else if (fallbackProfile?.displayName != null &&
            fallbackProfile!.displayName!.trim().isNotEmpty) {
          memberName = fallbackProfile.displayName!.trim();
        } else if (fallbackProfile?.username != null &&
            fallbackProfile!.username!.trim().isNotEmpty) {
          memberName = fallbackProfile.username!.trim();
        } else if (isLeader && currentRide.leaderName.trim().isNotEmpty) {
          memberName = currentRide.leaderName.trim();
        } else {
          memberName = 'Unknown rider';
        }

        String? memberPhoto;

        final storedPhoto = storedMember?.photoUrl?.trim();

        final fallbackPhoto = fallbackProfile?.photoUrl?.trim();

        if (storedPhoto != null && storedPhoto.isNotEmpty) {
          memberPhoto = storedPhoto;
        } else if (fallbackPhoto != null && fallbackPhoto.isNotEmpty) {
          memberPhoto = fallbackPhoto;
        } else if (isLeader) {
          memberPhoto = currentRide.leaderPhotoUrl;
        }

        final memberReference = operationalRideReference
            .collection('members')
            .doc(memberUid);

        transaction.set(memberReference, {
          'userId': memberUid,

          'displayName': memberName,

          'photoURL': memberPhoto,

          'role': isLeader ? 'leader' : 'member',

          'joinedAt': FieldValue.serverTimestamp(),
        });

        final userRideReference = _firestore
            .collection('users')
            .doc(memberUid)
            .collection('rides')
            .doc(operationalRideReference.id);

        transaction.set(userRideReference, {
          'rideDocumentId': operationalRideReference.id,

          'rideId': currentRide.rideId,

          'leaderId': currentRide.leaderUid,

          'leader': isLeader,

          'displayName': memberName,

          'photoURL': memberPhoto,

          'joinedAt': FieldValue.serverTimestamp(),

          'isCommunityRide': true,

          'communityRideDocumentId': currentRide.documentId,

          'communityRideTitle': currentRide.title,
        });
      }

      transaction.update(communityRideReference, {
        'status': 'active',

        'operationalRideDocumentId': operationalRideReference.id,
      });
    });

    return operationalRideReference.id;
  }

  Future<UserProfile?> _getUserProfileModel(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return UserProfile.fromFirestore(uid, data);
  }

  String _bestDisplayName({required User user, required UserProfile? profile}) {
    final profileName = profile?.displayName?.trim();

    if (profileName != null &&
        profileName.isNotEmpty &&
        profileName != 'Rider') {
      return profileName;
    }

    final username = profile?.username?.trim();

    if (username != null && username.isNotEmpty && username != 'Rider') {
      return username;
    }

    final authName = user.displayName?.trim();

    if (authName != null && authName.isNotEmpty && authName != 'Rider') {
      return authName;
    }

    final email = user.email?.trim();

    if (email != null && email.isNotEmpty) {
      final emailName = email.split('@').first.trim();

      if (emailName.isNotEmpty) {
        return emailName;
      }
    }

    return 'Rider';
  }

  String? _bestPhotoUrl({required User user, required UserProfile? profile}) {
    final profilePhoto = profile?.photoUrl?.trim();

    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      return profilePhoto;
    }

    final authPhoto = user.photoURL?.trim();

    if (authPhoto != null && authPhoto.isNotEmpty) {
      return authPhoto;
    }

    return null;
  }
}

class CommunityRideRoutePreview {
  final NavigationRoute route;

  final double distanceKm;

  final int drivingMinutes;

  final int stopMinutes;

  final int totalMinutes;

  const CommunityRideRoutePreview({
    required this.route,
    required this.distanceKm,
    required this.drivingMinutes,
    required this.stopMinutes,
    required this.totalMinutes,
  });
}

class UserProfile {
  final String uid;

  final String? displayName;

  final String? username;

  final String? photoUrl;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.username,
    this.photoUrl,
  });

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,

      displayName: _readString(data, const [
        'displayName',
        'display_name',
        'fullName',
        'full_name',
        'name',
      ]),

      username: _readString(data, const [
        'username',
        'userName',
        'user_name',
        'handle',
      ]),

      photoUrl: _readString(data, const [
        'photoURL',
        'photoUrl',
        'profilePhoto',
        'profilePhotoUrl',
        'profileImage',
        'profileImageUrl',
        'avatar',
        'avatarUrl',
        'imageUrl',
      ]),
    );
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value is String) {
        final cleaned = value.trim();

        if (cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    return null;
  }
}
