import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/core/enums/user_role.dart';
import 'package:jobswipe/core/enums/verification_status.dart';
import 'package:jobswipe/shared/models/app_user.dart';

final authProvider = NotifierProvider<AuthNotifier, AppUser>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppUser> {
  @override
  AppUser build() {
    return AppUser.guest;
  }

  void loginAsCandidate() {
    state = const AppUser(
      id: 'candidate_001',
      email: 'candidate@jobswipe.com',
      displayName: 'Adam Candidate',
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

  void logout() {
    state = AppUser.guest;
  }
}
