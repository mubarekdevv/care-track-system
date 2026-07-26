import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/school_config.dart';
import '../data/firestore/firestore_academic_repository.dart';
import '../data/firestore/firestore_student_repository.dart';
import '../models/academic_models.dart';
import '../models/student_model.dart';
import '../models/teacher_teaching_slot.dart';

class TeacherHomeworkProvider with ChangeNotifier {
  final FirestoreAcademicRepository _academic;
  final FirestoreStudentRepository _students;

  TeacherHomeworkProvider({
    FirestoreAcademicRepository? academic,
    FirestoreStudentRepository? students,
  })  : _academic = academic ?? FirestoreAcademicRepository(),
        _students = students ?? FirestoreStudentRepository();

  List<AssignmentModel> assignments = [];
  List<AssignmentSubmissionModel> submissions = [];
  bool isLoading = true;
  String? error;

  StreamSubscription<List<AssignmentModel>>? _assignmentsSub;
  StreamSubscription<List<AssignmentSubmissionModel>>? _submissionsSub;

  int submissionCountFor(String assignmentId) =>
      submissions.where((s) => s.assignmentId == assignmentId).length;

  Set<String> submittedStudentIdsFor(String assignmentId) => submissions
      .where((s) => s.assignmentId == assignmentId)
      .map((s) => s.studentId)
      .toSet();

  void startListening(String teacherId) {
    _assignmentsSub?.cancel();
    _submissionsSub?.cancel();
    isLoading = true;
    error = null;
    notifyListeners();

    var assignmentsReady = false;
    var submissionsReady = false;

    void maybeDone() {
      if (assignmentsReady && submissionsReady) {
        isLoading = false;
        notifyListeners();
      }
    }

    _assignmentsSub = _academic.watchAssignmentsForTeacher(teacherId).listen(
      (list) {
        assignments = list;
        assignmentsReady = true;
        maybeDone();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );

    _submissionsSub = _academic.watchSubmissionsForTeacher(teacherId).listen(
      (list) {
        submissions = list;
        submissionsReady = true;
        maybeDone();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> publishAssignment({
    required String teacherId,
    required TeacherTeachingSlot slot,
    required String title,
    String? description,
    required DateTime dueAt,
  }) async {
    error = null;
    notifyListeners();
    try {
      await _academic.createAssignment(
        AssignmentModel(
          id: '',
          schoolId: SchoolConfig.defaultSchoolId,
          classRoomId: slot.classRoomId,
          subjectId: slot.subjectId,
          teacherId: teacherId,
          title: title.trim(),
          description: description?.trim().isEmpty == true ? null : description?.trim(),
          dueAt: dueAt,
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> publishGradesForAssignment({
    required String teacherId,
    required AssignmentModel assignment,
    required Map<String, double> scoresByStudentId,
    required List<StudentModel> classRoster,
  }) async {
    var saved = 0;
    error = null;
    try {
      for (final student in classRoster) {
        final score = scoresByStudentId[student.id];
        if (score == null) continue;

        final enrollment =
            await _students.watchActiveEnrollment(student.id).first;
        await _academic.createAssessment(
          AssessmentModel(
            id: '',
            schoolId: assignment.schoolId.isNotEmpty
                ? assignment.schoolId
                : SchoolConfig.defaultSchoolId,
            studentId: student.id,
            enrollmentId: enrollment?.id ?? '',
            subjectId: assignment.subjectId,
            teacherId: teacherId,
            title: assignment.title,
            score: score,
            maxScore: 100,
            publishedAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );
        saved++;
      }
      return saved;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void stopListening() {
    _assignmentsSub?.cancel();
    _assignmentsSub = null;
    _submissionsSub?.cancel();
    _submissionsSub = null;
    assignments = [];
    submissions = [];
    isLoading = true;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
