import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/tmdb_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class MoodResultsScreen extends StatefulWidget {
  final String moodName;
  final String moodEmoji;
  final List<int> genreIds;
  final String sortBy;

  MoodResultsScreen({
    super.key,
    required this.moodName,
    required this.moodEmoji,
    required this.genreIds,
    required this.sortBy,
  });

  @override
  State<MoodResultsScreen> createState() => _MoodResultsScreenState();
}

class _MoodResultsScreenState extends State<MoodResultsScreen> {
  List<Movie> _movies = [];
  bool _loading = true;
  bool _hasError = false;
  TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() async {
    try {
      var movies = await _tmdbService.discoverMovies(
        widget.genreIds,
        widget.sortBy,
      );

      if (movies == null) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _movies = movies;
        _loading = false;
      });
    } catch (e) {
      print('Error loading mood results: $e');
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
        title: Row(
          children: [
            Text(
              widget.moodEmoji,
              style: TextStyle(fontSize: 22),
            ),
            SizedBox(width: 8),
            Text(
              widget.moodName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                _loadMovies();
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

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No movies found for this mood.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.6,
      ),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        return _GridPosterCard(movie: _movies[index]);
      },
    );
  }
}

class _GridPosterCard extends StatelessWidget {
  final Movie movie;

  const _GridPosterCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(movieId: movie.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterPath.isNotEmpty
                  ? Image.network(
                      movie.getFullPosterUrl(),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Color(0xFF222222),
                      child: Icon(Icons.movie_outlined, color: Colors.grey),
                    ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            movie.title,
            style: TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}