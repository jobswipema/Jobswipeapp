import 'package:flutter/material.dart';

class FeedActionsColumn extends StatelessWidget {
  final String likes;
  final String saves;
  final String applies;

  const FeedActionsColumn({
    super.key,
    required this.likes,
    required this.saves,
    required this.applies,
  });

  Widget _buildAction(IconData icon, String value) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.black.withOpacity(0.30),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 160),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildAction(Icons.favorite, '23.5K'),
          const SizedBox(height: 18),
          _buildAction(Icons.bookmark_border, '1.1K'),
          const SizedBox(height: 18),
          _buildAction(Icons.send, '212'),
        ],
      ),
    );
  }
}
