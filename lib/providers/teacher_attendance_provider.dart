import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_academic_repository.dart';
import '../models/academic_models.dart';
import '../models/student_model.dart';
import 'teacher_overview_provider.dart';

/// Attendance uses the same roster as [TeacherOverviewProvider] so counts match the UI.
class TeacherAttendanceProvider with ChangeNotifier {
  final FirestoreAcademicRepository _academic;

  TeacherAttendanceProvider({
    FirestoreAcademicRepository? academic,
  }) : _academic = academic ?? FirestoreAcademicRepository();

  List<StudentModel> roster = [];
  final Map<String, bool> presentByStudentId = {};
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  final List<StreamSubscription<List<AttendanceRecordModel>>> _classSubs = [];
  VoidCallback? _overviewListener;
  TeacherOverviewProvider? _overview;

  DateTime get _today => DateTime.now();

  void bindToOverview(TeacherOverviewProvider overview) {
    if (_overview == overview) return;
    stopListening();
    _overview = overview;
    isLoading = overview.isLoading;
    roster = List<StudentModel>.from(overview.roster);
    error = overview.error;

    _overviewListener = () => _syncFromOverview();
    overview.addListener(_overviewListener!);
    _syncFromOverview();
  }

  void _syncFromOverview() {
    final overview = _overview;
    if (overview == null) return;

    isLoading = overview.isLoading;
    error = overview.error;
    final nextRoster = List<StudentModel>.from(overview.roster);
    final rosterChanged = roster.length != nextRoster.length ||
        roster.any((s) => !nextRoster.any((n) => n.id == s.id));
    roster = nextRoster;

    if (rosterChanged) {
      unawaited(_reloadTodayAttendance().then((_) {
        _resubscribeClassStreams(roster);
        notifyListeners();
      }));
    } else {
      notifyListeners();
    }
  }

  void _resubscribeClassStreams(List<StudentModel> list) {
    for (final sub in _classSubs) {
      sub.cancel();
    }
    _classSubs.clear();

    final classIds = list
        .map((s) => s.classRoomId)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();

    for (final classId in classIds) {
      _classSubs.add(
        _academic.watchAttendanceForClass(classId, _today).listen((_) async {
          await _reloadTodayAttendance();
          notifyListeners();
        }),
      );
    }
  }

  Future<void> _reloadTodayAttendance() async {
    if (roster.isEmpty) {
      presentByStudentId.clear();
      return;
    }
    final statuses = await _academic.fetchAttendanceForStudentsOnDate(
      studentIds: roster.map((s) => s.id).toList(),
      date: _today,
    );
    for (final student in roster) {
      final status = statuses[student.id];
      if (status == null) {
        presentByStudentId.putIfAbsent(student.id, () => true);
      } else {
        presentByStudentId[student.id] = status == AttendanceStatus.present ||
            status == AttendanceStatus.late ||
            status == AttendanceStatus.excused;
      }
    }
  }

  bool isPresent(String studentId) => presentByStudentId[studentId] ?? true;

  Future<void> setPresent({
    required StudentModel student,
    required String teacherId,
    required bool present,
  }) async {
    presentByStudentId[student.id] = present;
    notifyListeners();

    isSaving = true;
    notifyListeners();

    try {
      final classRoomId = student.classRoomId ?? '';
      if (classRoomId.isEmpty) {
        error = 'Student has no grade assignment.';
        return;
      }

      await _academic.markAttendance(
        AttendanceRecordModel(
          id: AttendanceRecordModel.compositeId(student.id, _today),
          schoolId: student.schoolId.isNotEmpty
              ? student.schoolId
              : SchoolConfig.defaultSchoolId,
          studentId: student.id,
          classRoomId: classRoomId,
          date: _today,
          status: present ? AttendanceStatus.present : AttendanceStatus.absent,
          markedBy: teacherId,
          markedAt: DateTime.now(),
        ),
      );
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void stopListening() {
    if (_overviewListener != null && _overview != null) {
      _overview!.removeListener(_overviewListener!);
    }
    _overviewListener = null;
    _overview = null;
    for (final sub in _classSubs) {
      sub.cancel();
    }
    _classSubs.clear();
    roster = [];
    presentByStudentId.clear();
    isLoading = true;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
