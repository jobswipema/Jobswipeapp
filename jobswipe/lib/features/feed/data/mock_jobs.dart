import 'package:jobswipe/shared/models/job_offer.dart';

const mockJobs = [
  JobOffer(
    id: 'job_001',
    companyName: 'TechVision',
    companyVerified: true,
    title: 'Développeur Flutter',
    location: 'Casablanca',
    contractType: 'CDI',
    experience: '2 ans exp.',
    salary: '18 000 - 24 000 MAD',
    description:
        'Rejoins une équipe produit moderne et participe au développement d’une application mobile innovante.',
  ),
  JobOffer(
    id: 'job_002',
    companyName: 'DataNova',
    companyVerified: false,
    title: 'Data Analyst',
    location: 'Rabat',
    contractType: 'CDD',
    experience: '1 à 3 ans',
    salary: '12 000 - 16 000 MAD',
    description:
        'Analyse de données, tableaux de bord, reporting métier et amélioration continue des indicateurs.',
  ),
  JobOffer(
    id: 'job_003',
    companyName: 'CloudCore',
    companyVerified: true,
    title: 'Ingénieur DevOps',
    location: 'Marrakech',
    contractType: 'CDI',
    experience: '3 ans exp.',
    salary: '20 000 - 28 000 MAD',
    description:
        'Automatisation CI/CD, conteneurisation, observabilité et industrialisation des déploiements.',
  ),
];
