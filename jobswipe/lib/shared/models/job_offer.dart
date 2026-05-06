import 'package:cloud_firestore/cloud_firestore.dart';

class JobOffer {
  final String id;
  final String companyId;
  final String companyName;
  final bool companyVerified;
  final String title;
  final String location;
  final String contractType;
  final String experience;
  final String salary;
  final String category;
  final String description;
  final bool isActive;
  final DateTime? createdAt;

  const JobOffer({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.companyVerified,
    required this.title,
    required this.location,
    required this.contractType,
    required this.experience,
    required this.salary,
    required this.category,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory JobOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return JobOffer(
      id: doc.id,
      companyId: data['companyId']?.toString() ?? '',
      companyName: data['companyName']?.toString() ?? 'Entreprise',
      companyVerified: true,
      title: data['title']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      contractType: data['contractType']?.toString() ?? '',
      experience: data['experienceLevel']?.toString() ?? '',
      salary: data['salary'] != null
          ? '${data['salary']} MAD'
          : 'Salaire non précisé',
      category: data['category']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      isActive: data['isActive'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
