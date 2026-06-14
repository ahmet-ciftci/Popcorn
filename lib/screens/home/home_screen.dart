import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/tmdb_service.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../mood/mood_browse_screen.dart';
import '../feed/feed_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _trending = [];
  List<Movie> _popular = [];
  bool _loading = true;
  bool _hasError = false;
  TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() async {
    try {
      var trending = await _tmdbService.getTrendingMoviesWeek();
      var popular = await _tmdbService.getPopularMovies();

      if (trending == null || popular == null) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
        return;
      }

      setState(() {
        _trending = trending;
        _popular = popular;
        _loading = false;
      });
    } catch (e) {
      print('Error loading browse: $e');
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
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Browse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.dynamic_feed, color: Colors.white),
                        tooltip: 'Feed',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeedScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.auto_awesome, color: Colors.white),
                        tooltip: 'Moods',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MoodBrowseScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // body
            Expanded(child: _buildBody()),
          ],
        ),
      ),
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
                _loadAll();
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MovieRow(title: 'Trending This Week', movies: _trending),
          SizedBox(height: 16),
          _MovieRow(title: 'Popular', movies: _popular),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MovieRow extends StatelessWidget {
  final String title;
  final List<Movie> movies;

  const _MovieRow({required this.title, required this.movies});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return _PosterCard(movie: movies[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  final Movie movie;

  const _PosterCard({required this.movie});

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
      child: Container(
        width: 120,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterPath.isNotEmpty
                  ? Image.network(
                movie.getFullPosterUrl(),
                width: 120,
                height: 180,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 120,
                height: 180,
                color: Color(0xFF222222),
                child: Icon(Icons.movie_outlined, color: Colors.grey),
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
      ),
    );
  }
}
