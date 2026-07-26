import '../catalog/academic_catalog.dart';
import '../config/school_config.dart';

/// Normalizes grade names so "Grade 1" and "grade 1" are treated as duplicates.
class GradeNaming {
  GradeNaming._();

  static String normalizeKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int computeSortOrder(String name, Iterable<int> existingOrders) {
    final parsed = AcademicCatalog.parseGradeLevel(name);
    if (parsed != null) return parsed;
    if (existingOrders.isEmpty) return 1;
    return existingOrders.reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Badge text for UI (grade number, K, or first letter).
  static String displayBadge(String gradeName, int sortOrder) {
    final lower = gradeName.trim().toLowerCase();
    if (lower.startsWith('kindergarten') || lower == 'kg' || lower == 'k') {
      return 'K';
    }
    final level = AcademicCatalog.parseGradeLevel(gradeName);
    if (level != null) return '$level';
    if (gradeName.isNotEmpty) return gradeName[0].toUpperCase();
    return '$sortOrder';
  }
}

/// Whether a section is ready for parent enrollment (all subject slots have teachers).
class SectionEnrollmentStatus {
  final bool hasSubjectSlots;
  final bool canEnroll;
  final List<String> assignedSubjectNames;
  final List<String> unassignedSubjectNames;

  const SectionEnrollmentStatus({
    required this.hasSubjectSlots,
    required this.canEnroll,
    this.assignedSubjectNames = const [],
    this.unassignedSubjectNames = const [],
  });

  String get blockingMessage {
    if (!hasSubjectSlots) {
      return SchoolConfig.gradeOnlyEnrollment
          ? 'This grade has no subjects set up yet. Ask the school admin to configure '
              'subjects and assign teachers before enrolling.'
          : 'This class has no subjects set up yet. Ask the school admin to configure '
              'subjects and assign teachers before enrolling.';
    }
    if (unassignedSubjectNames.isEmpty) return '';
    final subjects = unassignedSubjectNames.join(', ');
    return 'Teachers are not assigned yet for: $subjects. '
        'The school admin has been notified. You will receive an alert when enrollment opens for this grade.';
  }
}
