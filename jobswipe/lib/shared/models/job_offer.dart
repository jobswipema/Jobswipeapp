class JobOffer {
  final String id;
  final String companyName;
  final bool companyVerified;
  final String title;
  final String location;
  final String contractType;
  final String experience;
  final String salary;
  final String description;

  const JobOffer({
    required this.id,
    required this.companyName,
    required this.companyVerified,
    required this.title,
    required this.location,
    required this.contractType,
    required this.experience,
    required this.salary,
    required this.description,
  });
}
