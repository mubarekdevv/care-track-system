import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_academic_repository.dart';
import '../data/firestore/firestore_school_structure_repository.dart';
import '../models/academic_models.dart';
import '../models/child_model.dart';
import '../models/class_subject_model.dart';

class ChildQuest {
  final String id;
  final String title;
  final String subject;
  final int xp;
  final String dueDate;
  final Color color;
  bool completed;

  ChildQuest({
    required this.id,
    required this.title,
    required this.subject,
    required this.xp,
    required this.dueDate,
    required this.color,
    this.completed = false,
  });
}

class ChildBadge {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  bool unlocked;

  ChildBadge({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });
}

class ScheduleItem {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int hour;
  final int minute;

  const ScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.hour,
    required this.minute,
  });
}

/// Gamification shell for the child dashboard. Homework quests load from Firestore
/// when the student account is linked and enrolled in a class.
class ChildGamificationProvider extends ChangeNotifier {
  static const int xpPerLevel = 500;

  static const _questColors = [
    Color(0xFF4A90E2),
    Color(0xFF7ED321),
    Color(0xFF9013FE),
    Color(0xFFE2894A),
    Color(0xFF50E3C2),
  ];

  final FirestoreAcademicRepository _academic = FirestoreAcademicRepository();

  int currentXp = 120;
  int currentLevel = 2;

  final List<ChildQuest> quests = [];
  final Set<String> _completedQuestIds = {};
  final Map<String, AssignmentModel> _assignmentsById = {};
  String? _activeStudentId;
  bool isSubmittingQuest = false;

  bool isLiveHomework = false;
  bool isHomeworkLoading = false;
  String? homeworkStatusMessage;

  StreamSubscription<List<AssignmentModel>>? _homeworkSub;
  StreamSubscription<Set<String>>? _completionsSub;
  StreamSubscription<List<ClassSubjectModel>>? _scheduleSub;
  StreamSubscription<List<AttendanceRecordModel>>? _attendanceSub;
  List<ClassSubjectModel> _lastClassSubjects = [];
  String? Function(String subjectId)? _cachedSubjectNameFor;

  final List<ScheduleItem> todaySchedule = [];
  String? attendanceTodayLabel;
  bool isScheduleLive = false;

  final List<ChildBadge> badges = [
    ChildBadge(
      title: 'Math Whiz',
      description: 'Complete 3 homework quests',
      icon: Icons.calculate_rounded,
      color: const Color(0xFF4A90E2),
    ),
    ChildBadge(
      title: 'Perfect Attendance',
      description: 'Check in every day for 2 consecutive weeks',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF7ED321),
    ),
    ChildBadge(
      title: 'Star Student',
      description: 'Score 90%+ on a published grade',
      icon: Icons.star_rounded,
      color: Colors.amber,
    ),
    ChildBadge(
      title: 'Helper Bee',
      description: 'Marked helpful in classroom peer activities',
      icon: Icons.pest_control_rodent_rounded,
      color: Colors.pinkAccent,
    ),
    ChildBadge(
      title: 'Science Explorer',
      description: 'Finish a science homework quest',
      icon: Icons.biotech_rounded,
      color: const Color(0xFF9013FE),
    ),
    ChildBadge(
      title: 'Fast Learner',
      description: 'Complete all homework quests for your class',
      icon: Icons.bolt_rounded,
      color: Colors.cyan,
    ),
  ];

  static const schedule = [
    ScheduleItem(
      time: '08:30 AM',
      title: 'Mathematics Class',
      subtitle: 'Learn divisions',
      icon: Icons.calculate_rounded,
      color: Color(0xFF4A90E2),
      hour: 8,
      minute: 30,
    ),
    ScheduleItem(
      time: '10:00 AM',
      title: 'Recess & Playtime',
      subtitle: 'Outdoor games',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF7ED321),
      hour: 10,
      minute: 0,
    ),
    ScheduleItem(
      time: '11:00 AM',
      title: 'Reading Session',
      subtitle: 'Storytelling module',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF9013FE),
      hour: 11,
      minute: 0,
    ),
    ScheduleItem(
      time: '01:30 PM',
      title: 'Creative Arts',
      subtitle: 'Watercolor painting',
      icon: Icons.palette_rounded,
      color: Color(0xFFE2894A),
      hour: 13,
      minute: 30,
    ),
  ];

  int get unlockedBadgeCount => badges.where((b) => b.unlocked).length;

  int get pendingQuestCount => quests.where((q) => !q.completed).length;

  double get xpProgress => (currentXp / xpPerLevel).clamp(0.0, 1.0);

  String get rankTitle {
    if (currentLevel >= 5) return 'Legend';
    if (currentLevel >= 4) return 'Elite IV';
    if (currentLevel >= 3) return 'Elite III';
    if (currentLevel >= 2) return 'Rising Star';
    return 'New Explorer';
  }

  List<ScheduleItem> get activeSchedule =>
      todaySchedule.isNotEmpty ? todaySchedule : schedule;

  ScheduleItem? get currentScheduleItem {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    ScheduleItem? active;
    for (final item in activeSchedule) {
      final itemMinutes = item.hour * 60 + item.minute;
      if (itemMinutes <= nowMinutes) active = item;
    }
    return active;
  }

  ScheduleItem? get nextScheduleItem {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    for (final item in activeSchedule) {
      final itemMinutes = item.hour * 60 + item.minute;
      if (itemMinutes > nowMinutes) return item;
    }
    return null;
  }

  static const _slotTimes = [
    (8, 30),
    (10, 0),
    (11, 30),
    (13, 30),
    (15, 0),
  ];

  /// Loads saved XP, level, and badges from the linked `children` profile.
  void applyGamificationFromChild(ChildModel? child) {
    if (child == null) return;
    if (child.gamificationXp > 0) currentXp = child.gamificationXp;
    if (child.gamificationLevel >= 1) currentLevel = child.gamificationLevel;
    for (final badge in badges) {
      badge.unlocked = child.unlockedBadges.contains(badge.title);
    }
    notifyListeners();
  }

  void bindStudentExperience({
    required bool isAccountLinked,
    required String? studentId,
    required String? classRoomId,
    required String? Function(String subjectId) subjectNameFor,
    ChildModel? linkedChild,
  }) {
    applyGamificationFromChild(linkedChild);
    bindHomework(
      isAccountLinked: isAccountLinked,
      studentId: studentId,
      classRoomId: classRoomId,
      subjectNameFor: subjectNameFor,
    );
    bindTodaySchedule(
      classRoomId: classRoomId,
      subjectNameFor: subjectNameFor,
    );
    bindAttendanceToday(studentId: studentId);
  }

  void bindTodaySchedule({
    required String? classRoomId,
    required String? Function(String subjectId) subjectNameFor,
  }) {
    _scheduleSub?.cancel();
    todaySchedule.clear();
    isScheduleLive = false;

    if (classRoomId == null || classRoomId.isEmpty) {
      notifyListeners();
      return;
    }

    final structure = FirestoreSchoolStructureRepository();
    _cachedSubjectNameFor = subjectNameFor;
    _scheduleSub = structure.watchClassSubjects(classRoomId).listen(
      (assignments) {
        _lastClassSubjects = assignments;
        _rebuildTodaySchedule();
      },
      onError: (_) {
        isScheduleLive = false;
        notifyListeners();
      },
    );
  }

  void _rebuildTodaySchedule() {
    final subjectNameFor = _cachedSubjectNameFor;
    if (subjectNameFor == null) return;
    todaySchedule
      ..clear()
      ..addAll(_scheduleFromSubjects(_lastClassSubjects, subjectNameFor));
    isScheduleLive = todaySchedule.isNotEmpty;
    notifyListeners();
  }

  List<ScheduleItem> _scheduleFromSubjects(
    List<ClassSubjectModel> subjects,
    String? Function(String subjectId) subjectNameFor,
  ) {
    if (subjects.isEmpty) return [];

    final sorted = List<ClassSubjectModel>.from(subjects)
      ..sort((a, b) {
        final an = subjectNameFor(a.subjectId) ?? '';
        final bn = subjectNameFor(b.subjectId) ?? '';
        return an.compareTo(bn);
      });

    final items = <ScheduleItem>[];
    for (var i = 0; i < sorted.length; i++) {
      final subjectName = subjectNameFor(sorted[i].subjectId) ?? 'Class';
      final slot = _slotTimes[i % _slotTimes.length];
      final hour = slot.$1;
      final minute = slot.$2;
      final timeLabel = _formatTime(hour, minute);
      items.add(
        ScheduleItem(
          time: timeLabel,
          title: '$subjectName Class',
          subtitle: 'With your ${subjectName.toLowerCase()} teacher',
          icon: _iconForSubject(subjectName),
          color: _questColors[i % _questColors.length],
          hour: hour,
          minute: minute,
        ),
      );
    }

    for (final quest in quests.where((q) => !q.completed)) {
      items.add(
        ScheduleItem(
          time: 'After school',
          title: 'Homework: ${quest.title}',
          subtitle: quest.dueDate,
          icon: Icons.assignment_rounded,
          color: quest.color,
          hour: 16,
          minute: 0,
        ),
      );
    }

    items.sort((a, b) {
      final am = a.hour * 60 + a.minute;
      final bm = b.hour * 60 + b.minute;
      return am.compareTo(bm);
    });
    return items;
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  static IconData _iconForSubject(String name) {
    final n = name.toLowerCase();
    if (n.contains('math')) return Icons.calculate_rounded;
    if (n.contains('english') || n.contains('reading')) return Icons.menu_book_rounded;
    if (n.contains('science')) return Icons.biotech_rounded;
    if (n.contains('art') || n.contains('music')) return Icons.palette_rounded;
    if (n.contains('sport') || n.contains('physical')) return Icons.sports_soccer_rounded;
    return Icons.school_rounded;
  }

  void bindAttendanceToday({required String? studentId}) {
    _attendanceSub?.cancel();
    attendanceTodayLabel = null;
    if (studentId == null || studentId.isEmpty) {
      notifyListeners();
      return;
    }

    _attendanceSub = _academic
        .watchRecentAttendanceForStudent(studentId, maxRecords: 3)
        .listen((records) {
      final today = DateTime.now();
      AttendanceRecordModel? todayRecord;
      for (final r in records) {
        final d = r.date;
        if (d.year == today.year && d.month == today.month && d.day == today.day) {
          todayRecord = r;
          break;
        }
      }
      if (todayRecord == null) {
        attendanceTodayLabel = 'Attendance not marked yet today';
      } else {
        attendanceTodayLabel = todayRecord.status == AttendanceStatus.present
            ? 'Marked present today'
            : 'Marked ${todayRecord.status.id} today';
      }
      notifyListeners();
    });
  }

  void bindHomework({
    required bool isAccountLinked,
    required String? studentId,
    required String? classRoomId,
    required String? Function(String subjectId) subjectNameFor,
  }) {
    _homeworkSub?.cancel();
    _homeworkSub = null;
    _completionsSub?.cancel();
    _completionsSub = null;
    quests.clear();
    _assignmentsById.clear();
    _activeStudentId = studentId;
    isLiveHomework = false;
    isHomeworkLoading = false;
    homeworkStatusMessage = null;

    if (!isAccountLinked || studentId == null || studentId.isEmpty) {
      homeworkStatusMessage =
          'Link your school profile with the code from your parent to see real homework.';
      notifyListeners();
      return;
    }

    isLiveHomework = true;
    isHomeworkLoading = true;
    homeworkStatusMessage = null;
    notifyListeners();

    _completionsSub =
        _academic.watchCompletedAssignmentIdsForStudent(studentId).listen(
      (completedIds) {
        _completedQuestIds
          ..clear()
          ..addAll(completedIds);
        if (_assignmentsById.isNotEmpty) {
          _syncQuestsFromAssignments(
            _assignmentsById.values.toList(),
            subjectNameFor,
          );
        }
        notifyListeners();
      },
    );

    _homeworkSub = _academic
        .watchAssignmentsForStudent(studentId, classRoomIdHint: classRoomId)
        .listen(
      (assignments) {
        _syncQuestsFromAssignments(assignments, subjectNameFor);
        isHomeworkLoading = false;
        if (assignments.isEmpty) {
          homeworkStatusMessage = classRoomId == null || classRoomId.isEmpty
              ? 'Ask your parent to finish enrolling you in a grade — then homework from teachers will appear.'
              : 'No homework from your teachers yet — check back soon!';
        } else {
          homeworkStatusMessage = null;
        }
        _rebuildTodaySchedule();
        notifyListeners();
      },
      onError: (_) {
        isHomeworkLoading = false;
        homeworkStatusMessage = 'Could not load homework. Pull to refresh later.';
        notifyListeners();
      },
    );
  }

  void unbindHomework() {
    _homeworkSub?.cancel();
    _homeworkSub = null;
    _completionsSub?.cancel();
    _completionsSub = null;
    _assignmentsById.clear();
    _activeStudentId = null;
    _scheduleSub?.cancel();
    _scheduleSub = null;
    _attendanceSub?.cancel();
    _attendanceSub = null;
    quests.clear();
    todaySchedule.clear();
    isScheduleLive = false;
    attendanceTodayLabel = null;
    isLiveHomework = false;
    isHomeworkLoading = false;
    homeworkStatusMessage = null;
    notifyListeners();
  }

  void _syncQuestsFromAssignments(
    List<AssignmentModel> assignments,
    String? Function(String subjectId) subjectNameFor,
  ) {
    final previousCompleted = Set<String>.from(_completedQuestIds);
    quests.clear();
    _assignmentsById.clear();

    for (var i = 0; i < assignments.length; i++) {
      final a = assignments[i];
      _assignmentsById[a.id] = a;
      final subject = subjectNameFor(a.subjectId) ?? 'Subject';
      quests.add(
        ChildQuest(
          id: a.id,
          title: a.title,
          subject: subject,
          xp: 40 + (i % 4) * 10,
          dueDate: _dueLabel(a.dueAt),
          color: _questColors[i % _questColors.length],
          completed: previousCompleted.contains(a.id),
        ),
      );
    }
  }

  static String _dueLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final diff = due.difference(DateTime.now());
    if (diff.inDays < 0) return 'Overdue';
    if (diff.inHours < 24 && diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    return 'Due in ${diff.inDays} days';
  }

  /// Student turns in homework — saved to Firestore and teacher is notified.
  Future<String?> completeQuestAsync({
    required String questId,
    required String studentName,
    required String submittedByUserId,
    required void Function() onLevelUp,
  }) async {
    ChildQuest? quest;
    for (final q in quests) {
      if (q.id == questId) {
        quest = q;
        break;
      }
    }
    final assignment = _assignmentsById[questId];
    final studentId = _activeStudentId;
    if (quest == null ||
        quest.completed ||
        assignment == null ||
        studentId == null ||
        studentId.isEmpty) {
      return null;
    }

    isSubmittingQuest = true;
    notifyListeners();

    try {
      await _academic.submitHomeworkCompletion(
        assignment: assignment,
        studentId: studentId,
        studentName: studentName,
        submittedByUserId: submittedByUserId,
      );
    } catch (_) {
      isSubmittingQuest = false;
      notifyListeners();
      rethrow;
    }

    quest.completed = true;
    _completedQuestIds.add(questId);
    currentXp += quest.xp;

    String? unlockedBadge;
    final completedCount = quests.where((q) => q.completed).length;

    if (quest.subject.toLowerCase().contains('science')) {
      unlockedBadge = _unlockBadge('Science Explorer') ?? unlockedBadge;
    }
    if (completedCount >= 3) {
      unlockedBadge = _unlockBadge('Math Whiz') ?? unlockedBadge;
    }
    if (quests.isNotEmpty && quests.every((q) => q.completed)) {
      unlockedBadge = _unlockBadge('Fast Learner') ?? unlockedBadge;
    }

    if (currentXp >= xpPerLevel) {
      currentLevel++;
      currentXp -= xpPerLevel;
      onLevelUp();
    }

    await _persistGamification(studentId);

    isSubmittingQuest = false;
    _rebuildTodaySchedule();
    notifyListeners();
    return unlockedBadge;
  }

  Future<void> _persistGamification(String studentId) async {
    final unlocked = badges.where((b) => b.unlocked).map((b) => b.title).toList();
    try {
      await _academic.saveStudentGamification(
        studentId: studentId,
        xp: currentXp,
        level: currentLevel,
        unlockedBadges: unlocked,
      );
    } catch (_) {
      // XP still applies locally if offline.
    }
  }

  String? _unlockBadge(String title) {
    final badge = badges.firstWhere((b) => b.title == title);
    if (badge.unlocked) return null;
    badge.unlocked = true;
    return badge.title;
  }

  @override
  void dispose() {
    _homeworkSub?.cancel();
    _completionsSub?.cancel();
    _scheduleSub?.cancel();
    _attendanceSub?.cancel();
    super.dispose();
  }
}
