import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/social_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notifService = NotificationService();
  final _socialService = SocialService();

  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifs = await _notifService.getNotifications();
    await _notifService.markAllRead();

    setState(() {
      _notifications = notifs;
      _loading = false;
    });
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = (createdAt as dynamic).toDate() as DateTime;
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return '';
    }
  }

  String _buildActionText(Map<String, dynamic> notif) {
    final type = notif['type'];
    final username = notif['fromUsername'] ?? '';

    switch (type) {
      case 'follow':
        return 'started following you';
      case 'follow_request':
        return 'wants to follow you';
      case 'follow_accepted':
        return 'accepted your follow request';
      default:
        return '';
    }
  }

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final now = DateTime.now();
    final requests = <Map<String, dynamic>>[];
    final last7 = <Map<String, dynamic>>[];
    final last30 = <Map<String, dynamic>>[];
    final older = <Map<String, dynamic>>[];

    for (final n in _notifications) {
      if (n['type'] == 'follow_request') {
        requests.add(n);
        continue;
      }

      DateTime? date;
      try {
        date = (n['createdAt'] as dynamic).toDate();
      } catch (_) {}

      if (date == null) {
        last30.add(n);
        continue;
      }

      final diff = now.difference(date).inDays;

      if (diff <= 7) {
        last7.add(n);
      } else if (diff <= 30) {
        last30.add(n);
      } else {
        older.add(n);
      }
    }

    return {
      if (requests.isNotEmpty) 'FOLLOW REQUESTS': requests,
      if (last7.isNotEmpty) 'LAST 7 DAYS': last7,
      if (last30.isNotEmpty) 'LAST 30 DAYS': last30,
      if (older.isNotEmpty) 'OLDER': older,
    };
  }

  Future<void> _acceptRequest(String fromUid, String notifId) async {
    await _socialService.acceptRequest(fromUid);
    await _notifService.deleteNotification(notifId);
    await _load();
  }

  Future<void> _declineRequest(String fromUid, String notifId) async {
    await _socialService.declineRequest(fromUid);
    await _notifService.deleteNotification(notifId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      )
          : _notifications.isEmpty
          ? Center(
        child: Text(
          'no notifications yet',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _grouped().entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              ...entry.value.map((notif) {
                final username = notif['fromUsername'] ?? '';
                final fromUid = notif['fromUid'] ?? '';
                final notifId = notif['id'] ?? '';
                final initial = username.isNotEmpty
                    ? username[0].toUpperCase()
                    : '?';
                final isRead = notif['read'] ?? true;
                final timeAgo = _timeAgo(notif['createdAt']);
                final isRequest =
                    notif['type'] == 'follow_request';

                final actionText = _buildActionText(notif);

                if (isRequest) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2A2A2A),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                              const Color(0xFFE50914),
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                      const TextSpan(
                                        text:
                                        ' wants to follow you',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _acceptRequest(
                                    fromUid, notifId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _declineRequest(
                                    fromUid, notifId),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2E),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Decline',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  color: isRead
                      ? Colors.transparent
                      : const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                        const Color(0xFFE50914),
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                  text: username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: ' $actionText',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE50914),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}