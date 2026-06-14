import 'package:flutter/material.dart';
import '../../constants/api_constants.dart';
import '../../services/blend_service.dart';

class BlendResultsScreen extends StatefulWidget {
  final String sessionId;

  BlendResultsScreen({super.key, required this.sessionId});

  @override
  State<BlendResultsScreen> createState() => _BlendResultsScreenState();
}

class _BlendResultsScreenState extends State<BlendResultsScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _hasError = false;
  BlendService _blendService = BlendService();

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  void _loadResults() async {
    try {
      // already sorted by yesCount desc, just render as-is
      var results = await _blendService.getRankedResults(widget.sessionId);

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      print('Error loading results: $e');
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
          'Results',
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
                });
                _loadResults();
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

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No movies to show yet, add some to the pool first',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return _ResultTile(movie: _results[index], isTop: index == 0);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Map<String, dynamic> movie;
  final bool isTop;

  const _ResultTile({required this.movie, required this.isTop});

  @override
  Widget build(BuildContext context) {
    String posterPath = movie['posterPath'] ?? '';
    var yesCount = movie['yesCount'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        // highlight the current winner
        border: isTop ? Border.all(color: Color(0xFFE50914)) : null,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: posterPath.isNotEmpty
                ? Image.network(
                    ApiConstants.imageBaseUrl + posterPath,
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 75,
                    color: Color(0xFF222222),
                    child: Icon(Icons.movie_outlined, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              movie['title'] ?? '',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.favorite, color: Color(0xFFE50914), size: 16),
          SizedBox(width: 4),
          Text(
            '$yesCount',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
