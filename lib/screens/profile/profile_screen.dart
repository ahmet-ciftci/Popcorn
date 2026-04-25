import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../settings/settings_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/tmdb_service.dart';
import '../../models/movie.dart';
import '../movie_detail/movie_detail_screen.dart';
import 'list_detail_screen.dart';
import 'edit_profile_sheet.dart';
import 'share_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();

  User? get _user => FirebaseAuth.instance.currentUser;
  String get _username => _user?.displayName ?? 'username';
  String get _displayName => _user?.displayName ?? 'User';
  String get _initials =>
      _username.isNotEmpty ? _username[0].toUpperCase() : '?';

  late TabController _tabController;

  List<Map<String, dynamic>> _watched = [];
  List<Map<String, dynamic>> _watchlist = [];
  List<Map<String, dynamic>> _lists = [];
  // 4 slot, boş = null
  List<Map<String, dynamic>?> _favorites = [null, null, null, null];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _firestoreService.getWatchedList(),
      _firestoreService.getWatchlist(),
      _firestoreService.getLists(),
      _firestoreService.getFavorites(),
    ]);
    if (mounted) {
      setState(() {
        _watched = results[0] as List<Map<String, dynamic>>;
        _watchlist = results[1] as List<Map<String, dynamic>>;
        _lists = results[2] as List<Map<String, dynamic>>;
        _favorites = results[3] as List<Map<String, dynamic>?>;
        _loading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final favorites = await _firestoreService.getFavorites();
    if (mounted) setState(() => _favorites = favorites);
  }

  // + ikonuna basınca → boş slotu bul, sheet aç
  void _onAddFavorite() {
    final emptySlot = _favorites.indexWhere((f) => f == null);
    if (emptySlot == -1) return; // 4 slot dolu
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FavoritesSearchSheet(
        slot: emptySlot,
        onAdded: _loadFavorites,
      ),
    );
  }

  // Uzun basınca → kaldır
  Future<void> _onRemoveFavorite(int slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Remove from favorites?',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.removeFromFavorites(slot);
      _loadFavorites();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior:
          ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFE50914),
                    indicatorWeight: 2,
                    labelColor: const Color(0xFFE50914),
                    unselectedLabelColor: Colors.grey.shade500,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Watched'),
                      Tab(text: 'Lists'),
                      Tab(text: 'Watchlist'),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: _loading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE50914)))
                    : TabBarView(
                  controller: _tabController,
                  children: [
                    _MovieGridTab(
                        movies: _watched,
                        emptyMessage: 'no watched films yet',
                        label: 'FILMS'),
                    _ListsTab(lists: _lists, onListsChanged: _loadAll),
                    _MovieGridTab(
                        movies: _watchlist,
                        emptyMessage: 'no watchlist yet',
                        label: 'FILMS'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top bar ──
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(_username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3)),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),

        // ── Avatar + stats ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFFE50914),
                child: Text(_initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        label: 'watched', value: '${_watched.length}'),
                    const _StatItem(label: 'followers', value: '0'),
                    const _StatItem(label: 'following', value: '0'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(_displayName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),

        const SizedBox(height: 14),

        // ── Buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _OutlineButton(
                  label: 'Edit Profile',
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const EditProfileSheet(),
                    );
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineButton(
                  label: 'Share Profile',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const ShareProfileSheet(),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Favorites ──
        _SectionHeader(title: 'favorites'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(4, (i) {
              final fav = _favorites[i];
              final hasMovie = fav != null;
              final posterPath = fav?['posterPath'] as String?;
              final posterUrl = (posterPath != null && posterPath.isNotEmpty)
                  ? 'https://image.tmdb.org/t/p/w185$posterPath'
                  : '';

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: hasMovie
                    // ── Dolu slot: tıkla → değiştir, uzun bas → kaldır ──
                        ? GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _FavoritesSearchSheet(
                          slot: i,
                          onAdded: _loadFavorites,
                        ),
                      ),
                      onLongPress: () => _onRemoveFavorite(i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: posterUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: const Color(0xFF1A1A1A)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF1A1A1A),
                            child: Icon(Icons.movie,
                                color: Colors.grey.shade700),
                          ),
                        )
                            : Container(
                            color: const Color(0xFF1A1A1A),
                            child: Icon(Icons.movie,
                                color: Colors.grey.shade700)),
                      ),
                    )
                    // ── Boş slot: + ikonu, sadece ilk boşa tıklanabilir ──
                        : GestureDetector(
                      onTap: _favorites.indexWhere((f) => f == null) == i
                          ? _onAddFavorite
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF2A2A2A),
                              width: 0.5),
                        ),
                        child: _favorites.indexWhere((f) => f == null) == i
                            ? Icon(Icons.add,
                            color: Colors.grey.shade700, size: 20)
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }


}

// ─────────────────────────────────────────────
// Favorites Search Sheet
// ─────────────────────────────────────────────
class _FavoritesSearchSheet extends StatefulWidget {
  final int slot;
  final VoidCallback onAdded;

  const _FavoritesSearchSheet({required this.slot, required this.onAdded});

  @override
  State<_FavoritesSearchSheet> createState() => _FavoritesSearchSheetState();
}

class _FavoritesSearchSheetState extends State<_FavoritesSearchSheet> {
  final _tmdbService = TMDBService();
  final _firestoreService = FirestoreService();
  final _controller = TextEditingController();

  List<Movie> _results = [];
  bool _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _tmdbService.searchMovies(query, 1);
    if (mounted) setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _select(Movie movie) async {
    await _firestoreService.addToFavorites(movie, widget.slot);
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // drag handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Text('add to favorites',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),

          const SizedBox(height: 14),

          // search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: const Color(0xFFE50914),
                decoration: InputDecoration(
                  hintText: 'search films...',
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => _search(val),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Container(height: 0.5, color: const Color(0xFF2C2C2E)),

          // results
          Expanded(
            child: _searching
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE50914)))
                : _results.isEmpty
                ? Center(
              child: Text(
                _controller.text.isEmpty
                    ? 'type to search...'
                    : 'no results',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14),
              ),
            )
                : ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(scrollbars: false),
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final movie = _results[index];
                  final posterUrl = movie.posterPath.isNotEmpty
                      ? 'https://image.tmdb.org/t/p/w92${movie.posterPath}'
                      : '';
                  final year = movie.releaseDate.isNotEmpty
                      ? movie.releaseDate.split('-')[0]
                      : '';

                  return GestureDetector(
                    onTap: () => _select(movie),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // mini poster
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: posterUrl.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: posterUrl,
                              width: 36,
                              height: 54,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                width: 36, height: 54,
                                color: const Color(0xFF2C2C2E),
                              ),
                              errorWidget: (_, __, ___) =>
                                  Container(
                                    width: 36, height: 54,
                                    color: const Color(0xFF2C2C2E),
                                    child: Icon(Icons.movie,
                                        color: Colors.grey.shade700,
                                        size: 16),
                                  ),
                            )
                                : Container(
                              width: 36, height: 54,
                              color: const Color(0xFF2C2C2E),
                              child: Icon(Icons.movie,
                                  color: Colors.grey.shade700,
                                  size: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(movie.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                if (year.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(year,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11)),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.add_circle_outline,
                              color: const Color(0xFFE50914),
                              size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Movie Grid Tab
// ─────────────────────────────────────────────
class _MovieGridTab extends StatelessWidget {
  final List<Map<String, dynamic>> movies;
  final String emptyMessage;
  final String label;

  const _MovieGridTab({
    required this.movies,
    required this.emptyMessage,
    required this.label,
  });

  String _posterUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w185$path';
  }

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${movies.length} $label',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _AllMoviesScreen(movies: movies, title: label),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE50914)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.grid_view_rounded,
                              color: Color(0xFFE50914), size: 13),
                          SizedBox(width: 5),
                          Text('See All',
                              style: TextStyle(
                                  color: Color(0xFFE50914), fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final movie = movies[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(
                            movieId: movie['tmdbId'] as int),
                      ),
                    ),
                    child: _PosterCard(
                      posterUrl: _posterUrl(movie['posterPath']),
                      rating: movie['rating'] as int?,
                    ),
                  );
                },
                childCount: movies.length,
              ),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 2 / 3,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// See All → Full Screen
// ─────────────────────────────────────────────
class _AllMoviesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> movies;
  final String title;

  const _AllMoviesScreen({required this.movies, required this.title});

  String _posterUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w342$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${movies.length} ${title.toLowerCase()}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
      body: ScrollConfiguration(
        behavior:
        ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: movies.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2 / 3,
          ),
          itemBuilder: (context, index) {
            final movie = movies[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MovieDetailScreen(movieId: movie['tmdbId'] as int),
                ),
              ),
              child: _PosterCard(
                posterUrl: _posterUrl(movie['posterPath']),
                rating: movie['rating'] as int?,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Lists Tab
// ─────────────────────────────────────────────
class _ListsTab extends StatelessWidget {
  final List<Map<String, dynamic>> lists;
  final VoidCallback onListsChanged;

  const _ListsTab({required this.lists, required this.onListsChanged});

  @override
  Widget build(BuildContext context) {
    if (lists.isEmpty) {
      return Center(
        child: Text('no lists yet',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: lists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final list = lists[index];
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => ListDetailScreen(
                    listId: list['id'],
                    listName: list['name'] ?? '',
                  ),
                ),
              );
              if (result != null) onListsChanged();
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.list,
                        color: Color(0xFFE50914), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(list['name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade700, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Poster Card
// ─────────────────────────────────────────────
class _PosterCard extends StatelessWidget {
  final String posterUrl;
  final int? rating;

  const _PosterCard({required this.posterUrl, this.rating});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          posterUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: posterUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFE50914), strokeWidth: 1.5),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: const Color(0xFF1A1A1A),
              child: Icon(Icons.image_not_supported,
                  color: Colors.grey.shade700, size: 16),
            ),
          )
              : Container(
            color: const Color(0xFF1A1A1A),
            child: Icon(Icons.movie,
                color: Colors.grey.shade700, size: 16),
          ),
          if (rating != null && rating! > 0)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < rating! ? Icons.star : Icons.star_border,
                      color: i < rating!
                          ? const Color(0xFFE50914)
                          : Colors.transparent,
                      size: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pinned Tab Bar Delegate
// ─────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          Container(height: 0.5, color: const Color(0xFF2A2A2A)),
          tabBar,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0)),
          const SizedBox(width: 10),
          Expanded(
              child:
              Container(height: 0.5, color: const Color(0xFF2A2A2A))),
        ],
      ),
    );
  }
}