import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompanyNotificationsPage extends StatelessWidget {
  final String companyId;

  const CompanyNotificationsPage({super.key, required this.companyId});

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: companyId)
        .snapshots();
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Erreur lors du chargement des notifications.'),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = [...snapshot.data!.docs];

            docs.sort((a, b) {
              final aDate = a.data()['createdAt'];
              final bDate = b.data()['createdAt'];

              if (aDate is! Timestamp && bDate is! Timestamp) return 0;
              if (aDate is! Timestamp) return 1;
              if (bDate is! Timestamp) return -1;

              return bDate.toDate().compareTo(aDate.toDate());
            });

            final unreadCount = docs.where((doc) {
              return doc.data()['isRead'] != true;
            }).length;

            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucune notification pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                const Text(
                  'Notifications entreprise',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$unreadCount non lue(s)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                ...docs.map((doc) {
                  final data = doc.data();

                  final title = data['title']?.toString() ?? 'Notification';
                  final message = data['message']?.toString() ?? '';
                  final isRead = data['isRead'] == true;
                  final date = _formatDate(data['createdAt']);

                  return _CompanyNotificationCard(
                    title: title,
                    message: message,
                    date: date,
                    isRead: isRead,
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(doc.id);
                      }
                    },
                    onMarkAsRead: () {
                      _markAsRead(doc.id);
                    },
                    onDelete: () {
                      _deleteNotification(doc.id);
                    },
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompanyNotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _CompanyNotificationCard({
    required this.title,
    required this.message,
    required this.date,
    required this.isRead,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161D2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRead
                ? Colors.white10
                : Colors.blueAccent.withOpacity(0.70),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      height: 1.35,
                      fontSize: 14,
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isRead)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onMarkAsRead,
                            icon: const Icon(Icons.done),
                            label: const Text('Marquer lue'),
                          ),
                        ),
                      if (!isRead) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
