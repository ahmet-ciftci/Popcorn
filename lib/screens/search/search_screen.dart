import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/tmdb_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Movie> _results = [];
  bool _loading = false;
  bool _hasSearched = false;
  TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  TMDBService _tmdbService = TMDBService();

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() {
          _results = [];
          _hasSearched = false;
          _loading = false;
        });
        return;
      }
      _searchMovies(query.trim());
    });
  }

  void _searchMovies(String query) async {
    setState(() {
      _loading = true;
    });

    var movies = await _tmdbService.searchMovies(query, 1);
    setState(() {
      _results = movies;
      _hasSearched = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // search bar
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search for a movie...',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFE50914)),
                  ),
                ),
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

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.grey, size: 64),
            SizedBox(height: 16),
            Text(
              'Search for a movie',
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
              'No results found',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        var movie = _results[index];

        // get year from release date
        String year = '';
        if (movie.releaseDate.length >= 4) {
          year = movie.releaseDate.split('-')[0];
        }

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
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // poster thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterPath.isNotEmpty
                      ? Image.network(
                          movie.getFullPosterUrl(),
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
                // movie info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (year.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          year,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Color(0xFFE50914), size: 16),
                          SizedBox(width: 4),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: TextStyle(color: Colors.white, fontSize: 14),
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
      },
    );
  }
}
