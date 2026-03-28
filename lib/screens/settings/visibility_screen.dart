import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VisibilityScreen extends StatefulWidget {
  const VisibilityScreen({super.key});

  @override
  State<VisibilityScreen> createState() => _VisibilityScreenState();
}

class _VisibilityScreenState extends State<VisibilityScreen> {
  final Map<String, String> _settings = {
    'Profile Visibility': 'Everyone',
    'Watched List': 'Everyone',
    'Watchlist': 'Everyone',
    'Reviews': 'Everyone',
    'Favorites': 'Everyone',
    'Custom Lists': 'Everyone',
    'Followers List': 'Everyone',
  };

  @override
  Widget build(BuildContext context) {
    final keys = _settings.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visibility',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: List.generate(keys.length, (i) {
                final key = keys[i];
                final isLast = i == keys.length - 1;

                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        key,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _settings[key]!,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Icon(CupertinoIcons.chevron_right, size: 13, color: Colors.grey.shade700),
                        ],
                      ),
                      onTap: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _VisibilityOptionScreen(
                              title: key,
                              currentValue: _settings[key]!,
                            ),
                          ),
                        );

                        if (result != null) {
                          setState(() => _settings[key] = result);
                        }
                      },
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Container(height: 0.5, color: const Color(0xFF2C2C2E)),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// (Everyone / Friends / Only Me)
class _VisibilityOptionScreen extends StatefulWidget {
  final String title;
  final String currentValue;

  const _VisibilityOptionScreen({
    required this.title,
    required this.currentValue,
  });

  @override
  State<_VisibilityOptionScreen> createState() => _VisibilityOptionScreenState();
}

class _VisibilityOptionScreenState extends State<_VisibilityOptionScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: [
                  _optionTile(
                    icon: CupertinoIcons.globe,
                    label: 'Everyone',
                    description: 'Visible to all users',
                    isLast: false,
                  ),
                  _optionTile(
                    icon: CupertinoIcons.person_2,
                    label: 'Friends',
                    description: 'Only your connections',
                    isLast: false,
                  ),
                  _optionTile(
                    icon: CupertinoIcons.lock,
                    label: 'Only Me',
                    description: 'Completely private',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, _selected),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required String description,
    required bool isLast,
  }) {
    final isSelected = _selected == label;

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
            child: Icon(icon, size: 16, color: Colors.grey),
          ),
          title: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            description,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFE50914) : Colors.transparent,
              border: isSelected ? null : Border.all(color: Colors.grey.shade700, width: 1.5),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          onTap: () => setState(() => _selected = label),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Container(height: 0.5, color: const Color(0xFF2C2C2E)),
          ),
      ],
    );
  }
}