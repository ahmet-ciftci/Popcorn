import 'package:flutter/material.dart';
import '../../models/movie.dart';
import '../../services/firestore_service.dart';

class MovieActionSheet extends StatefulWidget {
  final Movie movie;

  const MovieActionSheet({super.key, required this.movie});

  @override
  State<MovieActionSheet> createState() => _MovieActionSheetState();
}

class _MovieActionSheetState extends State<MovieActionSheet> {
  final _firestoreService = FirestoreService();

  bool _watched = false;
  bool _liked = false;
  bool _inWatchlist = false;
  int _rating = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final watched = await _firestoreService.isWatched(widget.movie.id);
    final inWatchlist = await _firestoreService.isInWatchlist(widget.movie.id);
    final rating = await _firestoreService.getRating(widget.movie.id);
    setState(() {
      _watched = watched;
      _inWatchlist = inWatchlist;
      _rating = rating ?? 0;
      _loading = false;
    });
  }

  Future<void> _toggleWatched() async {
    final newVal = !_watched;
    setState(() => _watched = newVal);
    if (newVal) {
      await _firestoreService.addToWatched(widget.movie,
          rating: _rating > 0 ? _rating : null);
    } else {
      await _firestoreService.removeFromWatched(widget.movie.id);
    }
  }

  Future<void> _toggleWatchlist() async {
    final newVal = !_inWatchlist;
    setState(() => _inWatchlist = newVal);
    if (newVal) {
      await _firestoreService.addToWatchlist(widget.movie);
    } else {
      await _firestoreService.removeFromWatchlist(widget.movie.id);
    }
  }

  Future<void> _setRating(int r) async {
    setState(() => _rating = r);
    if (_watched) {
      await _firestoreService.addToWatched(widget.movie, rating: r);
    }
  }

  Future<void> _onDone() async {
    if (_watched) {
      await _firestoreService.addToWatched(widget.movie,
          rating: _rating > 0 ? _rating : null);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // film adı + yıl
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.movie.releaseDate.isNotEmpty
                      ? widget.movie.releaseDate.split('-')[0]
                      : '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: const Color(0xFF2C2C2E)),

          // Watch / Like / Watchlist
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _IconAction(
                  icon: Icons.remove_red_eye_outlined,
                  activeIcon: Icons.remove_red_eye,
                  label: _watched ? 'Watched' : 'Watch',
                  active: _watched,
                  onTap: _toggleWatched,
                ),
                _IconAction(
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  label: 'Like',
                  active: _liked,
                  onTap: () => setState(() => _liked = !_liked),
                ),
                _IconAction(
                  icon: Icons.bookmark_border,
                  activeIcon: Icons.bookmark,
                  label: 'Watchlist',
                  active: _inWatchlist,
                  onTap: _toggleWatchlist,
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: const Color(0xFF2C2C2E)),

          // Yıldız rating
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  'RATE',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => _setRating(i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _rating ? Icons.star : Icons.star_border,
                          color: i < _rating
                              ? const Color(0xFFE50914)
                              : const Color(0xFF3A3A3C),
                          size: 34,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          Container(height: 0.5, color: const Color(0xFF2C2C2E)),

          ListTile(
            title: const Text('Review or log...',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade700),
            onTap: () {},
          ),

          Container(height: 0.5, color: const Color(0xFF2C2C2E)),

          ListTile(
            title: const Text('Add to list...',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade700),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => _AddToListSheet(movie: widget.movie),
              );
            },
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _onDone,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Done',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFE50914) : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(active ? activeIcon : icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Add to list bottom sheet ──
class _AddToListSheet extends StatefulWidget {
  final Movie movie;
  const _AddToListSheet({required this.movie});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    final lists = await _firestoreService.getLists();
    setState(() {
      _lists = lists;
      _loading = false;
    });
  }

  Future<void> _addToList(String listId, String listName) async {
    await _firestoreService.addMovieToList(listId, widget.movie);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to $listName'),
          backgroundColor: const Color(0xFF1E1E1E),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createNewList() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('New List',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: const Color(0xFFE50914),
          decoration: InputDecoration(
            hintText: 'List name',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            filled: true,
            fillColor: const Color(0xFF111111),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(0xFFE50914), width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final listId =
                await _firestoreService.createList(controller.text.trim());
                if (mounted) Navigator.pop(context);
                await _addToList(listId, controller.text.trim());
              }
            },
            child: const Text('Create',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A3C),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text('Add to List',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Container(height: 0.5, color: const Color(0xFF2C2C2E)),
          ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              const Icon(Icons.add, color: Color(0xFFE50914), size: 18),
            ),
            title: const Text('New List',
                style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            onTap: _createNewList,
          ),
          Container(height: 0.5, color: const Color(0xFF2C2C2E)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            )
          else if (_lists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No lists yet',
                  style:
                  TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            )
          else
            ...List.generate(_lists.length, (i) {
              final list = _lists[i];
              final isLast = i == _lists.length - 1;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.list,
                          color: Colors.grey.shade500, size: 18),
                    ),
                    title: Text(list['name'] ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                    onTap: () => _addToList(list['id'], list['name']),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 62),
                      child: Container(
                          height: 0.5, color: const Color(0xFF2C2C2E)),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}