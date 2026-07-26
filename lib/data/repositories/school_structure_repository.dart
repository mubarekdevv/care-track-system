import '../../models/class_room_model.dart';
import '../../models/class_subject_model.dart';
import '../../models/grade_level_model.dart';
import '../../models/school_model.dart';
import '../../models/subject_model.dart';
import '../../models/user_model.dart';

/// Admin-driven school structure — grades, classes, subjects, teacher assignments.
abstract class SchoolStructureRepository {
  Future<SchoolModel?> getSchool(String schoolId);
  Stream<SchoolModel?> watchSchool(String schoolId);

  Future<void> updateSchoolName(String schoolId, String name);

  Future<void> updateMaxCatalogGradeLevel(String schoolId, int level);

  Future<void> updateEnabledHealthSpecialties(
    String schoolId,
    List<String> specialtyIds,
  );

  Stream<List<GradeLevelModel>> watchGradeLevels(String schoolId);
  Future<String> createGradeLevel(GradeLevelModel grade);
  Future<void> updateGradeLevel(GradeLevelModel grade);

  /// Any grade document for this catalog level (includes soft-deleted).
  Future<GradeLevelModel?> findGradeByCatalogLevel(String schoolId, int catalogLevel);

  Future<List<ClassRoomModel>> fetchClassRoomsForGrade(
    String schoolId,
    String gradeLevelId,
  );

  Stream<List<ClassRoomModel>> watchClassRooms(String schoolId, {String? gradeLevelId});
  Future<String> createClassRoom(ClassRoomModel classRoom);
  Future<void> updateClassRoom(ClassRoomModel classRoom);

  Stream<List<SubjectModel>> watchSubjects(String schoolId);
  Future<String> createSubject(SubjectModel subject);
  Future<void> updateSubject(SubjectModel subject);

  Stream<List<ClassSubjectModel>> watchClassSubjects(String classRoomId);
  Stream<List<ClassSubjectModel>> watchSchoolClassSubjects(String schoolId);
  Stream<List<ClassSubjectModel>> watchTeacherAssignments(String teacherId);
  Future<String> assignTeacherToClassSubject(ClassSubjectModel assignment);
  Future<void> removeClassSubject(String classSubjectId);

  /// Resolves subject + teacher names for parent enrollment preview.
  Future<List<AssignedTeacherView>> getAssignedTeachersForClass(
    String classRoomId,
  );

  Stream<List<UserModel>> watchTeachers(String schoolId);

  Stream<List<UserModel>> watchHealthcareStaff(String schoolId);

  /// Teachers registered without a school link yet.
  Stream<List<UserModel>> watchPendingTeachers();

  Stream<List<UserModel>> watchPendingHealthcare();
}
