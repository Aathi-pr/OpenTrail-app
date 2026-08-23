import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/waypoint_model.dart';
import 'package:open_trail/services/firestore_service.dart';

class WaypointService {
  WaypointService({FirebaseAuth? auth, FirestoreService? firestoreService})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> _waypointCollection(String rideId) {
    return _firestoreService.ridesCollection
        .doc(rideId)
        .collection('waypoints');
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<WaypointModel> addWaypoint({
    required String rideId,
    required WaypointModel waypoint,
  }) async {
    try {
      final user = _requireCurrentUser();
      await _requireLeader(rideId, user.uid);

      final collection = _waypointCollection(rideId);
      final document = collection.doc();
      final nextOrder = await _nextWaypointOrder(rideId);

      final savedWaypoint = waypoint.copyWith(
        id: document.id,
        order: nextOrder,
        creatorId: user.uid,
        creatorName: _displayNameFor(user),
        createdAt: DateTime.now(),
        completed: false,
      );

      await document.set(savedWaypoint.toFirestore());
      return savedWaypoint;
    } on FirebaseException catch (e) {
      throw _firebaseWaypointException(e);
    }
  }

  Stream<List<WaypointModel>> watchWaypoints(String rideId) {
    return _waypointCollection(rideId)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(WaypointModel.fromFirestore).toList(),
        )
        .handleError((error) {
          if (error is FirebaseException) {
            throw _firebaseWaypointException(error);
          }
          throw error;
        });
  }

  Future<void> updateWaypoint({
    required String rideId,
    required WaypointModel waypoint,
  }) async {
    try {
      final user = _requireCurrentUser();
      await _requireLeader(rideId, user.uid);

      await _waypointCollection(
        rideId,
      ).doc(waypoint.id).update(waypoint.toFirestore());
    } on FirebaseException catch (e) {
      throw _firebaseWaypointException(e);
    }
  }

  Future<void> deleteWaypoint({
    required String rideId,
    required String waypointId,
  }) async {
    try {
      final user = _requireCurrentUser();
      await _requireLeader(rideId, user.uid);

      await _waypointCollection(rideId).doc(waypointId).delete();
    } on FirebaseException catch (e) {
      throw _firebaseWaypointException(e);
    }
  }

  Future<void> setWaypointCompleted({
    required String rideId,
    required String waypointId,
    required bool completed,
  }) async {
    try {
      final user = _requireCurrentUser();
      await _requireLeader(rideId, user.uid);

      await _waypointCollection(
        rideId,
      ).doc(waypointId).update({'completed': completed});
    } on FirebaseException catch (e) {
      throw _firebaseWaypointException(e);
    }
  }

  Future<int> _nextWaypointOrder(String rideId) async {
    final latestWaypoint = await _waypointCollection(
      rideId,
    ).orderBy('order', descending: true).limit(1).get();

    if (latestWaypoint.docs.isEmpty) return 0;

    final data = latestWaypoint.docs.first.data();
    return (data['order'] as int? ?? -1) + 1;
  }

  Future<void> _requireLeader(String rideId, String userId) async {
    final snapshot = await _firestoreService.getRideDocument(rideId);

    if (!snapshot.exists) {
      throw const WaypointException('Ride not found.');
    }

    final ride = RideModel.fromFirestore(snapshot);

    if (ride.leaderId != userId) {
      throw const WaypointException(
        'Only the ride leader can manage waypoints.',
      );
    }
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const WaypointException('You must be signed in to continue.');
    }
    return user;
  }

  String _displayNameFor(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Rider';
  }

  WaypointException _firebaseWaypointException(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return const WaypointException(
        'Permission denied. Check Firestore rules for waypoints.',
      );
    }
    if (error.message != null && error.message!.trim().isNotEmpty) {
      return WaypointException(error.message!.trim());
    }
    return WaypointException('Firestore error: ${error.code}');
  }
}

class WaypointException implements Exception {
  const WaypointException(this.message);
  final String message;

  @override
  String toString() => message;
}
