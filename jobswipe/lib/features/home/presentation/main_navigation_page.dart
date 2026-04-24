import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/features/feed/presentation/feed_page.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';
import 'package:jobswipe/features/company/presentation/create_job_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  int currentIndex = 0;

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        _placeholderPage('Recherche'),
        _placeholderPage('Publier une offre'),
        _placeholderPage('Messages'),
        _placeholderPage('Profil'),
      ];
    }

    return [
      const FeedPage(),
      _placeholderPage('Recherche'),
      _placeholderPage('Messages'),
      _placeholderPage('Profil'),
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

  void _onTabTapped(int index) {
    final user = ref.read(authProvider);

    if (user.role == UserRole.company && index == 2) {
      if (!user.isVerifiedCompany) {
        _showSnack(
          'Votre entreprise est en attente de validation. Vous ne pouvez pas encore publier d’offre.',
        );
        return;
      }

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CreateJobPage()));
      return;
    }

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
