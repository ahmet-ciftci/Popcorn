import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/social_service.dart';
import '../../constants/api_constants.dart';
import '../movie_detail/movie_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.uid,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final SocialService _socialService = SocialService();
  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  late TabController _tabController;

  bool _isFollowing = false;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, String> _visibility = {};

  List<Map<String, dynamic>> _watched = [];
  List<Map<String, dynamic>> _watchlist = [];
  List<Map<String, dynamic>> _lists = [];
  List<Map<String, dynamic>?> _favorites = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final profile = await _socialService.getUserProfile(widget.uid);
    final isFollowing = await _socialService.isFollowing(widget.uid);

    final visibilityData = profile?['visibility'];
    final visibility = visibilityData != null
        ? Map<String, String>.from(visibilityData)
        : <String, String>{};

    final watchedVisible = _canSee(visibility['Watched List'] ?? 'Everyone', isFollowing);
    final watchlistVisible = _canSee(visibility['Watchlist'] ?? 'Everyone', isFollowing);
    final listsVisible = _canSee(visibility['Custom Lists'] ?? 'Everyone', isFollowing);
    final favoritesVisible = _canSee(visibility['Favorites'] ?? 'Everyone', isFollowing);

    List<Map<String, dynamic>> watched = [];
    List<Map<String, dynamic>> watchlist = [];
    List<Map<String, dynamic>> lists = [];
    List<Map<String, dynamic>?> favorites = [null, null, null, null];

    if (watchedVisible) watched = await _socialService.getUserWatched(widget.uid);
    if (watchlistVisible) watchlist = await _socialService.getUserWatchlist(widget.uid);
    if (listsVisible) lists = await _socialService.getUserLists(widget.uid);
    if (favoritesVisible) favorites = await _socialService.getUserFavorites(widget.uid);

    setState(() {
      _profile = profile;
      _isFollowing = isFollowing;
      _visibility = visibility;
      _watched = watched;
      _watchlist = watchlist;
      _lists = lists;
      _favorites = favorites;
      _loading = false;
    });
  }

  bool _canSee(String setting, bool isFollowing) {
    if (setting == 'Everyone') return true;
    if (setting == 'Friends' && isFollowing) return true;
    return false;
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await _socialService.unfollow(widget.uid);
    } else {
      await _socialService.follow(widget.uid);
    }
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    final username = _profile?['username'] ?? widget.username;
    final followersCount = _profile?['followersCount'] ?? 0;
    final followingCount = _profile?['followingCount'] ?? 0;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    final watchedVisible = _canSee(_visibility['Watched List'] ?? 'Everyone', _isFollowing);
    final watchlistVisible = _canSee(_visibility['Watchlist'] ?? 'Everyone', _isFollowing);
    final listsVisible = _canSee(_visibility['Custom Lists'] ?? 'Everyone', _isFollowing);
    final favoritesVisible = _canSee(_visibility['Favorites'] ?? 'Everyone', _isFollowing);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            slivers: [

              // top bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(username,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(CupertinoIcons.chevron_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // avatar + stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFE50914),
                        child: Text(initial,
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
                              label: 'watched',
                              value: watchedVisible ? '${_watched.length}' : '—',
                            ),
                            _StatItem(label: 'followers', value: '$followersCount'),
                            _StatItem(label: 'following', value: '$followingCount'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // follow button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: _toggleFollow,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _isFollowing
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFE50914),
                        borderRadius: BorderRadius.circular(10),
                        border: _isFollowing
                            ? Border.all(color: Colors.grey.shade800)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _isFollowing ? 'Following' : 'Follow',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // favorites
              SliverToBoxAdapter(child: _SectionHeader(title: 'favorites')),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: favoritesVisible
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(4, (i) {
                      final fav = _favorites[i];
                      final posterPath = fav?['posterPath'] as String?;
                      final posterUrl =
                      (posterPath != null && posterPath.isNotEmpty)
                          ? 'https://image.tmdb.org/t/p/w185$posterPath'
                          : '';

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: fav != null && posterUrl.isNotEmpty
                                  ? Image.network(posterUrl, fit: BoxFit.cover)
                                  : Container(
                                color: const Color(0xFF1A1A1A),
                                child: Icon(Icons.movie_outlined,
                                    color: Colors.grey.shade700, size: 20),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )
                    : _PrivateSection(
                  message: 'Favorites are private',
                  isFollowing: _isFollowing,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // tabs
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

              // tab content
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // watched
                    watchedVisible
                        ? _MovieGrid(
                      movies: _watched,
                      emptyMessage: 'no watched films yet',
                    )
                        : _PrivateSection(
                      message: 'Watched list is private',
                      isFollowing: _isFollowing,
                    ),

                    // lists
                    listsVisible
                        ? _ListsTab(lists: _lists)
                        : _PrivateSection(
                      message: 'Lists are private',
                      isFollowing: _isFollowing,
                    ),

                    // watchlist
                    watchlistVisible
                        ? _MovieGrid(
                      movies: _watchlist,
                      emptyMessage: 'no watchlist yet',
                    )
                        : _PrivateSection(
                      message: 'Watchlist is private',
                      isFollowing: _isFollowing,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Movie Grid ──

class _MovieGrid extends StatelessWidget {
  final List<Map<String, dynamic>> movies;
  final String emptyMessage;

  const _MovieGrid({required this.movies, required this.emptyMessage});

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
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: movies.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 2 / 3,
        ),
        itemBuilder: (context, index) {
          final movie = movies[index];
          final posterPath = movie['posterPath'] ?? '';
          final posterUrl = posterPath.isNotEmpty
              ? ApiConstants.imageBaseUrl + posterPath
              : '';

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MovieDetailScreen(movieId: movie['tmdbId'] as int),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: posterUrl.isNotEmpty
                  ? Image.network(posterUrl, fit: BoxFit.cover)
                  : Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.movie_outlined,
                    color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Lists Tab ──

class _ListsTab extends StatelessWidget {
  final List<Map<String, dynamic>> lists;

  const _ListsTab({required this.lists});

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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
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
          );
        },
      ),
    );
  }
}

// ── Private Section ──

class _PrivateSection extends StatelessWidget {
  final String message;
  final bool isFollowing;

  const _PrivateSection({required this.message, required this.isFollowing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.lock, color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 10),
            Text(
              isFollowing ? message : 'Follow to see this content',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar Delegate ──

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
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

// ── Reusable Widgets ──

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
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
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
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0)),
          const SizedBox(width: 10),
          Expanded(
              child: Container(height: 0.5, color: const Color(0xFF2A2A2A))),
        ],
      ),
    );
  }
}