import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jobswipe/features/feed/data/job_interactions_service.dart';

final jobInteractionsServiceProvider = Provider<JobInteractionsService>((ref) {
  return JobInteractionsService();
});
