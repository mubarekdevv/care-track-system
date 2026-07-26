import 'dart:async';

import 'package:flutter/material.dart';

import '../core/academic/enrollment_display.dart';
import '../core/academic/grade_naming.dart';
import '../core/config/school_config.dart';
import '../data/firestore/firestore_school_structure_repository.dart';
import '../data/firestore/firestore_student_repository.dart';
import '../models/class_room_model.dart';
import '../models/class_subject_model.dart';
import '../models/grade_level_model.dart';
import '../models/subject_model.dart';
import '../models/student_model.dart';
import '../models/teacher_teaching_slot.dart';
import 'school_admin_provider.dart';

class TeacherOverviewProvider with ChangeNotifier {
  final FirestoreSchoolStructureRepository _structure;
  final FirestoreStudentRepository _students;

  TeacherOverviewProvider({
    FirestoreSchoolStructureRepository? structure,
    FirestoreStudentRepository? students,
  })  : _structure = structure ?? FirestoreSchoolStructureRepository(),
        _students = students ?? FirestoreStudentRepository();

  List<ClassSubjectModel> _rawAssignments = [];
  List<TeacherTeachingSlot> slots = [];
  List<StudentModel> roster = [];
  int rosterCount = 0;
  bool isLoading = true;
  String? error;

  StreamSubscription<List<ClassSubjectModel>>? _assignmentsSub;
  StreamSubscription<List<StudentModel>>? _rosterSub;
  SchoolAdminProvider? _school;
  VoidCallback? _schoolListener;

  String get badgeText {
    if (slots.isEmpty) {
      return SchoolConfig.gradeOnlyEnrollment
          ? 'No grade assignments yet — ask admin to link you'
          : 'No class assignments yet — ask admin to link you';
    }
    if (slots.length == 1) {
      final s = slots.first;
      return EnrollmentDisplay.teacherSlotLine(s.gradeName, s.className);
    }
    return '${slots.length} teaching slots · $rosterCount students';
  }

  void startListening({
    required String teacherId,
    required SchoolAdminProvider school,
  }) {
    stopListening();
    _school = school;
    isLoading = true;
    error = null;
    notifyListeners();

    _schoolListener = () {
      _resolveSlots();
      _restartRosterWatch();
      notifyListeners();
    };
    school.addListener(_schoolListener!);

    _assignmentsSub = _structure.watchTeacherAssignments(teacherId).listen(
      (list) {
        _rawAssignments = list;
        isLoading = false;
        _resolveSlots();
        _restartRosterWatch();
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Same class room IDs the admin panel uses for "Enrolled students (N)".
  Set<String> _classRoomIdsForRoster() {
    final school = _school;
    final ids = <String>{};
    for (final slot in slots) {
      if (slot.classRoomId.isNotEmpty) {
        ids.add(slot.classRoomId);
      }
      if (school != null) {
        final gradeId = school.gradeLevelIdForClassRoom(slot.classRoomId);
        if (gradeId != null && gradeId.isNotEmpty) {
          final primary = school.primaryClassForGrade(gradeId);
          if (primary != null) ids.add(primary.id);
        }
      }
    }
    return ids;
  }

  void _restartRosterWatch() {
    _rosterSub?.cancel();

    final classRoomIds = _classRoomIdsForRoster();
    if (classRoomIds.isEmpty) {
      roster = [];
      rosterCount = 0;
      notifyListeners();
      return;
    }

    _rosterSub = _students.watchStudentsForClassRooms(classRoomIds).listen(
      (students) {
        roster = students;
        rosterCount = students.length;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        notifyListeners();
      },
    );
  }

  int studentCountForClass(String classRoomId) {
    final gradeId = _school?.gradeLevelIdForClassRoom(classRoomId);
    final gradeName = gradeId != null ? _school?.gradeNameForId(gradeId) : null;
    final gradeKey = gradeName != null && gradeName.isNotEmpty
        ? GradeNaming.normalizeKey(gradeName)
        : null;

    return roster.where((s) {
      if (s.classRoomId == classRoomId) return true;
      if (gradeId != null &&
          gradeId.isNotEmpty &&
          s.gradeLevelId == gradeId) {
        return true;
      }
      if (gradeKey != null && _school != null) {
        final sName = _school!.gradeNameForId(s.gradeLevelId ?? '') ??
            _school!.gradeNameForClassRoom(s.classRoomId ?? '');
        if (sName != null &&
            sName.isNotEmpty &&
            GradeNaming.normalizeKey(sName) == gradeKey) {
          return true;
        }
      }
      return false;
    }).length;
  }

  void _resolveSlots() {
    final school = _school;
    if (school == null) return;

    final resolved = <TeacherTeachingSlot>[];
    for (final assignment in _rawAssignments) {
      final classRoom = _findClass(school.classes, assignment.classRoomId);
      if (classRoom == null) continue;

      final subject = _findSubject(school.subjects, assignment.subjectId);
      final grade = _findGrade(school.grades, classRoom.gradeLevelId);
      final subjectName = subject?.name ?? 'Subject';
      final accent = _accentForSubject(subjectName);

      resolved.add(
        TeacherTeachingSlot(
          subjectName: subjectName,
          className: SchoolConfig.gradeOnlyEnrollment
              ? (grade?.name ?? 'Grade')
              : classRoom.name,
          gradeName: grade?.name ?? 'Grade',
          classRoomId: classRoom.id,
          subjectId: assignment.subjectId,
          icon: _iconForSubject(subjectName),
          accentColor: accent,
        ),
      );
    }

    resolved.sort((a, b) => a.gradeName.compareTo(b.gradeName));
    slots = resolved;
  }

  ClassRoomModel? _findClass(List<ClassRoomModel> list, String id) {
    for (final c in list) {
      if (c.id == id) return c;
    }
    return null;
  }

  SubjectModel? _findSubject(List<SubjectModel> list, String id) {
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  }

  GradeLevelModel? _findGrade(List<GradeLevelModel> list, String id) {
    for (final g in list) {
      if (g.id == id) return g;
    }
    return null;
  }

  static IconData _iconForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('math')) return Icons.calculate_rounded;
    if (n.contains('english')) return Icons.menu_book_rounded;
    if (n.contains('science')) return Icons.biotech_rounded;
    if (n.contains('art') || n.contains('music')) return Icons.palette_rounded;
    if (n.contains('physical') || n.contains('sport')) {
      return Icons.sports_soccer_rounded;
    }
    return Icons.menu_book_rounded;
  }

  static Color _accentForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('math')) return const Color(0xFF4A90E2);
    if (n.contains('english')) return const Color(0xFF7ED321);
    if (n.contains('science')) return const Color(0xFF9013FE);
    if (n.contains('art') || n.contains('music')) return const Color(0xFFE2894A);
    return const Color(0xFF4A90E2);
  }

  void stopListening() {
    _assignmentsSub?.cancel();
    _assignmentsSub = null;
    _rosterSub?.cancel();
    _rosterSub = null;
    if (_schoolListener != null && _school != null) {
      _school!.removeListener(_schoolListener!);
    }
    _schoolListener = null;
    _school = null;
    _rawAssignments = [];
    slots = [];
    roster = [];
    rosterCount = 0;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
