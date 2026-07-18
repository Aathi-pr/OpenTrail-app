import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: databaseId,
          );

  final FirebaseFirestore _firestore;
  static const databaseId = String.fromEnvironment(
    'FIRESTORE_DATABASE_ID',
    defaultValue: '(default)',
  );

  CollectionReference<Map<String, dynamic>> get usersCollection {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> get ridesCollection {
    return _firestore.collection('rides');
  }

  CollectionReference<Map<String, dynamic>> get rideIdsCollection {
    return _firestore.collection('rideIds');
  }

  DocumentReference<Map<String, dynamic>> rideIdDocument(String rideId) {
    return rideIdsCollection.doc(rideId);
  }

  CollectionReference<Map<String, dynamic>> rideMembersCollection(
    String rideDocumentId,
  ) {
    return ridesCollection.doc(rideDocumentId).collection('members');
  }

  DocumentReference<Map<String, dynamic>> createRideDocument() {
    return ridesCollection.doc();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> findRideByRideId(String rideId) {
    return ridesCollection.where('rideId', isEqualTo: rideId).limit(1).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRide(
    String rideDocumentId,
  ) {
    return ridesCollection.doc(rideDocumentId).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getRideDocument(
    String rideDocumentId,
  ) {
    return ridesCollection.doc(rideDocumentId).get();
  }

  Future<void> runTransaction(
    Future<void> Function(Transaction transaction) action,
  ) {
    return _firestore.runTransaction(action);
  }
}
