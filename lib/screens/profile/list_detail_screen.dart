import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../movie_detail/movie_detail_screen.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const ListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _movies = [];
  bool _loading = true;
  late String _listName;

  @override
  void initState() {
    super.initState();
    _listName = widget.listName;
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    final movies = await _firestoreService.getMoviesInList(widget.listId);
    if (mounted) {
      setState(() {
        _movies = movies;
        _loading = false;
      });
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _listName);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Rename List',
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != _listName) {
                await _firestoreService.renameList(widget.listId, newName);
                if (mounted) {
                  setState(() => _listName = newName);
                  Navigator.pop(context);
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteList() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete List',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "$_listName"?',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteList(widget.listId);
      // 'deleted' döndür → profile refresh etsin
      if (mounted) Navigator.pop(context, 'deleted');
    }
  }

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
          // Geri basınca 'renamed' döndür → profile ismi güncellesin
          onPressed: () => Navigator.pop(context, 'renamed'),
        ),
        title: GestureDetector(
          onTap: _editName,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _listName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined,
                  color: Color(0xFFE50914), size: 15),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Colors.grey.shade600, size: 22),
            onPressed: _deleteList,
          ),
        ],
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : _movies.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined,
                color: Colors.grey.shade700, size: 48),
            const SizedBox(height: 12),
            Text('No movies in this list yet',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      )
          : ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(scrollbars: false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                '${_movies.length} FILMS',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _movies.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2 / 3,
                ),
                itemBuilder: (context, index) {
                  final movie = _movies[index];
                  final url = _posterUrl(movie['posterPath']);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailScreen(
                            movieId: movie['tmdbId'] as int),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: url.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE50914),
                              strokeWidth: 1.5,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade700),
                        ),
                      )
                          : Container(
                        color: const Color(0xFF1A1A1A),
                        child: Icon(Icons.movie,
                            color: Colors.grey.shade700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}