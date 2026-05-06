import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/applications/data/applications_service.dart';

final applicationsServiceProvider = Provider<ApplicationsService>((ref) {
  return ApplicationsService();
});
