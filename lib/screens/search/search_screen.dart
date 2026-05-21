import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/tmdb_service.dart';
import '../../services/social_service.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  List<Movie> _movieResults = [];
  bool _movieLoading = false;
  bool _movieHasSearched = false;

  List<Map<String, dynamic>> _peopleResults = [];
  bool _peopleLoading = false;
  bool _peopleHasSearched = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  final TMDBService _tmdbService = TMDBService();
  final SocialService _socialService = SocialService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // when tab changes, search with the same query
    _tabController.addListener(() {
      final query = _searchController.text.trim();
      if (query.isEmpty) return;
      if (_tabController.index == 0 && !_movieHasSearched) {
        _searchMovies(query);
      } else if (_tabController.index == 1 && !_peopleHasSearched) {
        _searchPeople(query);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _movieResults = [];
        _movieHasSearched = false;
        _movieLoading = false;
        _peopleResults = [];
        _peopleHasSearched = false;
        _peopleLoading = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_tabController.index == 0) {
        _searchMovies(query.trim());
      } else {
        _searchPeople(query.trim());
      }
    });
  }

  Future<void> _searchMovies(String query) async {
    setState(() => _movieLoading = true);
    final movies = await _tmdbService.searchMovies(query, 1);
    setState(() {
      _movieResults = movies;
      _movieHasSearched = true;
      _movieLoading = false;
    });
  }

  Future<void> _searchPeople(String query) async {
    setState(() => _peopleLoading = true);
    final people = await _socialService.searchUsers(query);
    setState(() {
      _peopleResults = people;
      _peopleHasSearched = true;
      _peopleLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE50914)),
                  ),
                ),
              ),
            ),

            // Movies / People tabs
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE50914),
              indicatorWeight: 2,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Movies'),
                Tab(text: 'People'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMoviesTab(),
                  _buildPeopleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Movies tab ──

  Widget _buildMoviesTab() {
    if (_movieLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    if (!_movieHasSearched) {
      return _buildEmptyState(Icons.movie_outlined, 'Search for a movie');
    }

    if (_movieResults.isEmpty) {
      return _buildEmptyState(Icons.movie_outlined, 'No movies found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _movieResults.length,
      itemBuilder: (context, index) {
        final movie = _movieResults[index];
        final year = movie.releaseDate.length >= 4
            ? movie.releaseDate.split('-')[0]
            : '';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movieId: movie.id),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // poster
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
                    color: const Color(0xFF222222),
                    child: const Icon(Icons.movie_outlined,
                        color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (year.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(year,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFE50914), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            movie.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
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

  // ── People tab ──

  Widget _buildPeopleTab() {
    if (_peopleLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    if (!_peopleHasSearched) {
      return _buildEmptyState(Icons.person_outline, 'Search for people');
    }

    if (_peopleResults.isEmpty) {
      return _buildEmptyState(Icons.person_outline, 'No users found');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _peopleResults.length,
      itemBuilder: (context, index) {
        final user = _peopleResults[index];
        final username = user['username'] ?? '';
        final initial =
        username.isNotEmpty ? username[0].toUpperCase() : '?';
        final followersCount = user['followersCount'] ?? 0;

        // tapping the card goes to that user's profile
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(
                uid: user['uid'],
                username: username,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE50914),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // username + followers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$followersCount followers',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // arrow icon — shows the card is tappable
                Icon(Icons.chevron_right,
                    color: Colors.grey.shade700, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }
}