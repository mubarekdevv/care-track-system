import '../../core/academic/teacher_roster_scope.dart';
import '../../models/enrollment_model.dart';
import '../../models/student_model.dart';

/// Student profiles (`children` collection) and enrollments.
abstract class StudentRepository {
  Stream<List<StudentModel>> watchStudentsByParent(String parentId);
  Stream<StudentModel?> watchStudent(String studentId);
  Future<String> createStudent(StudentModel student);
  Future<void> updateStudent(StudentModel student);
  Future<void> deleteStudent(String studentId);

  /// Creates enrollment + updates student denormalized class/grade fields.
  Future<EnrollmentModel> enrollStudent({
    required StudentModel student,
    required String classRoomId,
    required String gradeLevelId,
  });

  Stream<List<EnrollmentModel>> watchEnrollmentsByClass(String classRoomId);
  Stream<List<StudentModel>> watchStudentsForClass(String classRoomId);
  Stream<EnrollmentModel?> watchActiveEnrollment(String studentId);

  /// Teacher roster — students in grades/classes this teacher teaches.
  Stream<List<StudentModel>> watchStudentsForTeacher(
    String teacherId, {
    TeacherRosterScope? scopeHint,
  });

  /// Student self-login link.
  Future<void> linkStudentAccount({
    required String studentId,
    required String studentUserId,
  });
}
