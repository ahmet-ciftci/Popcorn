import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/tmdb_service.dart';
import '../../screens/movie_detail/movie_action_sheet.dart';

class MovieDetailScreen extends StatefulWidget {
  int movieId;

  MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Movie _movie = Movie(
    id: 0,
    title: '',
    overview: '',
    posterPath: '',
    backdropPath: '',
    releaseDate: '',
    voteAverage: 0.0,
    genreIds: [],
  );
  bool _loading = true;
  bool _hasError = false;
  TMDBService _tmdbService = TMDBService();

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  void _loadMovie() async {
    try {
      var result = await _tmdbService.getMovieDetails(widget.movieId);
      if (result != null) {
        setState(() {
          _movie = result;
          _loading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading movie: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
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
                  _loadMovie();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE50914),
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,  actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => MovieActionSheet(movie: _movie),
            );
          },
        ),
      ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // backdrop image
            Image.network(
              _movie.getFullBackdropUrl(),
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            // poster + info row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _movie.getFullPosterUrl(),
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 16),
                  // info column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _movie.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_movie.releaseDate.isNotEmpty)
                          Text(
                            '(${_movie.releaseDate.split('-')[0]})',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Color(0xFFE50914), size: 18),
                            SizedBox(width: 4),
                            Text(
                              _movie.voteAverage.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${_movie.runtime} min',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                        if (_movie.director.isNotEmpty) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.movie_outlined, color: Colors.grey, size: 16),
                              SizedBox(width: 4),
                              Text(
                                _movie.director,
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                        if (_movie.genres.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _movie.genres.map((genre) {
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFE50914).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Color(0xFFE50914).withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  genre,
                                  style: TextStyle(
                                    color: Color(0xFFE50914),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // tagline
            if (_movie.tagline.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  '"${_movie.tagline}"',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // overview section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _movie.overview,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.5,
                    ),
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
