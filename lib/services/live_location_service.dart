import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_trail/models/rider_location_model.dart';

class LiveLocationService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> updateLocation({
    required String rideId,
    required String uid,
    required String displayName,
    required String role,
    required Position position,
  }) async {
    await _db.child("live_locations").child(rideId).child(uid).update({
      "userId": uid,
      "displayName": displayName,
      "role": role,
      "latitude": position.latitude,
      "longitude": position.longitude,
      "heading": position.heading,
      "speed": position.speed,
      "isOnline": true,
      "updatedAt": ServerValue.timestamp,
    });
  }

  Stream<List<RiderLocationModel>> watchLocations(String rideId) {
    return _db.child("live_locations").child(rideId).onValue.map((event) {
      final value = event.snapshot.value;

      if (value == null) {
        return <RiderLocationModel>[];
      }

      final data = value as Map<dynamic, dynamic>;

      return data.entries.map((entry) {
        return RiderLocationModel.fromRealtime(
          entry.key.toString(),
          Map<dynamic, dynamic>.from(entry.value),
        );
      }).toList();
    });
  }

  Future<void> removeLocation({
    required String rideId,
    required String uid,
  }) async {
    await _db.child("live_locations").child(rideId).child(uid).remove();
  }

  Future<void> enableDisconnectRemoval({
    required String rideId,
    required String uid,
  }) async {
    await _db
        .child("live_locations")
        .child(rideId)
        .child(uid)
        .onDisconnect()
        .update({"isOnline": false, "updatedAt": ServerValue.timestamp});
  }

  // ===========================
  // SOS
  // ===========================

  Future<void> setSOS({
    required String rideId,
    required String uid,
    required bool active,
  }) async {
    await _db.child("live_locations").child(rideId).child(uid).update({
      "isSOS": active,
      "updatedAt": ServerValue.timestamp,
    });
  }

  Future<void> clearSOS({required String rideId, required String uid}) async {
    await setSOS(rideId: rideId, uid: uid, active: false);
  }
}
