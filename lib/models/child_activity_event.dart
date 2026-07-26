import 'package:flutter/material.dart';

import '../core/domain/domain_enums.dart';
import '../core/theme/app_theme.dart';
import 'academic_models.dart';

enum ChildActivityType {
  attendance,
  grade,
  homeworkAssigned,
  homeworkDue,
}

class ChildActivityEvent {
  final ChildActivityType type;
  final String title;
  final String subtitle;
  final DateTime at;

  const ChildActivityEvent({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.at,
  });

  IconData get icon => switch (type) {
        ChildActivityType.attendance => Icons.fact_check_rounded,
        ChildActivityType.grade => Icons.grade_rounded,
        ChildActivityType.homeworkAssigned => Icons.assignment_rounded,
        ChildActivityType.homeworkDue => Icons.event_rounded,
      };

  Color get color => switch (type) {
        ChildActivityType.attendance => AppTheme.primaryBlue,
        ChildActivityType.grade => AppTheme.softGreen,
        ChildActivityType.homeworkAssigned => Colors.deepPurple,
        ChildActivityType.homeworkDue => Colors.orange,
      };

  static List<ChildActivityEvent> merge({
    required List<AttendanceRecordModel> attendance,
    required List<AssessmentModel> assessments,
    required List<AssignmentModel> assignments,
    required String? Function(String subjectId) subjectNameFor,
  }) {
    final events = <ChildActivityEvent>[];
    final now = DateTime.now();

    for (final record in attendance) {
      final statusLabel = switch (record.status) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.excused => 'Excused',
        AttendanceStatus.absent => 'Absent',
      };
      events.add(
        ChildActivityEvent(
          type: ChildActivityType.attendance,
          title: 'Attendance: $statusLabel',
          subtitle: 'Marked for class day',
          at: record.markedAt,
        ),
      );
    }

    for (final assessment in assessments) {
      if (!assessment.isPublished) continue;
      final subject = subjectNameFor(assessment.subjectId) ?? 'Subject';
      final pct = assessment.percentage?.round();
      events.add(
        ChildActivityEvent(
          type: ChildActivityType.grade,
          title: assessment.title,
          subtitle: pct != null ? '$subject • $pct%' : subject,
          at: assessment.publishedAt ?? assessment.createdAt,
        ),
      );
    }

    for (final assignment in assignments) {
      final subject = subjectNameFor(assignment.subjectId) ?? 'Subject';
      events.add(
        ChildActivityEvent(
          type: ChildActivityType.homeworkAssigned,
          title: assignment.title,
          subtitle: '$subject • Assigned by teacher',
          at: assignment.createdAt,
        ),
      );
      final due = assignment.dueAt;
      if (due != null && !due.isBefore(now.subtract(const Duration(days: 1)))) {
        events.add(
          ChildActivityEvent(
            type: ChildActivityType.homeworkDue,
            title: assignment.title,
            subtitle: '$subject • Due date',
            at: due,
          ),
        );
      }
    }

    events.sort((a, b) => b.at.compareTo(a.at));
    if (events.length > 40) {
      return events.sublist(0, 40);
    }
    return events;
  }
}
