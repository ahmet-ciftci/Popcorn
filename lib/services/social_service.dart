import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final snapshot = await _db
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lowerQuery)
        .where('username', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList();
  }

  // follow a user
  Future<void> follow(String targetUid) async {
    print('Current user (following): $_uid');
    print('Target user (followers): $targetUid');
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
      _db.collection('users').doc(targetUid),
      {'followersCount': FieldValue.increment(1)},
    );

    batch.update(
      _db.collection('users').doc(_uid),
      {'followingCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  // unfollow a user
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

  // check if current user is following target
  Future<bool> isFollowing(String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  // get another user's profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }

  // get another user's watched list
  Future<List<Map<String, dynamic>>> getUserWatched(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('watched')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // get another user's favorites
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

  // get another user's custom lists
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

  // get another user's watchlist
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