import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a new sign prediction under the user's history
  Future<void> savePrediction({required String userId, required String prediction}) async {
    try {
      await _firestore.collection('users').doc(userId).collection('predictions').add({
        'prediction': prediction,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving prediction: $e');
    }
  }

  /// Save a new meet room
  Future<void> createMeetRoom({required String roomId, required String hostUserId}) async {
    try {
      await _firestore.collection('meet_rooms').doc(roomId).set({
        'host': hostUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating meet room: $e');
    }
  }

  /// Fetch past predictions for a user
  Future<List<String>> getUserPredictions({required String userId}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('predictions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc['prediction'] as String).toList();
    } catch (e) {
      print('Error fetching predictions: $e');
      return [];
    }
  }
}

