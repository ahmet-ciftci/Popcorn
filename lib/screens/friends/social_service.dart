import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .where((user) => user['uid'] != _uid)
        .toList();
  }

  Future<void> follow(String targetUid) async {
    final batch = _db.batch();

    batch.set(
      _db.collection('users').doc(_uid).collection('following').doc(targetUid),
      {'uid': targetUid, 'followedAt': FieldValue.serverTimestamp()},
    );

    batch.set(
      _db.collection('users').doc(targetUid).collection('followers').doc(_uid),
      {'uid': _uid, 'followedAt': FieldValue.serverTimestamp()},
    );

    batch.update(
      _db.collection('users').doc(_uid),
      {'followingCount': FieldValue.increment(1)},
    );
    batch.update(
      _db.collection('users').doc(targetUid),
      {'followersCount': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  Future<void> unfollow(String targetUid) async {
    final batch = _db.batch();

    batch.delete(
      _db.collection('users').doc(_uid).collection('following').doc(targetUid),
    );
    batch.delete(
      _db.collection('users').doc(targetUid).collection('followers').doc(_uid),
    );

    batch.update(
      _db.collection('users').doc(_uid),
      {'followingCount': FieldValue.increment(-1)},
    );
    batch.update(
      _db.collection('users').doc(targetUid),
      {'followersCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  Future<bool> isFollowing(String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  // bring information another users
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }

  Future<List<Map<String, dynamic>>> getUserWatched(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('watched')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // // another's users favorites
  Future<List<Map<String, dynamic>?>> getUserFavorites(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .get();

    final List<Map<String, dynamic>?> slots = [null, null, null, null];
    for (final doc in snapshot.docs) {
      final slot = int.tryParse(doc.id);
      if (slot != null && slot >= 0 && slot < 4) {
        slots[slot] = doc.data();
      }
    }
    return slots;
  }

  // another's users list
  Future<List<Map<String, dynamic>>> getUserLists(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('lists')
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  // another's users watchlist
  Future<List<Map<String, dynamic>>> getUserWatchlist(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}