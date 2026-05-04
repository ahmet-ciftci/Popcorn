import 'package:flutter/material.dart';
import 'mood_results_screen.dart';

class _Mood {
  final String name;
  final String emoji;
  final List<int> genreIds;
  final String sortBy;
  final Color color;

  const _Mood({
    required this.name,
    required this.emoji,
    required this.genreIds,
    required this.sortBy,
    required this.color,
  });
}

const List<_Mood> _moods = [
  _Mood(
    name: 'Cozy Night In',
    emoji: '🛋️',
    genreIds: [10751, 35, 10749],
    sortBy: 'popularity.desc',
    color: Color(0xFF8B5E3C),
  ),
  _Mood(
    name: 'Mind-Bending',
    emoji: '🧠',
    genreIds: [878, 9648, 53],
    sortBy: 'popularity.desc',
    color: Color(0xFF4B3F72),
  ),
  _Mood(
    name: 'Feel-Good',
    emoji: '😊',
    genreIds: [35, 10749],
    sortBy: 'popularity.desc',
    color: Color(0xFFE5A100),
  ),
  _Mood(
    name: 'Edge of Your Seat',
    emoji: '😱',
    genreIds: [53, 28],
    sortBy: 'popularity.desc',
    color: Color(0xFFB23A48),
  ),
  _Mood(
    name: 'Dark & Gritty',
    emoji: '🌑',
    genreIds: [80, 18, 53],
    sortBy: 'popularity.desc',
    color: Color(0xFF2C2C2C),
  ),
  _Mood(
    name: 'Epic Adventure',
    emoji: '⚔️',
    genreIds: [12, 14, 28],
    sortBy: 'popularity.desc',
    color: Color(0xFF2E5E4E),
  ),
  _Mood(
    name: 'Tear-Jerker',
    emoji: '😢',
    genreIds: [18, 10749],
    sortBy: 'popularity.desc',
    color: Color(0xFF3E5C76),
  ),
  _Mood(
    name: 'Spooky',
    emoji: '👻',
    genreIds: [27, 9648],
    sortBy: 'popularity.desc',
    color: Color(0xFF1F1B2E),
  ),
];

class MoodBrowseScreen extends StatelessWidget {
  const MoodBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0D0D),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Moods',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          return _MoodCard(mood: _moods[index]);
        },
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final _Mood mood;

  const _MoodCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoodResultsScreen(
              moodName: mood.name,
              moodEmoji: mood.emoji,
              genreIds: mood.genreIds,
              sortBy: mood.sortBy,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: mood.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              mood.emoji,
              style: TextStyle(fontSize: 40),
            ),
            Text(
              mood.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}