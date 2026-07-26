import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HealthAppointment {
  final String id;
  final String childId;
  final String childName;
  final String title;
  final DateTime scheduledAt;
  final String status;

  HealthAppointment({
    required this.id,
    required this.childId,
    required this.childName,
    required this.title,
    required this.scheduledAt,
    this.status = 'Active',
  });

  factory HealthAppointment.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime scheduledAt = DateTime.now();
    final raw = map['scheduledAt'];
    if (raw is Timestamp) {
      scheduledAt = raw.toDate();
    } else if (raw is String) {
      scheduledAt = DateTime.tryParse(raw) ?? scheduledAt;
    }

    return HealthAppointment(
      id: documentId,
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      title: map['title'] ?? '',
      scheduledAt: scheduledAt,
      status: map['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'childName': childName,
      'title': title,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status,
    };
  }

  String get timeLabel => DateFormat('hh:mm a').format(scheduledAt);

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }
}
