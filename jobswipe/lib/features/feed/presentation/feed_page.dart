import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/feed/data/jobs_provider.dart';
import 'package:jobswipe/features/feed/presentation/widgets/tiktok_video_card.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final authNotifier = ref.read(authProvider.notifier);
    final jobsAsync = ref.watch(jobsStreamProvider);

    return Scaffold(
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur lors du chargement des offres : $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return Stack(
              children: [
                const Center(
                  child: Text(
                    'Aucune offre disponible pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _logoutButton(authNotifier),
              ],
            );
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  return TikTokVideoCard(job: jobs[index]);
                },
              ),
              _logoutButton(authNotifier),
            ],
          );
        },
      ),
    );
  }

  Widget _logoutButton(AuthNotifier authNotifier) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, right: 10),
          child: IconButton(
            onPressed: authNotifier.logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
