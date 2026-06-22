import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/applications/data/applications_provider.dart';
import 'package:jobswipe/features/feed/data/job_interactions_provider.dart';
import 'package:jobswipe/features/profile/presentation/candidate_profile_page.dart';
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
      if (!context.mounted) return;

      final errorMessage = e.toString();

      if (errorMessage.contains('Profil incomplet')) {
        _showIncompleteProfileSheet(context, errorMessage);
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  List<String> _extractMissingProfileItems(String errorMessage) {
    var message = errorMessage
        .replaceFirst('Profil incomplet.', '')
        .replaceFirst('Complétez votre', '')
        .replaceFirst('avant de postuler.', '')
        .trim();

    if (message.isEmpty) {
      return [
        'Titre professionnel',
        'Ville',
        'Téléphone',
        'Résumé professionnel',
        'Au moins 3 compétences',
        'CV PDF',
      ];
    }

    return message
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) {
          return item[0].toUpperCase() + item.substring(1);
        })
        .toList();
  }

  void _showIncompleteProfileSheet(BuildContext context, String errorMessage) {
    final missingItems = _extractMissingProfileItems(errorMessage);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _IncompleteProfileBottomSheet(
          missingItems: missingItems,
          onCompleteProfile: () {
            Navigator.of(sheetContext).pop();

            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CandidateProfilePage()),
            );
          },
        );
      },
    );
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

class _IncompleteProfileBottomSheet extends StatelessWidget {
  final List<String> missingItems;
  final VoidCallback onCompleteProfile;

  const _IncompleteProfileBottomSheet({
    required this.missingItems,
    required this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, bottomPadding + 22),
      decoration: const BoxDecoration(
        color: Color(0xFF0E1627),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withOpacity(0.45)),
            ),
            child: const Icon(
              Icons.assignment_late_outlined,
              color: Colors.amber,
              size: 30,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Profil incomplet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complète les informations suivantes avant de postuler à cette offre.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: Colors.white.withOpacity(0.62),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111A2C),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: missingItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onCompleteProfile,
              icon: const Icon(Icons.person_outline),
              label: const Text(
                'Compléter mon profil',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Plus tard',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.68),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
