import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/shared/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  static const String _logoUrl =
      'https://res.cloudinary.com/dfqxmh5gq/image/upload/v1780565357/logo_jobswipe_j8stfm.png';

  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.candidate;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1A2235),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .registerWithEmailAndRole(
            email: email,
            password: password,
            displayName: displayName,
            role: _selectedRole,
          );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLogo() {
    return Center(
      child: Image.network(
        _logoUrl,
        height: 86,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return const SizedBox(
            height: 86,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 86,
            child: Center(
              child: Text(
                'JobSwipe',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _roleCard({
    required UserRole role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedRole == role;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F2A52) : const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.white10,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: selected
                  ? Colors.blueAccent
                  : const Color(0xFF202A3F),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Colors.white.withOpacity(0.68),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompany = _selectedRole == UserRole.company;

    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(),

              const SizedBox(height: 32),

              const Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choisis ton type de compte pour accéder aux fonctionnalités adaptées.',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 28),

              _roleCard(
                role: UserRole.candidate,
                icon: Icons.person_outline,
                title: 'Je suis candidat',
                subtitle: 'Découvrir des offres, sauvegarder et postuler.',
              ),
              const SizedBox(height: 14),
              _roleCard(
                role: UserRole.company,
                icon: Icons.business_outlined,
                title: 'Je suis une entreprise',
                subtitle:
                    'Créer un profil entreprise et demander la validation admin.',
              ),

              const SizedBox(height: 28),

              if (isCompany)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.amber.withOpacity(0.55)),
                  ),
                  child: const Text(
                    'Important : un compte entreprise doit être validé par l’administrateur après vérification de son existence légale et signature du contrat. La publication d’offres sera désactivée tant que le badge Vérifié n’est pas accordé.',
                    style: TextStyle(
                      color: Colors.amber,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _displayNameController,
                      decoration: _inputDecoration(
                        label: isCompany
                            ? 'Nom de l’entreprise'
                            : 'Nom complet',
                        icon: isCompany
                            ? Icons.business_center_outlined
                            : Icons.person_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isCompany
                              ? 'Le nom de l’entreprise est obligatoire.'
                              : 'Le nom complet est obligatoire.';
                        }
                        if (value.trim().length < 3) {
                          return 'Le nom est trop court.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: 'Email',
                        icon: Icons.mail_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L’email est obligatoire.';
                        }
                        if (!value.contains('@')) {
                          return 'Adresse email invalide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecoration(
                        label: 'Mot de passe',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le mot de passe est obligatoire.';
                        }
                        if (value.trim().length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(
                          isCompany
                              ? 'Créer le compte entreprise'
                              : 'Créer le compte candidat',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
