import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_trail/models/ride_model.dart';
import 'package:open_trail/models/rider_location_model.dart';
import 'package:open_trail/services/firestore_service.dart';

class RideService {
  RideService({
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
    Random? random,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestoreService = firestoreService ?? FirestoreService(),
       _random = random ?? Random.secure();

  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;
  final Random _random;

  static const _rideIdPrefix = 'OT';
  static const _rideIdLength = 6;
  static const _rideIdCharacters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  Future<RideModel> createRide({
    String? destination,
    double? destinationLatitude,
    double? destinationLongitude,
  }) async {
    try {
      final user = _requireCurrentUser();
      final leaderName = _displayNameFor(user);

      for (var attempt = 0; attempt < 8; attempt++) {
        final rideId = _generateRideIdCandidate();
        final rideDocument = _firestoreService.createRideDocument();
        final rideIdDocument = _firestoreService.rideIdDocument(rideId);
        var rideCreated = false;

        await _firestoreService.runTransaction((transaction) async {
          final rideIdSnapshot = await transaction.get(rideIdDocument);
          if (rideIdSnapshot.exists) return;

          transaction.set(rideIdDocument, {
            'rideDocumentId': rideDocument.id,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // transaction.set(rideDocument, {
          //   'rideId': rideId,
          //   'leaderId': user.uid,
          //   'leaderName': leaderName,
          //   'destination': destination,
          //   'destinationLatitude': destinationLatitude,
          //   'destinationLongitude': destinationLongitude,
          //   'createdAt': FieldValue.serverTimestamp(),
          //   'status': RideStatus.active,
          //   'memberCount': 1,
          // });

          transaction.set(rideDocument, {
            'rideId': rideId,
            'leaderId': user.uid,
            'leaderName': leaderName,

            'destination': destination,
            'destinationLatitude': destinationLatitude,
            'destinationLongitude': destinationLongitude,

            'isNavigating': false,

            'createdAt': FieldValue.serverTimestamp(),
            'status': RideStatus.active,
            'memberCount': 1,
          });

          transaction.set(rideDocument.collection('members').doc(user.uid), {
            'userId': user.uid,
            'displayName': leaderName,
            'role': 'leader',
            'joinedAt': FieldValue.serverTimestamp(),
          });

          rideCreated = true;
        });

        if (rideCreated) {
          return RideModel(
            documentId: rideDocument.id,
            rideId: rideId,
            leaderId: user.uid,
            leaderName: leaderName,
            destination: destination,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude,
            createdAt: DateTime.now(),
            status: RideStatus.active,
            memberCount: 1,
            isNavigating: false,
          );
        }
      }

      throw RideException('Could not generate a unique Ride ID. Try again.');
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Future<RideModel?> getRideById(String rideId) async {
    try {
      final normalizedRideId = _normalizeRideId(rideId);
      if (normalizedRideId.isEmpty) return null;

      final result = await _firestoreService.findRideByRideId(normalizedRideId);
      if (result.docs.isEmpty) return null;

      return RideModel.fromFirestore(result.docs.first);
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Stream<RideModel?> watchRide(String rideDocumentId) {
    return _firestoreService
        .watchRide(rideDocumentId)
        .map((document) {
          if (!document.exists) return null;
          return RideModel.fromFirestore(document);
        })
        .handleError((error) {
          if (error is FirebaseException) {
            throw _firebaseRideException(error);
          }

          throw error;
        });
  }

  Future<RideModel> joinRide(String rideId) async {
    try {
      final user = _requireCurrentUser();
      final ride = await getRideById(rideId);

      if (ride == null) {
        throw RideException('Ride not found.');
      }

      if (!ride.isActive) {
        throw RideException('Ride has already ended.');
      }

      final rideDocument = _firestoreService.ridesCollection.doc(
        ride.documentId,
      );
      final memberDocument = rideDocument.collection('members').doc(user.uid);
      var addedMember = false;

      await _firestoreService.runTransaction((transaction) async {
        final memberSnapshot = await transaction.get(memberDocument);

        if (!memberSnapshot.exists) {
          addedMember = true;

          transaction.set(memberDocument, {
            'userId': user.uid,
            'displayName': _displayNameFor(user),
            'role': 'member',
            'joinedAt': FieldValue.serverTimestamp(),
          });

          transaction.update(rideDocument, {
            'memberCount': FieldValue.increment(1),
          });
        }
      });

      return ride.copyWith(
        memberCount: addedMember ? ride.memberCount + 1 : ride.memberCount,
      );
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Future<void> leaveRide(String rideDocumentId) async {
    try {
      final user = _requireCurrentUser();
      final rideDocument = _firestoreService.ridesCollection.doc(
        rideDocumentId,
      );
      final memberDocument = rideDocument.collection('members').doc(user.uid);

      await _firestoreService.runTransaction((transaction) async {
        final rideSnapshot = await transaction.get(rideDocument);
        if (!rideSnapshot.exists) return;

        final ride = RideModel.fromFirestore(rideSnapshot);
        if (ride.leaderId == user.uid) {
          throw RideException('Leader cannot leave. End the ride instead.');
        }

        final memberSnapshot = await transaction.get(memberDocument);
        if (!memberSnapshot.exists) return;

        transaction.delete(memberDocument);
        transaction.update(rideDocument, {
          'memberCount': FieldValue.increment(-1),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Future<void> endRide(String rideDocumentId) async {
    try {
      final user = _requireCurrentUser();
      final rideDocument = _firestoreService.ridesCollection.doc(
        rideDocumentId,
      );

      await _firestoreService.runTransaction((transaction) async {
        final rideSnapshot = await transaction.get(rideDocument);
        if (!rideSnapshot.exists) {
          throw RideException('Ride not found.');
        }

        final ride = RideModel.fromFirestore(rideSnapshot);
        if (ride.leaderId != user.uid) {
          throw RideException('Only the leader can end this ride.');
        }

        transaction.update(rideDocument, {'status': RideStatus.ended});
      });
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

Future<void> updateDestination(
    String rideDocumentId, {
    required String destination,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final user = _requireCurrentUser();

      final rideDoc = _firestoreService.ridesCollection.doc(rideDocumentId);

      final snapshot = await rideDoc.get();

      if (!snapshot.exists) {
        throw RideException("Ride not found.");
      }

      final ride = RideModel.fromFirestore(snapshot);

      if (ride.leaderId != user.uid) {
        throw RideException("Only the leader can change destination.");
      }

      await rideDoc.update({
        'destination': destination,
        'destinationLatitude': latitude,
        'destinationLongitude': longitude,
      });
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Future<void> startRideNavigation(String rideDocumentId) async {
    try {
      final user = _requireCurrentUser();

      final rideDoc = _firestoreService.ridesCollection.doc(rideDocumentId);

      final snapshot = await rideDoc.get();

      if (!snapshot.exists) {
        throw RideException("Ride not found.");
      }

      final ride = RideModel.fromFirestore(snapshot);

      if (ride.leaderId != user.uid) {
        throw RideException("Only the leader can start navigation.");
      }

      await rideDoc.update({'isNavigating': true});
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  Future<void> stopRideNavigation(String rideDocumentId) async {
    try {
      final user = _requireCurrentUser();

      final rideDoc = _firestoreService.ridesCollection.doc(rideDocumentId);

      final snapshot = await rideDoc.get();

      if (!snapshot.exists) {
        throw RideException("Ride not found.");
      }

      final ride = RideModel.fromFirestore(snapshot);

      if (ride.leaderId != user.uid) {
        throw RideException("Only the leader can stop navigation.");
      }

      await rideDoc.update({'isNavigating': false});
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }



  // ---- Convoy / live location tracking ----

  /// Pushes the current user's live position to their member doc for this ride.
  /// Call this on a throttled basis (e.g. every few seconds or N meters moved),
  /// not on every single GPS callback.
  Future<void> updateMemberLocation(
    String rideDocumentId, {
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    try {
      final user = _requireCurrentUser();
      final memberDocument = _firestoreService.ridesCollection
          .doc(rideDocumentId)
          .collection('members')
          .doc(user.uid);

      await memberDocument.set({
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw _firebaseRideException(error);
    }
  }

  /// Streams every member of the ride (including yourself). The MapPage is
  /// responsible for filtering out its own uid and members without a location yet.
  Stream<List<RiderLocationModel>> watchMemberLocations(String rideDocumentId) {
    return _firestoreService.ridesCollection
        .doc(rideDocumentId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RiderLocationModel.fromFirestore(doc))
              .toList();
        })
        .handleError((error) {
          if (error is FirebaseException) {
            throw _firebaseRideException(error);
          }
          throw error;
        });
  }

  /// Convenience getter so callers (like MapPage) can identify "self" in a
  /// stream of RiderLocationModel without re-importing FirebaseAuth everywhere.
  String? get currentUserId => _auth.currentUser?.uid;

  RideException _firebaseRideException(FirebaseException error) {
    if (error.code == 'not-found') {
      return RideException(
        'Cloud Firestore database "${FirestoreService.databaseId}" was not found in project opentrail-app.',
      );
    }

    if (error.code == 'permission-denied') {
      return const RideException(
        'Firestore permission denied. Check your Firestore security rules.',
      );
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return RideException(error.message!.trim());
    }

    return RideException('Firestore error: ${error.code}');
  }

  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw RideException('You must be signed in to continue.');
    }
    return user;
  }

  String _generateRideIdCandidate() {
    final body = List.generate(_rideIdLength, (_) {
      return _rideIdCharacters[_random.nextInt(_rideIdCharacters.length)];
    }).join();

    return '$_rideIdPrefix-$body';
  }

  String _normalizeRideId(String rideId) {
    return rideId.trim().toUpperCase();
  }

  String _displayNameFor(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Rider';
  }
}

class RideException implements Exception {
  const RideException(this.message);

  final String message;

  @override
  String toString() => message;
}
