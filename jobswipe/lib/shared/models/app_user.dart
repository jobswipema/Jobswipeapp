import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/core/enums/verification_status.dart';

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final bool isLoggedIn;
  final bool isVerifiedCompany;
  final VerificationStatus? verificationStatus;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isLoggedIn,
    this.isVerifiedCompany = false,
    this.verificationStatus,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isLoggedIn,
    bool? isVerifiedCompany,
    VerificationStatus? verificationStatus,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isVerifiedCompany: isVerifiedCompany ?? this.isVerifiedCompany,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  static const AppUser guest = AppUser(
    id: '',
    email: '',
    displayName: 'Guest',
    role: UserRole.candidate,
    isLoggedIn: false,
    isVerifiedCompany: false,
    verificationStatus: null,
  );
}
