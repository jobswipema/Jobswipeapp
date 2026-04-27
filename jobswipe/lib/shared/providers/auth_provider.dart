import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/shared/models/app_user.dart';

final authProvider = NotifierProvider<AuthNotifier, AppUser>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppUser> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  AppUser build() {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return AppUser.guest;
    }

    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName:
          firebaseUser.displayName ?? firebaseUser.email ?? 'Utilisateur',
      role: UserRole.candidate, // temporaire, Firestore ensuite
      isLoggedIn: true,
    );
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw 'Utilisateur introuvable.';
      }

      state = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName:
            firebaseUser.displayName ?? firebaseUser.email ?? 'Utilisateur',
        role: UserRole.candidate, // temporaire, Firestore ensuite
        isLoggedIn: true,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (_) {
      throw 'Erreur de connexion inattendue.';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    state = AppUser.guest;
  }

  // -------- BOUTONS DE TEST DEV --------

  void loginAsCandidate() {
    state = const AppUser(
      id: 'candidate_001',
      email: 'candidate@jobswipe.com',
      displayName: 'Test Candidate',
      role: UserRole.candidate,
      isLoggedIn: true,
    );
  }

  void loginAsPendingCompany() {
    state = const AppUser(
      id: 'company_001',
      email: 'company@jobswipe.com',
      displayName: 'TechVision Morocco',
      role: UserRole.company,
      isLoggedIn: true,
      isVerifiedCompany: false,
      verificationStatus: VerificationStatus.pending,
    );
  }

  void loginAsVerifiedCompany() {
    state = const AppUser(
      id: 'company_002',
      email: 'verified@jobswipe.com',
      displayName: 'Verified Tech Corp',
      role: UserRole.company,
      isLoggedIn: true,
      isVerifiedCompany: true,
      verificationStatus: VerificationStatus.approved,
    );
  }

  void loginAsAdmin() {
    state = const AppUser(
      id: 'admin_001',
      email: 'admin@jobswipe.com',
      displayName: 'Platform Admin',
      role: UserRole.admin,
      isLoggedIn: true,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte utilisateur est désactivé.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème réseau. Vérifiez votre connexion.';
      default:
        return e.message ?? 'Erreur de connexion Firebase.';
    }
  }
}
