import '../../models/academic_models.dart';

/// Attendance, assignments, and assessments — no synthetic data.
abstract class AcademicRepository {
  Stream<List<AttendanceRecordModel>> watchAttendanceForClass(
    String classRoomId,
    DateTime date,
  );

  Future<void> markAttendance(AttendanceRecordModel record);

  Stream<List<AssignmentModel>> watchAssignmentsForClass(String classRoomId);
  Stream<List<AssignmentModel>> watchAssignmentsForTeacher(String teacherId);
  Stream<List<AssignmentModel>> watchAssignmentsForStudent(
    String studentId, {
    String? classRoomIdHint,
  });
  Future<String> createAssignment(AssignmentModel assignment);

  Future<void> submitHomeworkCompletion({
    required AssignmentModel assignment,
    required String studentId,
    required String studentName,
    required String submittedByUserId,
  });

  Stream<Set<String>> watchCompletedAssignmentIdsForStudent(String studentId);

  Stream<List<AssignmentSubmissionModel>> watchSubmissionsForAssignment(
    String assignmentId,
  );

  Stream<List<AssignmentSubmissionModel>> watchSubmissionsForTeacher(
    String teacherId,
  );

  Future<void> saveStudentGamification({
    required String studentId,
    required int xp,
    required int level,
    required List<String> unlockedBadges,
  });

  Stream<List<AssessmentModel>> watchPublishedAssessmentsForStudent(
    String studentId,
  );

  Stream<List<AttendanceRecordModel>> watchRecentAttendanceForStudent(
    String studentId, {
    int maxRecords = 14,
  });

  Stream<List<AssessmentModel>> watchAssessmentsForTeacher(String teacherId);
  Future<String> createAssessment(AssessmentModel assessment);
  Future<void> publishAssessment(String assessmentId);
}
