import '../../models/class_room_model.dart';
import '../../models/class_subject_model.dart';
import '../../models/grade_level_model.dart';

/// Defines which grades/class rooms a teacher's roster includes.
class TeacherRosterScope {
  final Set<String> gradeIds;
  final Set<String> classRoomIds;
  final Set<String> gradeNameKeys;
  final String schoolId;

  const TeacherRosterScope({
    required this.gradeIds,
    required this.classRoomIds,
    required this.gradeNameKeys,
    this.schoolId = '',
  });

  bool get isEmpty =>
      gradeIds.isEmpty && classRoomIds.isEmpty && gradeNameKeys.isEmpty;

  /// Same inputs as [TeacherOverviewProvider] slot resolution — keeps UI and roster aligned.
  static TeacherRosterScope fromAssignments({
    required List<ClassSubjectModel> assignments,
    required List<ClassRoomModel> classes,
    required List<GradeLevelModel> grades,
    String schoolId = '',
  }) {
    final gradeIds = <String>{};
    final classRoomIds = <String>{};
    final gradeNameKeys = <String>{};

    for (final assignment in assignments) {
      if (!assignment.isActive) continue;
      if (assignment.classRoomId.isNotEmpty) {
        classRoomIds.add(assignment.classRoomId);
      }

      ClassRoomModel? room;
      for (final c in classes) {
        if (c.id == assignment.classRoomId) {
          room = c;
          break;
        }
      }
      if (room == null) continue;

      if (room.gradeLevelId.isNotEmpty) {
        gradeIds.add(room.gradeLevelId);
      }
      if (room.name.isNotEmpty) {
        gradeNameKeys.add(_normalizeGradeName(room.name));
      }

      for (final g in grades) {
        if (g.id == room.gradeLevelId && g.name.isNotEmpty) {
          gradeNameKeys.add(_normalizeGradeName(g.name));
        }
      }
    }

    return TeacherRosterScope(
      gradeIds: gradeIds,
      classRoomIds: classRoomIds,
      gradeNameKeys: gradeNameKeys,
      schoolId: schoolId,
    );
  }

  TeacherRosterScope merge(TeacherRosterScope other) {
    return TeacherRosterScope(
      gradeIds: {...gradeIds, ...other.gradeIds},
      classRoomIds: {...classRoomIds, ...other.classRoomIds},
      gradeNameKeys: {...gradeNameKeys, ...other.gradeNameKeys},
      schoolId: schoolId.isNotEmpty ? schoolId : other.schoolId,
    );
  }

  static String _normalizeGradeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
