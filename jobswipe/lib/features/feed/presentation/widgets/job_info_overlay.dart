import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/applications/data/applications_provider.dart';
import 'package:jobswipe/features/feed/data/job_interactions_provider.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class JobInfoOverlay extends ConsumerWidget {
  final JobOffer job;

  const JobInfoOverlay({super.key, required this.job});

  String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }

  String _interactionDocId(String jobId) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return '${jobId}_$uid';
  }

  Stream<bool> _likedStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('job_likes')
        .doc(_interactionDocId(job.id))
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> _favoriteStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('job_favorites')
        .doc(_interactionDocId(job.id))
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(applicationsServiceProvider).applyToJob(job);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidature envoyée avec succès.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(jobInteractionsServiceProvider).toggleLike(job.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(jobInteractionsServiceProvider).toggleFavorite(job.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            right: 14,
            bottom: 145,
            child: Column(
              children: [
                StreamBuilder<bool>(
                  stream: _likedStream(),
                  builder: (context, snapshot) {
                    final isLiked = snapshot.data ?? false;

                    return _ActionButton(
                      icon: Icons.favorite,
                      value: _formatCount(job.likesCount),
                      isActive: isLiked,
                      activeColor: const Color(0xFFFF4D6D),
                      activeBackgroundColor: const Color(
                        0xFFFF2D55,
                      ).withOpacity(0.25),
                      onTap: () => _toggleLike(context, ref),
                    );
                  },
                ),
                const SizedBox(height: 18),
                StreamBuilder<bool>(
                  stream: _favoriteStream(),
                  builder: (context, snapshot) {
                    final isFavorite = snapshot.data ?? false;

                    return _ActionButton(
                      icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      value: _formatCount(job.favoritesCount),
                      isActive: isFavorite,
                      activeColor: Colors.amberAccent,
                      activeBackgroundColor: Colors.amber.withOpacity(0.22),
                      onTap: () => _toggleFavorite(context, ref),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _ActionButton(
                  icon: Icons.remove_red_eye,
                  value: _formatCount(job.viewsCount),
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 74,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.42),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 26,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${job.companyName} • ${job.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.82),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (job.companyVerified) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(label: job.contractType),
                      _Pill(label: job.experience),
                      _Pill(label: job.salary),
                    ],
                  ),
                  if (job.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _apply(context, ref),
                      child: const Text('Postuler'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final Color activeBackgroundColor;

  const _ActionButton({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.isActive,
    this.activeColor = const Color(0xFFFF4D6D),
    this.activeBackgroundColor = const Color(0x40FF2D55),
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;
  late bool _localActive;

  @override
  void initState() {
    super.initState();
    _localActive = widget.isActive;
  }

  @override
  void didUpdateWidget(covariant _ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _localActive = widget.isActive;
    }
  }

  Future<void> _handleTap() async {
    setState(() {
      _isPressed = true;
      _localActive = !_localActive;
    });

    await Future.delayed(const Duration(milliseconds: 140));

    if (mounted) {
      setState(() {
        _isPressed = false;
      });
    }

    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = _localActive ? widget.activeColor : Colors.white;
    final bgColor = _localActive
        ? widget.activeBackgroundColor
        : Colors.black.withOpacity(0.38);

    return Column(
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedScale(
            scale: _isPressed ? 1.28 : 1.0,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _localActive ? widget.activeColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(widget.icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52).withOpacity(0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.65)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
