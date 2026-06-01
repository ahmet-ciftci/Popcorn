import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/api_constants.dart';
import '../movie_detail/movie_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _feed = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _feed = [];
          _loading = false;
        });
        return;
      }

      var db = FirebaseFirestore.instance;

      // people i follow
      var following = await db
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .get();

      List<Map<String, dynamic>> activity = [];

      for (var f in following.docs) {
        var followedId = f.data()['uid'];

        try {
          // their name
          var userDoc = await db.collection('users').doc(followedId).get();
          var username = userDoc.data()?['username'] ?? '';

          // their recent rated / reviewed movies
          var watched = await db
              .collection('users')
              .doc(followedId)
              .collection('watched')
              .orderBy('addedAt', descending: true)
              .limit(5)
              .get();

          for (var w in watched.docs) {
            var data = w.data();
            var rating = data['rating'];
            var review = data['review'];
            var addedAt = data['addedAt'];

            // ratings / reviews only, skip ones with no timestamp yet
            if (addedAt == null) continue;
            if (rating == null && (review == null || review == '')) continue;

            activity.add({
              'username': username,
              'tmdbId': data['tmdbId'],
              'title': data['title'],
              'posterPath': data['posterPath'],
              'rating': rating,
              'review': review,
              'addedAt': addedAt.millisecondsSinceEpoch,
            });
          }
        } catch (e) {
          // can't see this person's stuff (private), skip them
          continue;
        }
      }

      // newest first
      activity.sort((a, b) => b['addedAt'].compareTo(a['addedAt']));

      // keep the 30 most recent
      if (activity.length > 30) {
        activity = activity.sublist(0, 30);
      }

      setState(() {
        _feed = activity;
        _loading = false;
      });
    } catch (e) {
      print('Error loading feed: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Something went wrong.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _hasError = false;
                });
                _loadFeed();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_feed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No activity from people you follow yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _feed.length,
      itemBuilder: (context, index) {
        return _FeedTile(activity: _feed[index]);
      },
    );
  }
}

class _FeedTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _FeedTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    var rating = activity['rating'];
    var review = activity['review'];
    var posterPath = activity['posterPath'] ?? '';

    // what they did
    var action = 'rated';
    if (rating != null && review != null && review != '') {
      action = 'rated and reviewed';
    } else if (rating == null) {
      action = 'reviewed';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MovieDetailScreen(movieId: activity['tmdbId']),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: posterPath.isNotEmpty
                  ? Image.network(
                ApiConstants.imageBaseUrl + posterPath,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 60,
                height: 90,
                color: Color(0xFF222222),
                child: Icon(Icons.movie_outlined, color: Colors.grey),
              ),
            ),
            SizedBox(width: 12),
            // info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activity['username']} $action',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    activity['title'] ?? '',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (rating != null) ...[
                        Icon(Icons.star, color: Color(0xFFE50914), size: 14),
                        SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        SizedBox(width: 8),
                      ],
                      Text(
                        _timeAgo(activity['addedAt']),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(int millis) {
  var diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(millis),
  );
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
