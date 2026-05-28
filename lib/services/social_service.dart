import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // search users by username
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
        .where((user) => user['uid'] != currentUid)
        .toList();
  }

  // follow or send request depending on target's privacy setting
  Future<String> follow(String targetUid) async {
    final targetDoc = await _db.collection('users').doc(targetUid).get();
    final targetData = targetDoc.data();
    final visibility = targetData?['visibility'];
    final profileVisibility = visibility?['Profile Visibility'] ?? 'Public';

    final currentDoc = await _db.collection('users').doc(_uid).get();
    final username = currentDoc.data()?['username'] ?? '';

    // Public → direkt takip
    if (profileVisibility == 'Public' || profileVisibility == 'Everyone') {
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
      batch.set(
        _db.collection('notifications').doc(targetUid).collection('items').doc(),
        {
          'type': 'follow',
          'fromUid': _uid,
          'fromUsername': username,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return 'followed';

    } else {
      // Private → istek gönder
      await _db
          .collection('users')
          .doc(targetUid)
          .collection('followRequests')
          .doc(_uid)
          .set({
        'fromUid': _uid,
        'fromUsername': username,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db
          .collection('notifications')
          .doc(targetUid)
          .collection('items')
          .doc()
          .set({
        'type': 'follow_request',
        'fromUid': _uid,
        'fromUsername': username,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'requested';
    }
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

  // cancel a follow request
  Future<void> cancelRequest(String targetUid) async {
    await _db
        .collection('users')
        .doc(targetUid)
        .collection('followRequests')
        .doc(_uid)
        .delete();
  }

  // check follow status — 'following', 'requested', or 'none'
  Future<String> getFollowStatus(String targetUid) async {
    final followDoc = await _db
        .collection('users')
        .doc(_uid)
        .collection('following')
        .doc(targetUid)
        .get();
    if (followDoc.exists) return 'following';

    final requestDoc = await _db
        .collection('users')
        .doc(targetUid)
        .collection('followRequests')
        .doc(_uid)
        .get();
    if (requestDoc.exists) return 'requested';

    return 'none';
  }

  // accept a follow request
  Future<void> acceptRequest(String fromUid) async {
    final batch = _db.batch();

    // add to followers/following
    batch.set(
      _db.collection('users').doc(_uid).collection('followers').doc(fromUid),
      {'uid': fromUid, 'followedAt': FieldValue.serverTimestamp()},
    );
    batch.set(
      _db.collection('users').doc(fromUid).collection('following').doc(_uid),
      {'uid': _uid, 'followedAt': FieldValue.serverTimestamp()},
    );
    batch.update(
      _db.collection('users').doc(_uid),
      {'followersCount': FieldValue.increment(1)},
    );
    batch.update(
      _db.collection('users').doc(fromUid),
      {'followingCount': FieldValue.increment(1)},
    );

    // delete the request
    batch.delete(
      _db.collection('users').doc(_uid).collection('followRequests').doc(fromUid),
    );

    await batch.commit();
  }

  // decline a follow request
  Future<void> declineRequest(String fromUid) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('followRequests')
        .doc(fromUid)
        .delete();
  }

  // get pending follow requests
  Future<List<Map<String, dynamic>>> getFollowRequests() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('followRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // check if following
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

  Future<List<Map<String, dynamic>>> getFollowers(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .get();

    List<Map<String, dynamic>> users = [];

    for (final doc in snapshot.docs) {
      final followerUid = doc.id;

      final userDoc =
      await _db.collection('users').doc(followerUid).get();

      if (userDoc.exists) {
        users.add({
          'uid': userDoc.id,
          ...userDoc.data()!,
        });
      }
    }

    return users;
  }

  Future<List<Map<String, dynamic>>> getFollowing(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .orderBy('followedAt', descending: true)
        .get();

    List<Map<String, dynamic>> users = [];

    for (final doc in snapshot.docs) {
      final followingUid = doc.id;

      final userDoc =
      await _db.collection('users').doc(followingUid).get();

      if (userDoc.exists) {
        users.add({
          'uid': userDoc.id,
          ...userDoc.data()!,
        });
      }
    }

    return users;
  }
}