import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/features/company/presentation/create_job_page.dart';
import 'package:jobswipe/features/feed/presentation/feed_page.dart';
import 'package:jobswipe/features/profile/presentation/candidate_profile_page.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/search/presentation/search_page.dart';
import 'package:jobswipe/features/notifications/presentation/notifications_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int currentIndex = 0;

  Future<void> _showNavigationSheet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _NavigationInfoBottomSheet(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
        );
      },
    );
  }

  Widget _placeholderPage(String title) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<Widget> _buildPages(UserRole role) {
    if (role == UserRole.company) {
      return [
        const FeedPage(),
        const SearchPage(),
        _placeholderPage('Publier une offre'),
        const NotificationsPage(),
        _placeholderPage('Profil entreprise'),
      ];
    }

    return [
      const FeedPage(),
      const SearchPage(),
      const NotificationsPage(),
      const CandidateProfilePage(),
    ];
  }

  List<BottomNavigationBarItem> _buildItems(UserRole role) {
    if (role == UserRole.company) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Publier'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
      BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ];
  }

  Future<void> _onTabTapped(int index) async {
    final user = ref.read(authProvider);

    if (user.role == UserRole.company && index == 2) {
      if (!user.isVerifiedCompany) {
        await _showNavigationSheet(
          icon: Icons.verified_user_outlined,
          iconColor: Colors.amber,
          title: 'Entreprise en attente',
          message:
              'Votre entreprise est en attente de validation. Vous ne pouvez pas encore publier d’offre.',
        );
        return;
      }

      if (!mounted) return;

      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CreateJobPage()));
      return;
    }

    if (!mounted) return;

    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    final pages = _buildPages(user.role);
    final items = _buildItems(user.role);

    if (currentIndex >= pages.length) {
      currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}

class _NavigationInfoBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _NavigationInfoBottomSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(22, 10, 22, bottomPadding + 22),
      decoration: const BoxDecoration(
        color: Color(0xFF101827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Icon(icon, color: iconColor, size: 44),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.4,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
