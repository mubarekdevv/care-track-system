import '../../data/firestore/firestore_school_structure_repository.dart';
import '../../models/class_room_model.dart';
import '../../models/class_subject_model.dart';
import '../../models/grade_level_model.dart';
import '../../models/subject_model.dart';
import '../../providers/school_admin_provider.dart';
import '../catalog/academic_catalog.dart';

/// Resolves grade → class → teachers for parent enrollment preview.
class AcademicResolver {
  final FirestoreSchoolStructureRepository _structure;

  AcademicResolver({FirestoreSchoolStructureRepository? structure})
      : _structure = structure ?? FirestoreSchoolStructureRepository();

  List<ClassRoomModel> sectionsForGrade(
    String gradeLevelId,
    SchoolAdminProvider admin,
  ) {
    return admin.sectionsForGrade(gradeLevelId);
  }

  ClassRoomModel? defaultClassForGrade(
    String gradeLevelId,
    SchoolAdminProvider admin,
  ) {
    return admin.primaryClassForGrade(gradeLevelId);
  }

  CatalogGrade? catalogForGrade(GradeLevelModel grade) {
    if (grade.sortOrder > 0) {
      final byLevel = AcademicCatalog.byLevel(grade.sortOrder);
      if (byLevel != null) return byLevel;
    }
    final level = AcademicCatalog.parseGradeLevel(grade.name);
    if (level != null) return AcademicCatalog.byLevel(level);
    return AcademicCatalog.byDisplayName(grade.name);
  }

  Future<List<AssignedTeacherView>> teachersForClass(String classRoomId) {
    return _structure.getAssignedTeachersForClass(classRoomId);
  }

  Future<GradeEnrollmentPreview?> previewForGrade({
    required String gradeLevelId,
    required SchoolAdminProvider admin,
    String? classRoomId,
  }) async {
    return previewForGradeSync(
      gradeLevelId: gradeLevelId,
      admin: admin,
      classRoomId: classRoomId,
    );
  }

  /// Instant preview from admin cache — no Firestore round-trip (parent enroll UI).
  GradeEnrollmentPreview? previewForGradeSync({
    required String gradeLevelId,
    required SchoolAdminProvider admin,
    String? classRoomId,
  }) {
    GradeLevelModel? grade;
    for (final g in admin.grades) {
      if (g.id == gradeLevelId) {
        grade = g;
        break;
      }
    }
    if (grade == null) return null;

    ClassRoomModel? classRoom;
    if (classRoomId != null && classRoomId.isNotEmpty) {
      for (final c in admin.classes) {
        if (c.id == classRoomId) {
          classRoom = c;
          break;
        }
      }
    }
    classRoom ??= defaultClassForGrade(gradeLevelId, admin);
    if (classRoom == null) {
      final catalog = catalogForGrade(grade);
      if (catalog == null) return null;
      return GradeEnrollmentPreview(
        grade: grade,
        classRoom: null,
        teachers: catalog.subjects
            .map(
              (s) => AssignedTeacherView(
                subject: SubjectModel(
                  id: '',
                  schoolId: '',
                  name: s.subjectName,
                ),
                teacherId: '',
                teacherName: s.teacherName,
                teacherEmail: s.teacherEmail,
                subjectIconKey: s.subjectIcon,
                isLinked: false,
              ),
            )
            .toList(),
        fromCatalogOnly: true,
      );
    }

    var teachers = admin.assignedTeacherViewsForClass(classRoom.id);
    return GradeEnrollmentPreview(
      grade: grade,
      classRoom: classRoom,
      teachers: teachers,
      fromCatalogOnly: false,
    );
  }
}

class GradeEnrollmentPreview {
  final GradeLevelModel grade;
  final ClassRoomModel? classRoom;
  final List<AssignedTeacherView> teachers;
  final bool fromCatalogOnly;

  const GradeEnrollmentPreview({
    required this.grade,
    required this.classRoom,
    required this.teachers,
    this.fromCatalogOnly = false,
  });
}
