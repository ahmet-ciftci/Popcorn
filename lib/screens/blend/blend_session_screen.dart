import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/api_constants.dart';
import '../../services/blend_service.dart';
import '../../services/firestore_service.dart';
import 'blend_vote_screen.dart';
import 'blend_results_screen.dart';

class BlendSessionScreen extends StatefulWidget {
  final String sessionId;
  final String sessionName;
  final String createdBy;

  BlendSessionScreen({
    super.key,
    required this.sessionId,
    required this.sessionName,
    required this.createdBy,
  });

  @override
  State<BlendSessionScreen> createState() => _BlendSessionScreenState();
}

class _BlendSessionScreenState extends State<BlendSessionScreen> {
  List<Map<String, dynamic>> _pool = [];
  bool _loading = true;
  bool _hasError = false;
  BlendService _blendService = BlendService();
  FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  void _loadPool() async {
    try {
      var pool = await _blendService.getPool(widget.sessionId);

      setState(() {
        _pool = pool;
        _loading = false;
      });
    } catch (e) {
      print('Error loading pool: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  // open a picker of my lists, then add the selected ones to the pool
  void _addFromList() async {
    try {
      var lists = await _firestoreService.getLists();
      if (!mounted) return;

      if (lists.isEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C1C1E),
              title: Text(
                'Add from list',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              content: Text(
                'You have no lists yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          },
        );
        return;
      }

      // the lists I've ticked
      var selected = <String>{};

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Color(0xFF1C1C1E),
                title: Text(
                  'Add from list',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: lists.map((list) {
                        String id = list['id'];
                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected.add(id);
                              } else {
                                selected.remove(id);
                              }
                            });
                          },
                          title: Text(
                            list['name'] ?? 'Untitled',
                            style: TextStyle(color: Colors.white),
                          ),
                          activeColor: Color(0xFFE50914),
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addLists(selected.toList());
                    },
                    child: Text(
                      'Add selected',
                      style: TextStyle(color: Color(0xFFE50914)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error loading lists: $e');
    }
  }

  void _addLists(List<String> listIds) async {
    try {
      for (var listId in listIds) {
        var movies = await _firestoreService.getMoviesInList(listId);
        await _blendService.addListToPool(widget.sessionId, movies);
      }
      _loadPool();
    } catch (e) {
      print('Error adding lists to pool: $e');
    }
  }

  void _confirmDelete() async {
    var confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1C1C1E),
          title: Text(
            'Delete this Blend?',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Color(0xFFE50914))),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _blendService.deleteSession(widget.sessionId);
      } catch (e) {
        print('Error deleting session: $e');
      }
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // only the creator can delete the session
    var isCreator = widget.createdBy == FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.sessionName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isCreator)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _confirmDelete,
            ),
        ],
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
                _loadPool();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // header
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // session id, selectable so it can be shared again
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    SelectableText(
                      widget.sessionId,
                      style: TextStyle(color: Color(0xFFE50914), fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Share this ID so a friend can join.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addFromList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE50914),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add movies from my list'),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlendVoteScreen(
                          sessionId: widget.sessionId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE50914),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Start voting'),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlendResultsScreen(
                          sessionId: widget.sessionId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE50914),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Results'),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Pool',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(child: _buildPoolList()),
      ],
    );
  }

  Widget _buildPoolList() {
    if (_pool.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No movies in the pool yet.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pool.length,
      itemBuilder: (context, index) {
        return _PoolTile(movie: _pool[index]);
      },
    );
  }
}

class _PoolTile extends StatelessWidget {
  final Map<String, dynamic> movie;

  const _PoolTile({required this.movie});

  @override
  Widget build(BuildContext context) {
    String posterPath = movie['posterPath'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: posterPath.isNotEmpty
                ? Image.network(
                    ApiConstants.imageBaseUrl + posterPath,
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 50,
                    height: 75,
                    color: Color(0xFF222222),
                    child: Icon(Icons.movie_outlined, color: Colors.grey),
                  ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              movie['title'] ?? '',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
