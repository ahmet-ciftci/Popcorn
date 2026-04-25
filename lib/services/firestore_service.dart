import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/movie.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── WATCHED ──

  Future<void> addToWatched(Movie movie, {int? rating, String? review}) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watched')
        .doc(movie.id.toString())
        .set({
      'tmdbId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'rating': rating,
      'review': review,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromWatched(int movieId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watched')
        .doc(movieId.toString())
        .delete();
  }

  Future<bool> isWatched(int movieId) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('watched')
        .doc(movieId.toString())
        .get();
    return doc.exists;
  }

  Future<int?> getRating(int movieId) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('watched')
        .doc(movieId.toString())
        .get();
    if (!doc.exists) return null;
    return doc.data()?['rating'] as int?;
  }

  Future<List<Map<String, dynamic>>> getWatchedList() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('watched')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ── WATCHLIST ──

  Future<void> addToWatchlist(Movie movie) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc(movie.id.toString())
        .set({
      'tmdbId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFromWatchlist(int movieId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc(movieId.toString())
        .delete();
  }

  Future<bool> isInWatchlist(int movieId) async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .doc(movieId.toString())
        .get();
    return doc.exists;
  }

  Future<List<Map<String, dynamic>>> getWatchlist() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('watchlist')
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ── FAVORITES ──

  // Favorilere ekle (max 4)
  Future<void> addToFavorites(Movie movie, int slot) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(slot.toString())
        .set({
      'tmdbId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'slot': slot,
    });
  }

  // Favorilerden kaldır
  Future<void> removeFromFavorites(int slot) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(slot.toString())
        .delete();
  }

  // Favorileri getir (slot sırasına göre, 4 slot: 0-3)
  Future<List<Map<String, dynamic>?>> getFavorites() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .get();

    // 4 slotluk liste, boş slotlar null
    final List<Map<String, dynamic>?> slots = [null, null, null, null];
    for (final doc in snapshot.docs) {
      final slot = int.tryParse(doc.id);
      if (slot != null && slot >= 0 && slot < 4) {
        slots[slot] = doc.data();
      }
    }
    return slots;
  }

  // ── CUSTOM LISTS ──

  Future<String> createList(String name, {String description = ''}) async {
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteList(String listId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .doc(listId)
        .delete();
  }

  Future<void> renameList(String listId, String newName) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .doc(listId)
        .update({'name': newName});
  }

  Future<List<Map<String, dynamic>>> getLists() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> addMovieToList(String listId, Movie movie) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .doc(listId)
        .collection('movies')
        .doc(movie.id.toString())
        .set({
      'tmdbId': movie.id,
      'title': movie.title,
      'posterPath': movie.posterPath,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMovieFromList(String listId, int movieId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .doc(listId)
        .collection('movies')
        .doc(movieId.toString())
        .delete();
  }

  Future<List<Map<String, dynamic>>> getMoviesInList(String listId) async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('lists')
        .doc(listId)
        .collection('movies')
        .orderBy('addedAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}