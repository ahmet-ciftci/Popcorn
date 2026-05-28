import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/social_service.dart';
import 'user_profile_screen.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String uid;
  final String title;
  final bool isFollowers;

  const FollowersFollowingScreen({
    super.key,
    required this.uid,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState
    extends State<FollowersFollowingScreen> {
  final SocialService _socialService = SocialService();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final users = widget.isFollowers
        ? await _socialService.getFollowers(widget.uid)
        : await _socialService.getFollowing(widget.uid);

    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE50914),
        ),
      )
          : _users.isEmpty
          ? Center(
        child: Text(
          'No users found',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      )
          : ListView.separated(
        itemCount: _users.length,
        separatorBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(left: 72),
          height: 0.5,
          color: const Color(0xFF2A2A2A),
        ),
        itemBuilder: (context, index) {
          final user = _users[index];

          final username = user['username'] ?? '';
          final initial = username.isNotEmpty
              ? username[0].toUpperCase()
              : '?';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE50914),
              child: Text(
                initial,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(
                    uid: user['uid'],
                    username: username,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}