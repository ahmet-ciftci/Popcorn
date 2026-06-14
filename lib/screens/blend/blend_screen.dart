import 'package:flutter/material.dart';
import '../../services/blend_service.dart';
import 'blend_session_screen.dart';

class BlendScreen extends StatefulWidget {
  BlendScreen({super.key});

  @override
  State<BlendScreen> createState() => _BlendScreenState();
}

class _BlendScreenState extends State<BlendScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _hasError = false;
  BlendService _blendService = BlendService();

  final _nameController = TextEditingController();
  final _joinController = TextEditingController();

  // the session id we just made, shown so it can be shared
  String? _createdId;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  void _loadSessions() async {
    try {
      var sessions = await _blendService.getMySessions();

      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        _hasError = true;
        _loading = false;
      });
    }
  }

  void _createSession() async {
    var name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      var id = await _blendService.createSession(name);
      _nameController.clear();
      setState(() {
        _createdId = id;
      });
      _loadSessions();
    } catch (e) {
      print('Error creating session: $e');
    }
  }

  void _joinSession() async {
    var id = _joinController.text.trim();
    if (id.isEmpty) return;

    try {
      await _blendService.joinSession(id);
      _joinController.clear();
      _loadSessions();
    } catch (e) {
      print('Error joining session: $e');
    }
  }

  void _openSession(Map<String, dynamic> session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlendSessionScreen(
          sessionId: session['id'],
          sessionName: session['name'] ?? 'Untitled',
          createdBy: session['createdBy'] ?? '',
        ),
      ),
    );
    // a session may have been deleted, refresh the list
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Blend',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                _loadSessions();
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // create
          Text(
            'Start a Blend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: Color(0xFFE50914),
            decoration: InputDecoration(
              hintText: 'Session name',
              hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 14),
              filled: true,
              fillColor: Color(0xFF111111),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE50914), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              child: Text('Create'),
            ),
          ),
          // after creating, show the id so a friend can join
          _createdId == null
              ? SizedBox()
              : Container(
                  margin: EdgeInsets.only(top: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session created',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      SelectableText(
                        _createdId!,
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
          SizedBox(height: 24),
          // join
          Text(
            'Join a Blend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _joinController,
            style: TextStyle(color: Colors.white, fontSize: 14),
            cursorColor: Color(0xFFE50914),
            decoration: InputDecoration(
              hintText: 'Paste session ID',
              hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 14),
              filled: true,
              fillColor: Color(0xFF111111),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE50914), width: 1.5),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE50914),
                foregroundColor: Colors.white,
              ),
              child: Text('Join'),
            ),
          ),
          SizedBox(height: 24),
          // my sessions
          Text(
            'My Blends',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildSessionList(),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    if (_sessions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.group_outlined, color: Colors.grey, size: 48),
              SizedBox(height: 16),
              Text(
                'No blends yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _sessions.map((session) {
        return _SessionTile(
          session: session,
          onTap: () => _openSession(session),
        );
      }).toList(),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    var members = session['members'] as List;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session['name'] ?? 'Untitled',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${members.length} members',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
