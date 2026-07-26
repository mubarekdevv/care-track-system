import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../models/parent_insights.dart';

/// Demo insights until Firestore collections are wired for academics/billing.
///
/// **DEPRECATED — Phase 2.** Do not use in new code. Will be removed in Phase 4
/// when parent dashboards show empty states instead of synthetic grades/billing.
@Deprecated('Use AcademicRepository and real Firestore data. Removed in Phase 4.')
class ParentDemoData {
  ParentDemoData._();

  static String gradeForAge(int age) {
    final grade = (age - 5).clamp(1, 12);
    return 'Grade $grade';
  }

  static List<SubjectGrade> gradesFor(ChildModel child) {
    final seed = child.name.hashCode.abs();
    return [
      SubjectGrade(subject: 'Math', score: 78 + (seed % 15), previousScore: 70 + (seed % 12)),
      SubjectGrade(subject: 'Reading', score: 85 + (seed % 10), previousScore: 80 + (seed % 8)),
      SubjectGrade(subject: 'Science', score: 82 + (seed % 12), previousScore: 79 + (seed % 10)),
      SubjectGrade(subject: 'Art', score: 90 + (seed % 8), previousScore: 88 + (seed % 6)),
    ];
  }

  static List<TimelineEvent> timelineFor(ChildModel child) {
    final now = DateTime.now();
    final events = <TimelineEvent>[
      TimelineEvent(
        title: 'Attendance marked present',
        description: '${child.name} checked in at 8:12 AM today.',
        date: now.subtract(const Duration(hours: 3)),
        type: TimelineEventType.academic,
        icon: Icons.check_circle_rounded,
      ),
      TimelineEvent(
        title: 'Math quiz score posted',
        description: 'Scored 88% — up 12% from last month.',
        date: now.subtract(const Duration(days: 2)),
        type: TimelineEventType.academic,
        icon: Icons.calculate_rounded,
      ),
      TimelineEvent(
        title: 'Reading homework assigned',
        description: 'Chapter 4 worksheet due Friday.',
        date: now.subtract(const Duration(days: 3)),
        type: TimelineEventType.academic,
        icon: Icons.menu_book_rounded,
      ),
    ];

    if (child.vaccinations.isNotEmpty) {
      events.add(
        TimelineEvent(
          title: 'Vaccination logged',
          description: '${child.vaccinations.last} recorded in health profile.',
          date: now.subtract(const Duration(days: 5)),
          type: TimelineEventType.health,
          icon: Icons.vaccines_rounded,
        ),
      );
    } else {
      events.add(
        TimelineEvent(
          title: 'Vaccination reminder',
          description: 'Complete ${child.name}\'s immunization profile.',
          date: now.subtract(const Duration(days: 5)),
          type: TimelineEventType.health,
          icon: Icons.medical_information_rounded,
        ),
      );
    }

    events.addAll([
      TimelineEvent(
        title: 'Annual wellness checkup',
        description: 'Scheduled with Metro Pediatrics Clinic.',
        date: now.subtract(const Duration(days: 12)),
        type: TimelineEventType.health,
        icon: Icons.favorite_rounded,
      ),
      TimelineEvent(
        title: 'Tuition invoice generated',
        description: 'Invoice #1042 for spring semester.',
        date: now.subtract(const Duration(days: 18)),
        type: TimelineEventType.billing,
        icon: Icons.receipt_long_rounded,
      ),
      TimelineEvent(
        title: 'Science fair project submitted',
        description: 'STEM activity pack presentation approved.',
        date: now.subtract(const Duration(days: 25)),
        type: TimelineEventType.academic,
        icon: Icons.science_rounded,
      ),
    ]);

    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  static List<InvoiceItem> invoicesFor(List<ChildModel> children) {
    final primary = children.isNotEmpty ? children.first.name : 'Student';
    final secondary = children.length > 1 ? children[1].name : primary;
    final now = DateTime.now();

    return [
      InvoiceItem(
        id: '1042',
        title: 'Spring Tuition',
        childName: primary,
        amount: 420,
        dueDate: now.add(const Duration(days: 5)),
        isPaid: false,
      ),
      InvoiceItem(
        id: '1038',
        title: 'After-school Program',
        childName: secondary,
        amount: 120,
        dueDate: now.add(const Duration(days: 12)),
        isPaid: false,
      ),
      InvoiceItem(
        id: '1029',
        title: 'Uniform Bundle',
        childName: primary,
        amount: 64.99,
        dueDate: now.subtract(const Duration(days: 8)),
        isPaid: true,
      ),
      InvoiceItem(
        id: '1015',
        title: 'Field Trip Fee',
        childName: secondary,
        amount: 35,
        dueDate: now.subtract(const Duration(days: 22)),
        isPaid: true,
      ),
    ];
  }

  static Color colorForEventType(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.academic:
        return const Color(0xFF4A90E2);
      case TimelineEventType.health:
        return const Color(0xFF7ED321);
      case TimelineEventType.billing:
        return const Color(0xFFE2894A);
      case TimelineEventType.general:
        return const Color(0xFF9013FE);
    }
  }
}
