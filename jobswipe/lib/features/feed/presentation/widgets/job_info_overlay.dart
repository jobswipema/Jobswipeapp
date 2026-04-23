import 'package:flutter/material.dart';
import 'package:jobswipe/shared/models/job_offer.dart';

class JobInfoOverlay extends StatelessWidget {
  final JobOffer job;

  const JobInfoOverlay({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 90, 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${job.companyName} • ${job.location}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ),
              if (job.companyVerified)
                const Icon(Icons.verified, color: Colors.greenAccent, size: 18),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(job.contractType),
              _chip(job.experience),
              _chip(job.salary),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 2),
              onPressed: () {},
              child: const Text('Postuler'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
