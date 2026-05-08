import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String candidateId;
  final String candidateName;
  final String candidateEmail;
  final String candidateCvUrl;
  final String candidateCvFileName;
  final String companyId;
  final String companyName;
  final String jobTitle;
  final String status;
  final DateTime? createdAt;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.candidateId,
    required this.candidateName,
    required this.candidateEmail,
    required this.candidateCvUrl,
    required this.candidateCvFileName,
    required this.companyId,
    required this.companyName,
    required this.jobTitle,
    required this.status,
    required this.createdAt,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ApplicationModel(
      id: doc.id,
      jobId: data['jobId']?.toString() ?? '',
      candidateId: data['candidateId']?.toString() ?? '',
      candidateName: data['candidateName']?.toString() ?? 'Candidat',
      candidateEmail: data['candidateEmail']?.toString() ?? '',
      candidateCvUrl: data['candidateCvUrl']?.toString() ?? '',
      candidateCvFileName: data['candidateCvFileName']?.toString() ?? '',
      companyId: data['companyId']?.toString() ?? '',
      companyName: data['companyName']?.toString() ?? '',
      jobTitle: data['jobTitle']?.toString() ?? '',
      status: data['status']?.toString() ?? 'submitted',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
