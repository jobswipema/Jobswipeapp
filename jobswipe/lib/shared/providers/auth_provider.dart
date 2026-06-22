import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/shared/models/app_user.dart';
import 'package:flutter/material.dart';

final authProvider = NotifierProvider<AuthNotifier, AppUser>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppUser> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  AppUser build() {
    return AppUser.guest;
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

      await _createUserDocumentIfMissing(firebaseUser);

      final appUser = await _loadUserFromFirestore(firebaseUser);

      state = appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> registerWithEmailAndRole({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw 'Utilisateur introuvable après inscription.';
      }

      await firebaseUser.updateDisplayName(displayName);

      final isCompany = role == UserRole.company;

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'email': email,
        'displayName': displayName,
        'role': isCompany ? 'company' : 'candidate',
        'isActive': true,
        'isVerifiedCompany': false,
        'verificationStatus': isCompany ? 'pending' : 'none',

        // Profil candidat
        'title': '',
        'city': '',
        'phone': '',
        'bio': '',
        'skills': [],
        'linkedinUrl': '',
        'githubUrl': '',
        'portfolioUrl': '',
        'cvUrl': '',
        'cvFileName': '',
        'profileCompleted': false,
        'profileCompletionPercent': isCompany ? 100 : 10,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final appUser = await _loadUserFromFirestore(firebaseUser);
      state = appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw 'Utilisateur introuvable après inscription.';
      }

      await _createUserDocumentIfMissing(firebaseUser);

      final appUser = await _loadUserFromFirestore(firebaseUser);

      state = appUser;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> _createUserDocumentIfMissing(User firebaseUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      return;
    }

    await userRef.set({
      'email': firebaseUser.email ?? '',
      'displayName':
          firebaseUser.displayName ??
          firebaseUser.email ??
          'Utilisateur JobSwipe',
      'role': 'candidate',
      'isActive': true,
      'isVerifiedCompany': false,
      'verificationStatus': 'none',

      // Profil candidat
      'title': '',
      'city': '',
      'phone': '',
      'bio': '',
      'skills': [],
      'linkedinUrl': '',
      'githubUrl': '',
      'portfolioUrl': '',
      'cvUrl': '',
      'cvFileName': '',
      'profileCompleted': false,
      'profileCompletionPercent': 10,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser> _loadUserFromFirestore(User firebaseUser) async {
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) {
      throw 'Profil utilisateur introuvable dans Firestore.';
    }

    final data = doc.data();

    if (data == null) {
      throw 'Profil utilisateur vide dans Firestore.';
    }

    final isActiveValue = data['isActive'];

    debugPrint('USER FIRESTORE DATA: $data');
    debugPrint('isActive value: $isActiveValue');

    final isActive = isActiveValue == true || isActiveValue == 'true';

    if (!isActive) {
      throw 'Votre compte est désactivé. Contactez l’administrateur. Valeur isActive lue: $isActiveValue';
    }

    return AppUser(
      id: firebaseUser.uid,
      email: data['email'] ?? firebaseUser.email ?? '',
      displayName: data['displayName'] ?? firebaseUser.email ?? 'Utilisateur',
      role: _parseRole(data['role']),
      isLoggedIn: true,
      isVerifiedCompany: data['isVerifiedCompany'] == true,
      verificationStatus: _parseVerificationStatus(data['verificationStatus']),
    );
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

  UserRole _parseRole(dynamic value) {
    switch (value) {
      case 'company':
        return UserRole.company;
      case 'admin':
        return UserRole.admin;
      case 'candidate':
      default:
        return UserRole.candidate;
    }
  }

  VerificationStatus? _parseVerificationStatus(dynamic value) {
    switch (value) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'none':
      default:
        return null;
    }
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
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème réseau. Vérifiez votre connexion.';
      default:
        return e.message ?? 'Erreur Firebase.';
    }
  }
}
