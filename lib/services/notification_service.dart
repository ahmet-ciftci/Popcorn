import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final snapshot = await _db
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> deleteNotification(String notifId) async {
    await _db
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .doc(notifId)
        .delete();
  }

  Future<int> getUnreadCount() async {
    final snapshot = await _db
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();

    return snapshot.docs.length;
  }

  Future<void> markAllRead() async {
    final snapshot = await _db
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  Future<void> markRead(String notifId) async {
    await _db
        .collection('notifications')
        .doc(_uid)
        .collection('items')
        .doc(notifId)
        .update({'read': true});
  }
}