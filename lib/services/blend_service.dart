import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlendService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;


  // create a new blend session, returns the session id
  Future<String> createSession(String name) async {
    final ref = await _db.collection('blendSessions').add({
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'name': name,
      'members': [_uid],
    });
    return ref.id;
  }

  // join a session using session id
  Future<void> joinSession(String sessionId) async {
    await _db.collection('blendSessions').doc(sessionId).update({
      'members': FieldValue.arrayUnion([_uid]),
    });
  }

  // get session info
  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final doc = await _db.collection('blendSessions').doc(sessionId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  // get all sessions current user is a member of
  Future<List<Map<String, dynamic>>> getMySessions() async {
    final snapshot = await _db
        .collection('blendSessions')
        .where('members', arrayContains: _uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  // ── POOL ──

  // add a single movie to the pool
  Future<void> addMovieToPool(
      String sessionId, {
        required int tmdbId,
        required String title,
        required String posterPath,
      }) async {
    await _db
        .collection('blendSessions')
        .doc(sessionId)
        .collection('pool')
        .doc(tmdbId.toString())
        .set({
      'tmdbId': tmdbId,
      'title': title,
      'posterPath': posterPath,
      'addedBy': _uid,
    });
  }

  // add all movies from a list to the pool
  Future<void> addListToPool(
      String sessionId,
      List<Map<String, dynamic>> movies,
      ) async {
    // use batched writes for efficiency
    final batches = <WriteBatch>[];
    var batch = _db.batch();
    var count = 0;

    for (final movie in movies) {
      final ref = _db
          .collection('blendSessions')
          .doc(sessionId)
          .collection('pool')
          .doc(movie['tmdbId'].toString());

      batch.set(ref, {
        'tmdbId': movie['tmdbId'],
        'title': movie['title'],
        'posterPath': movie['posterPath'] ?? '',
        'addedBy': _uid,
      });

      count++;

      // Firestore batch limit is 500
      if (count == 499) {
        batches.add(batch);
        batch = _db.batch();
        count = 0;
      }
    }

    batches.add(batch);
    for (final b in batches) {
      await b.commit();
    }
  }

  // get all movies in pool
  Future<List<Map<String, dynamic>>> getPool(String sessionId) async {
    final snapshot = await _db
        .collection('blendSessions')
        .doc(sessionId)
        .collection('pool')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ── VOTES ──

  // cast a vote on a movie
  Future<void> vote(String sessionId, int tmdbId, bool isYes) async {
    // doc id is uid_tmdbId — forces one vote per person per movie
    final docId = '${_uid}_$tmdbId';

    await _db
        .collection('blendSessions')
        .doc(sessionId)
        .collection('votes')
        .doc(docId)
        .set({
      'uid': _uid,
      'tmdbId': tmdbId,
      'vote': isYes,
      'votedAt': FieldValue.serverTimestamp(),
    });
  }

  // get all votes for a session
  Future<List<Map<String, dynamic>>> getVotes(String sessionId) async {
    final snapshot = await _db
        .collection('blendSessions')
        .doc(sessionId)
        .collection('votes')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // get ranked results — movies sorted by yes vote count
  Future<List<Map<String, dynamic>>> getRankedResults(
      String sessionId) async {
    final pool = await getPool(sessionId);
    final votes = await getVotes(sessionId);

    // count yes votes per movie
    final yesCounts = <int, int>{};
    for (final v in votes) {
      if (v['vote'] == true) {
        final tmdbId = v['tmdbId'] as int;
        yesCounts[tmdbId] = (yesCounts[tmdbId] ?? 0) + 1;
      }
    }

    // attach yes count to each movie
    final results = pool.map((movie) {
      final tmdbId = movie['tmdbId'] as int;
      return {
        ...movie,
        'yesCount': yesCounts[tmdbId] ?? 0,
      };
    }).toList();

    // sort by yes count descending
    results.sort((a, b) =>
        (b['yesCount'] as int).compareTo(a['yesCount'] as int));

    return results;
  }

  // check if current user has voted on a specific movie
  Future<bool?> getMyVote(String sessionId, int tmdbId) async {
    final docId = '${_uid}_$tmdbId';
    final doc = await _db
        .collection('blendSessions')
        .doc(sessionId)
        .collection('votes')
        .doc(docId)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['vote'] as bool?;
  }
}