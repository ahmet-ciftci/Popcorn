import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/social_service.dart';
import '../../constants/api_constants.dart';

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

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SocialService _socialService = SocialService();
  final _db = FirebaseFirestore.instance;
  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  bool _isFollowing = false;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  Map<String, String> _visibility = {};

  List<Map<String, dynamic>> _watched = [];
  List<Map<String, dynamic>?> _favorites = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // load profile, follow status and visibility settings
    final profile = await _socialService.getUserProfile(widget.uid);
    final isFollowing = await _socialService.isFollowing(widget.uid);

    // load visibility settings
    final visibilityData = profile?['visibility'];
    final visibility = visibilityData != null
        ? Map<String, String>.from(visibilityData)
        : <String, String>{};

    // check if current user can see watched list
    final watchedVisible = _canSee(
      visibility['Watched List'] ?? 'Everyone',
      isFollowing,
    );

    // check if current user can see favorites
    final favoritesVisible = _canSee(
      visibility['Favorites'] ?? 'Everyone',
      isFollowing,
    );

    List<Map<String, dynamic>> watched = [];
    List<Map<String, dynamic>?> favorites = [null, null, null, null];

    if (watchedVisible) {
      watched = await _socialService.getUserWatched(widget.uid);
    }

    if (favoritesVisible) {
      favorites = await _socialService.getUserFavorites(widget.uid);
    }

    setState(() {
      _profile = profile;
      _isFollowing = isFollowing;
      _visibility = visibility;
      _watched = watched;
      _favorites = favorites;
      _loading = false;
    });
  }

  // check if current user can see content based on privacy setting
  bool _canSee(String setting, bool isFollowing) {
    if (setting == 'Everyone') return true;
    if (setting == 'Friends' && isFollowing) return true;
    if (setting == 'Only Me') return false;
    return false;
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await _socialService.unfollow(widget.uid);
    } else {
      await _socialService.follow(widget.uid);
    }

    // reload everything from Firestore
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

    final watchedVisible = _canSee(
      _visibility['Watched List'] ?? 'Everyone',
      _isFollowing,
    );
    final favoritesVisible = _canSee(
      _visibility['Favorites'] ?? 'Everyone',
      _isFollowing,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: ScrollConfiguration(
          behavior:
          ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            slivers: [

              // top bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            CupertinoIcons.chevron_back,
                            color: Colors.white,
                            size: 20,
                          ),
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
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              label: 'watched',
                              value: watchedVisible
                                  ? '${_watched.length}'
                                  : '—',
                            ),
                            _StatItem(
                              label: 'followers',
                              value: '$followersCount',
                            ),
                            _StatItem(
                              label: 'following',
                              value: '$followingCount',
                            ),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // favorites section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'favorites'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: favoritesVisible
                    ? Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(4, (i) {
                      final fav = _favorites[i];
                      final posterPath =
                      fav?['posterPath'] as String?;
                      final posterUrl = (posterPath != null &&
                          posterPath.isNotEmpty)
                          ? 'https://image.tmdb.org/t/p/w185$posterPath'
                          : '';

                      return Expanded(
                        child: Padding(
                          padding:
                          EdgeInsets.only(right: i < 3 ? 8 : 0),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: fav != null && posterUrl.isNotEmpty
                                  ? Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                              )
                                  : Container(
                                color: const Color(0xFF1A1A1A),
                                child: Icon(
                                  Icons.movie_outlined,
                                  color: Colors.grey.shade700,
                                  size: 20,
                                ),
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

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // watched section
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'watched'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // watched grid or private notice
              if (!watchedVisible)
                SliverToBoxAdapter(
                  child: _PrivateSection(
                    message: 'Watched list is private',
                    isFollowing: _isFollowing,
                  ),
                )
              else if (_watched.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'no movies watched yet',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final movie = _watched[index];
                        final posterPath = movie['posterPath'] ?? '';
                        final posterUrl = posterPath.isNotEmpty
                            ? ApiConstants.imageBaseUrl + posterPath
                            : '';

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: posterUrl.isNotEmpty
                              ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            color: const Color(0xFF1A1A1A),
                            child: const Icon(
                              Icons.movie_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      childCount: _watched.length,
                    ),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 2 / 3,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private section notice ──

class _PrivateSection extends StatelessWidget {
  final String message;
  final bool isFollowing;

  const _PrivateSection({
    required this.message,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.lock,
                color: Colors.grey.shade600, size: 18),
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

// ── Reusable widgets ──

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
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
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
                height: 0.5, color: const Color(0xFF2A2A2A)),
          ),
        ],
      ),
    );
  }
}