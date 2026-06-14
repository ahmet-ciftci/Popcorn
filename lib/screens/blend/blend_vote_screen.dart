import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/api_constants.dart';
import '../../services/blend_service.dart';

class BlendVoteScreen extends StatefulWidget {
  final String sessionId;

  BlendVoteScreen({super.key, required this.sessionId});

  @override
  State<BlendVoteScreen> createState() => _BlendVoteScreenState();
}

class _BlendVoteScreenState extends State<BlendVoteScreen> {
  List<Map<String, dynamic>> _movies = [];
  int _index = 0;
  bool _loading = true;
  bool _hasError = false;
  BlendService _blendService = BlendService();

  @override
  void initState() {
    super.initState();
    _loadVoting();
  }

  void _loadVoting() async {
    try {
      var pool = await _blendService.getPool(widget.sessionId);
      var votes = await _blendService.getVotes(widget.sessionId);

      var uid = FirebaseAuth.instance.currentUser!.uid;

      // tmdbIds I've already voted on (getVotes returns everyone's votes)
      var votedIds = <int>{};
      for (var v in votes) {
        if (v['uid'] == uid) {
          votedIds.add(v['tmdbId'] as int);
        }
      }

      // only keep the movies I haven't voted on yet
      var remaining = <Map<String, dynamic>>[];
      for (var movie in pool) {
        if (!votedIds.contains(movie['tmdbId'])) {
          remaining.add(movie);
        }
      }

      setState(() {
        _movies = remaining;
        _loading = false;
      });
    } catch (e) {
      print('Error loading voting: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _vote(bool isYes) async {
    var movie = _movies[_index];
    var tmdbId = movie['tmdbId'] as int;

    try {
      await _blendService.vote(widget.sessionId, tmdbId, isYes);
    } catch (e) {
      print('Error voting: $e');
    }

    setState(() {
      _index++;
    });
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
          'Voting',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
                  _index = 0;
                });
                _loadVoting();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    // no movies left (voted on all, or pool is empty)
    if (_index >= _movies.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFFE50914), size: 64),
            SizedBox(height: 16),
            Text(
              "You've voted on all the movies",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              child: Text('Back to session'),
            ),
          ],
        ),
      );
    }

    var movie = _movies[_index];
    String posterPath = movie['posterPath'] ?? '';

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: posterPath.isNotEmpty
                ? Image.network(
                    ApiConstants.imageBaseUrl + posterPath,
                    width: 220,
                    height: 330,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 220,
                    height: 330,
                    color: Color(0xFF222222),
                    child: Icon(Icons.movie_outlined, color: Colors.grey, size: 48),
                  ),
          ),
          SizedBox(height: 20),
          Text(
            movie['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          // no / yes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _vote(false),
                icon: Icon(Icons.close),
                color: Colors.white,
                iconSize: 36,
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFF1C1C1E),
                  padding: EdgeInsets.all(18),
                ),
              ),
              SizedBox(width: 48),
              IconButton(
                onPressed: () => _vote(true),
                icon: Icon(Icons.favorite),
                color: Color(0xFFE50914),
                iconSize: 36,
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFF1C1C1E),
                  padding: EdgeInsets.all(18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
