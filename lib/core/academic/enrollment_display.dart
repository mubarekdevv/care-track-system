import '../config/school_config.dart';
import '../../providers/school_admin_provider.dart';

/// Consistent enrollment labels — grade-only schools never show section codes (1-A, Section A).
class EnrollmentDisplay {
  EnrollmentDisplay._();

  /// Parent child card / list subtitle, e.g. "7 years old • Grade 1".
  static String childAgeAndGradeLine({
    required SchoolAdminProvider admin,
    required int age,
    String? gradeLevelId,
    String? classRoomId,
  }) {
    final grade = _gradeLabel(admin, gradeLevelId, classRoomId);
    if (grade != null && grade.isNotEmpty) {
      return '$age years old • $grade';
    }
    if (gradeLevelId == null &&
        (classRoomId == null || classRoomId.isEmpty)) {
      return SchoolConfig.gradeOnlyEnrollment
          ? '$age years old • Grade not assigned'
          : '$age years old • Class not assigned';
    }
    return SchoolConfig.gradeOnlyEnrollment
        ? '$age years old • Grade not assigned'
        : '$age years old • Class not assigned';
  }

  /// Short class/grade label for reports and headers.
  static String classOrGradeLabel(
    SchoolAdminProvider admin,
    String? classRoomId, {
    String? gradeLevelId,
    String fallback = 'Not enrolled',
  }) {
    final grade = _gradeLabel(admin, gradeLevelId, classRoomId);
    if (grade != null && grade.isNotEmpty) return grade;
    if (classRoomId == null || classRoomId.isEmpty) return fallback;
    return fallback;
  }

  static String teacherSlotLine(String gradeName, String className) {
    if (SchoolConfig.gradeOnlyEnrollment) return gradeName;
    if (className.trim().isEmpty) return gradeName;
    return '$gradeName · $className';
  }

  static String teachersForGradeTitle(String gradeName, {String? classRoomName}) {
    if (SchoolConfig.gradeOnlyEnrollment) {
      return 'Teachers for $gradeName';
    }
    if (classRoomName != null && classRoomName.isNotEmpty) {
      return 'Teachers for $classRoomName';
    }
    return 'Teachers for $gradeName';
  }

  static String? _gradeLabel(
    SchoolAdminProvider admin,
    String? gradeLevelId,
    String? classRoomId,
  ) {
    if (gradeLevelId != null) {
      final byId = admin.gradeNameForId(gradeLevelId);
      if (byId != null && byId.isNotEmpty) return byId;
    }
    if (classRoomId != null && classRoomId.isNotEmpty) {
      final fromRoom = admin.gradeNameForClassRoom(classRoomId);
      if (fromRoom != null && fromRoom.isNotEmpty) {
        if (SchoolConfig.gradeOnlyEnrollment &&
            _looksLikeLegacySectionName(fromRoom)) {
          for (final c in admin.classes) {
            if (c.id == classRoomId) {
              final gradeName = admin.gradeNameForId(c.gradeLevelId);
              if (gradeName != null && gradeName.isNotEmpty) return gradeName;
            }
          }
        }
        return fromRoom;
      }
    }
    return null;
  }

  static bool _looksLikeLegacySectionName(String name) {
    final n = name.trim();
    final lower = n.toLowerCase();
    if (lower.contains('section')) return true;
    if (RegExp(r'^\d+-[A-Za-z]$').hasMatch(n)) return true;
    if (RegExp(r'Grade\s+\d+\s*-\s*[A-Za-z]', caseSensitive: false).hasMatch(n)) {
      return true;
    }
    return false;
  }
}
