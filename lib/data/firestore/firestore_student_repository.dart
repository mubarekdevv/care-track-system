import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/academic/teacher_roster_scope.dart';
import '../../core/config/school_config.dart';
import '../../core/domain/domain_enums.dart';
import '../../models/enrollment_model.dart';
import '../../models/student_model.dart';
import '../repositories/student_repository.dart';
import 'firestore_helpers.dart';

class FirestoreStudentRepository implements StudentRepository {
  final FirebaseFirestore _db;

  FirestoreStudentRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _children =>
      _db.collection(FirestoreCollections.children);

  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _db.collection(FirestoreCollections.enrollments);

  @override
  Stream<List<StudentModel>> watchStudentsByParent(String parentId) {
    return _children
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StudentModel.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Stream<StudentModel?> watchStudent(String studentId) {
    return _children.doc(studentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StudentModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<String> createStudent(StudentModel student) async {
    final ref = _children.doc(student.id);
    await ref.set(
      FirestoreHelpers.withTimestamps(student.toMap(), isCreate: true),
    );
    return ref.id;
  }

  @override
  Future<void> updateStudent(StudentModel student) async {
    await _children.doc(student.id).update(
          FirestoreHelpers.withTimestamps(student.toMap()),
        );
  }

  @override
  Future<void> deleteStudent(String studentId) async {
    await _children.doc(studentId).delete();
  }

  @override
  Future<EnrollmentModel> enrollStudent({
    required StudentModel student,
    required String classRoomId,
    required String gradeLevelId,
  }) async {
    final enrollmentRef = _enrollments.doc();
    final enrollment = EnrollmentModel(
      id: enrollmentRef.id,
      schoolId: student.schoolId,
      studentId: student.id,
      parentId: student.parentId,
      classRoomId: classRoomId,
      gradeLevelId: gradeLevelId,
      enrolledAt: DateTime.now(),
    );

    final batch = _db.batch();
    batch.set(
      enrollmentRef,
      FirestoreHelpers.withTimestamps(
        {
          ...enrollment.toMap(),
          'enrolledAt': FieldValue.serverTimestamp(),
        },
        isCreate: true,
      ),
    );
    batch.set(
      _children.doc(student.id),
      FirestoreHelpers.withTimestamps(
        {
          ...student.toMap(),
          'activeEnrollmentId': enrollmentRef.id,
          'gradeLevelId': gradeLevelId,
          'classRoomId': classRoomId,
        },
      ),
      SetOptions(merge: true),
    );
    await batch.commit();

    try {
      await _notifyTeachersOfEnrollment(
        schoolId: student.schoolId,
        classRoomId: classRoomId,
        gradeLevelId: gradeLevelId,
        studentName: student.fullName,
        enrollmentId: enrollmentRef.id,
      );
    } catch (_) {
      // Enrollment succeeded; teacher notification is best-effort.
    }

    return enrollment;
  }

  Future<void> _notifyTeachersOfEnrollment({
    required String schoolId,
    required String classRoomId,
    required String studentName,
    required String enrollmentId,
    String? gradeLevelId,
  }) async {
    final notified = <String>{};

    Future<void> notifyFromAssignments(
      QuerySnapshot<Map<String, dynamic>> assignments,
    ) async {
      for (final doc in assignments.docs) {
        final data = doc.data();
        if (data['isActive'] == false) continue;
        final teacherId = data['teacherId'] as String? ?? '';
        if (teacherId.isEmpty || notified.contains(teacherId)) continue;
        notified.add(teacherId);
        await _db.collection(FirestoreCollections.notifications).add({
          'schoolId': schoolId,
          'recipientId': teacherId,
          'userId': teacherId,
          'type': 'new_enrollment',
          'title': 'New student enrolled',
          'body': '$studentName joined your grade roster.',
          'enrollmentId': enrollmentId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    final roomAssignments = await _db
        .collection(FirestoreCollections.classSubjects)
        .where('classRoomId', isEqualTo: classRoomId)
        .get();
    await notifyFromAssignments(roomAssignments);

    final resolvedGradeId = gradeLevelId ??
        (await _db
                .collection(FirestoreCollections.classRooms)
                .doc(classRoomId)
                .get())
            .data()?['gradeLevelId'] as String?;

    if (resolvedGradeId == null || resolvedGradeId.isEmpty) return;

    final gradeRooms = await _db
        .collection(FirestoreCollections.classRooms)
        .where('gradeLevelId', isEqualTo: resolvedGradeId)
        .get();

    for (final room in gradeRooms.docs) {
      final assignments = await _db
          .collection(FirestoreCollections.classSubjects)
          .where('classRoomId', isEqualTo: room.id)
          .get();
      await notifyFromAssignments(assignments);
    }
  }

  @override
  Stream<List<EnrollmentModel>> watchEnrollmentsByClass(String classRoomId) {
    return _enrollments
        .where('classRoomId', isEqualTo: classRoomId)
        .where('status', isEqualTo: EnrollmentStatus.active.id)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EnrollmentModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Live roster for one class room — same query the admin "Enrolled students" panel uses.
  @override
  Stream<List<StudentModel>> watchStudentsForClass(String classRoomId) {
    return _children
        .where('classRoomId', isEqualTo: classRoomId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StudentModel.fromMap(d.data(), d.id))
            .toList());
  }

  /// Merges students from multiple class rooms (e.g. teacher's grade slots).
  Stream<List<StudentModel>> watchStudentsForClassRooms(
    Iterable<String> classRoomIds,
  ) {
    final ids = classRoomIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return Stream.value(<StudentModel>[]);
    }
    if (ids.length == 1) {
      return watchStudentsForClass(ids.first);
    }

    final controller = StreamController<List<StudentModel>>.broadcast();
    final subs = <StreamSubscription<List<StudentModel>>>{};
    final latest = <String, List<StudentModel>>{};

    void emitMerged() {
      final byId = <String, StudentModel>{};
      for (final list in latest.values) {
        for (final s in list) {
          byId[s.id] = s;
        }
      }
      final merged = byId.values.toList()
        ..sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      if (!controller.isClosed) controller.add(merged);
    }

    controller.onListen = () {
      for (final classRoomId in ids) {
        subs.add(
          watchStudentsForClass(classRoomId).listen(
            (students) {
              latest[classRoomId] = students;
              emitMerged();
            },
            onError: controller.addError,
          ),
        );
      }
    };

    controller.onCancel = () {
      for (final sub in subs) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  @override
  Stream<EnrollmentModel?> watchActiveEnrollment(String studentId) {
    return _enrollments
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: EnrollmentStatus.active.id)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return EnrollmentModel.fromMap(doc.data(), doc.id);
    });
  }

  /// Resolves roster scope from Firestore assignments + teacher profile.
  Future<TeacherRosterScope> resolveTeacherRosterScope(String teacherId) async {
    final gradeIds = <String>{};
    final classRoomIds = <String>{};
    var schoolId = SchoolConfig.defaultSchoolId;

    final assignments = await _db
        .collection(FirestoreCollections.classSubjects)
        .where('teacherId', isEqualTo: teacherId)
        .get();

    for (final doc in assignments.docs) {
      final data = doc.data();
      if (data['isActive'] == false) continue;

      final sid = data['schoolId'] as String? ?? '';
      if (sid.isNotEmpty) schoolId = sid;

      final directGrade = data['gradeLevelId'] as String? ?? '';
      if (directGrade.isNotEmpty) gradeIds.add(directGrade);

      final classId = data['classRoomId'] as String? ?? '';
      if (classId.isEmpty) continue;
      classRoomIds.add(classId);

      final room =
          await _db.collection(FirestoreCollections.classRooms).doc(classId).get();
      final roomData = room.data();
      final gradeId = roomData?['gradeLevelId'] as String? ?? '';
      if (gradeId.isNotEmpty) gradeIds.add(gradeId);

      final roomName = roomData?['name'] as String? ?? '';
      if (roomName.isNotEmpty) {
        gradeIds.addAll(await _gradeIdsMatchingName(roomName));
      }
    }

    final userDoc =
        await _db.collection(FirestoreCollections.users).doc(teacherId).get();
    final userData = userDoc.data();
    if (userData != null) {
      final sid = userData['schoolId'] as String? ?? '';
      if (sid.isNotEmpty) schoolId = sid;

      final assignedRooms = userData['assignedClassRoomIds'];
      if (assignedRooms is List) {
        for (final id in assignedRooms) {
          final roomId = id.toString();
          if (roomId.isNotEmpty) classRoomIds.add(roomId);
        }
      }
    }

    final profile = userData?['teacherProfile'];
    if (profile is Map<String, dynamic>) {
      final teachings = profile['teachingsByGrade'];
      if (teachings is List) {
        for (final item in teachings) {
          if (item is Map<String, dynamic>) {
            final gid = item['gradeLevelId'] as String? ?? '';
            if (gid.isNotEmpty) gradeIds.add(gid);
          }
        }
      }
      final legacy = profile['preferredGradeLevelId'] as String? ?? '';
      if (legacy.isNotEmpty) gradeIds.add(legacy);
    }

    return TeacherRosterScope(
      gradeIds: gradeIds,
      classRoomIds: classRoomIds,
      gradeNameKeys: {},
      schoolId: schoolId,
    );
  }

  /// Expands grade IDs (duplicate names), class rooms, and grade name keys.
  Future<TeacherRosterScope> expandScope(TeacherRosterScope scope) async {
    final expandedGradeIds = await _expandGradeIdsWithSameName(scope.gradeIds);
    var gradeNameKeys = await _gradeNameKeysForIds(expandedGradeIds);
    final expandedClassRoomIds =
        await _expandClassRoomIdsForGrades(expandedGradeIds, scope.classRoomIds);

    if (gradeNameKeys.isEmpty) {
      final snap = await _db.collection(FirestoreCollections.classRooms).get();
      for (final doc in snap.docs) {
        if (!expandedClassRoomIds.contains(doc.id)) continue;
        final name = doc.data()['name'] as String? ?? '';
        if (name.isNotEmpty) {
          gradeNameKeys.add(_normalizeGradeName(name));
        }
      }
    }

    return TeacherRosterScope(
      gradeIds: expandedGradeIds,
      classRoomIds: expandedClassRoomIds,
      gradeNameKeys: gradeNameKeys,
      schoolId: scope.schoolId,
    );
  }

  /// One-shot roster fetch for a resolved scope.
  Future<List<StudentModel>> fetchRosterForScope(TeacherRosterScope scope) async {
    if (scope.isEmpty) return [];
    return _fetchStudentsForTeacherScope(scope);
  }

  @override
  Stream<List<StudentModel>> watchStudentsForTeacher(
    String teacherId, {
    TeacherRosterScope? scopeHint,
  }) {
    final hint = scopeHint;
    final controller = StreamController<List<StudentModel>>.broadcast();
    final subs = <StreamSubscription>[];
    final scopedChildSubs = <StreamSubscription>[];
    TeacherRosterScope? boundScope;

    Future<void> emitRoster(TeacherRosterScope scope) async {
      final list = await fetchRosterForScope(scope);
      if (!controller.isClosed) controller.add(list);
    }

    void bindScopedListeners(TeacherRosterScope scope) {
      if (boundScope != null &&
          boundScope!.gradeIds.length == scope.gradeIds.length &&
          boundScope!.classRoomIds.length == scope.classRoomIds.length &&
          boundScope!.gradeIds.containsAll(scope.gradeIds) &&
          boundScope!.classRoomIds.containsAll(scope.classRoomIds)) {
        return;
      }
      boundScope = scope;

      for (final sub in scopedChildSubs) {
        sub.cancel();
      }
      scopedChildSubs.clear();

      for (final classRoomId in scope.classRoomIds) {
        scopedChildSubs.add(
          _children
              .where('classRoomId', isEqualTo: classRoomId)
              .snapshots()
              .listen((_) => emitRoster(scope), onError: controller.addError),
        );
        scopedChildSubs.add(
          _enrollments
              .where('classRoomId', isEqualTo: classRoomId)
              .snapshots()
              .listen((_) => emitRoster(scope), onError: controller.addError),
        );
      }
      for (final gradeId in scope.gradeIds) {
        scopedChildSubs.add(
          _children
              .where('gradeLevelId', isEqualTo: gradeId)
              .snapshots()
              .listen((_) => emitRoster(scope), onError: controller.addError),
        );
        scopedChildSubs.add(
          _enrollments
              .where('gradeLevelId', isEqualTo: gradeId)
              .snapshots()
              .listen((_) => emitRoster(scope), onError: controller.addError),
        );
      }
    }

    Future<void> refresh() async {
      try {
        var scope = await resolveTeacherRosterScope(teacherId);
        if (hint != null && !hint.isEmpty) {
          scope = scope.merge(hint);
        }
        scope = await expandScope(scope);

        if (scope.isEmpty) {
          boundScope = null;
          for (final sub in scopedChildSubs) {
            await sub.cancel();
          }
          scopedChildSubs.clear();
          if (!controller.isClosed) controller.add([]);
          return;
        }

        bindScopedListeners(scope);
        await emitRoster(scope);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller.onListen = () {
      refresh();
      subs.add(
        _db
            .collection(FirestoreCollections.classSubjects)
            .where('teacherId', isEqualTo: teacherId)
            .snapshots()
            .listen((_) => refresh(), onError: controller.addError),
      );
      subs.add(
        _db
            .collection(FirestoreCollections.users)
            .doc(teacherId)
            .snapshots()
            .listen((_) => refresh(), onError: controller.addError),
      );
    };

    controller.onCancel = () {
      boundScope = null;
      for (final sub in subs) {
        sub.cancel();
      }
      for (final sub in scopedChildSubs) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  Future<Set<String>> _gradeIdsMatchingName(String name) async {
    final key = _normalizeGradeName(name);
    if (key.isEmpty) return {};

    final ids = <String>{};
    final snap = await _db.collection(FirestoreCollections.gradeLevels).get();
    for (final doc in snap.docs) {
      final gradeName = doc.data()['name'] as String? ?? '';
      if (gradeName.isNotEmpty && _normalizeGradeName(gradeName) == key) {
        ids.add(doc.id);
      }
    }
    return ids;
  }

  Future<Set<String>> _expandClassRoomIdsForGrades(
    Set<String> gradeIds,
    Set<String> seedRoomIds,
  ) async {
    final expanded = Set<String>.from(seedRoomIds);
    if (gradeIds.isEmpty) return expanded;

    final snap = await _db.collection(FirestoreCollections.classRooms).get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isActive'] == false) continue;
      final gid = data['gradeLevelId'] as String? ?? '';
      if (gid.isNotEmpty && gradeIds.contains(gid)) {
        expanded.add(doc.id);
      }
    }
    return expanded;
  }

  Future<Set<String>> _gradeNameKeysForIds(Set<String> gradeIds) async {
    if (gradeIds.isEmpty) return {};

    final keys = <String>{};
    final snap = await _db.collection(FirestoreCollections.gradeLevels).get();
    for (final doc in snap.docs) {
      if (!gradeIds.contains(doc.id)) continue;
      final name = doc.data()['name'] as String? ?? '';
      if (name.isNotEmpty) keys.add(_normalizeGradeName(name));
    }
    return keys;
  }

  static String _normalizeGradeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<Set<String>> _expandGradeIdsWithSameName(Set<String> gradeIds) async {
    if (gradeIds.isEmpty) return gradeIds;

    final expanded = Set<String>.from(gradeIds);
    final gradesSnap =
        await _db.collection(FirestoreCollections.gradeLevels).get();

    final names = <String>{};
    for (final doc in gradesSnap.docs) {
      if (gradeIds.contains(doc.id)) {
        final name = doc.data()['name'] as String? ?? '';
        if (name.isNotEmpty) names.add(_normalizeGradeName(name));
      }
    }

    for (final doc in gradesSnap.docs) {
      final name = doc.data()['name'] as String? ?? '';
      if (name.isNotEmpty && names.contains(_normalizeGradeName(name))) {
        expanded.add(doc.id);
      }
    }

    return expanded;
  }

  Future<List<StudentModel>> _fetchStudentsForTeacherScope(
    TeacherRosterScope scope,
  ) async {
    final roomGrades = await _classRoomGradeMap();
    final roomNamesById = await _classRoomNamesByIdMap();
    final gradeNamesById = await _gradeNamesByIdMap();

    bool matchesScope(StudentModel student) {
      if (scope.schoolId.isNotEmpty &&
          student.schoolId.isNotEmpty &&
          student.schoolId != scope.schoolId) {
        return false;
      }

      final roomId = student.classRoomId;
      if (roomId != null &&
          roomId.isNotEmpty &&
          scope.classRoomIds.contains(roomId)) {
        return true;
      }

      final gid = student.gradeLevelId ?? '';
      if (gid.isNotEmpty && scope.gradeIds.contains(gid)) return true;

      if (roomId != null && roomId.isNotEmpty) {
        final fromRoom = roomGrades[roomId] ?? '';
        if (fromRoom.isNotEmpty && scope.gradeIds.contains(fromRoom)) {
          return true;
        }
      }

      if (scope.gradeNameKeys.isNotEmpty) {
        var studentGradeName = gid.isNotEmpty
            ? (gradeNamesById[gid] ?? '')
            : (roomId != null
                ? (gradeNamesById[roomGrades[roomId] ?? ''] ?? '')
                : '');
        if (studentGradeName.isEmpty && roomId != null && roomId.isNotEmpty) {
          studentGradeName = roomNamesById[roomId] ?? '';
        }
        if (studentGradeName.isNotEmpty &&
            scope.gradeNameKeys
                .contains(_normalizeGradeName(studentGradeName))) {
          return true;
        }
      }

      return false;
    }

    bool enrollmentMatchesScope(Map<String, dynamic> data) {
      final gid = data['gradeLevelId'] as String? ?? '';
      final roomId = data['classRoomId'] as String? ?? '';
      if (gid.isNotEmpty && scope.gradeIds.contains(gid)) return true;
      if (roomId.isNotEmpty && scope.classRoomIds.contains(roomId)) return true;
      if (scope.schoolId.isNotEmpty) {
        final sid = data['schoolId'] as String? ?? '';
        if (sid.isNotEmpty && sid != scope.schoolId) return false;
      }
      return false;
    }

    StudentModel normalize(StudentModel student) {
      if (student.gradeLevelId != null && student.gradeLevelId!.isNotEmpty) {
        return student;
      }
      final roomId = student.classRoomId;
      if (roomId == null) return student;
      final gid = roomGrades[roomId];
      if (gid == null || gid.isEmpty) return student;
      return student.copyWith(gradeLevelId: gid);
    }

    final byId = <String, StudentModel>{};

    // Same queries as admin GradeEnrolledStudentsPanel (classRoomId / gradeLevelId).
    for (final classRoomId in scope.classRoomIds) {
      try {
        final snap =
            await _children.where('classRoomId', isEqualTo: classRoomId).get();
        for (final doc in snap.docs) {
          final student = normalize(StudentModel.fromMap(doc.data(), doc.id));
          if (matchesScope(student)) {
            byId[student.id] = student;
          }
        }
      } catch (_) {
        // Query blocked — continue with other rooms/grades.
      }
    }

    for (final gradeId in scope.gradeIds) {
      try {
        final snap =
            await _children.where('gradeLevelId', isEqualTo: gradeId).get();
        for (final doc in snap.docs) {
          final student = normalize(StudentModel.fromMap(doc.data(), doc.id));
          if (matchesScope(student)) {
            byId[student.id] = student;
          }
        }
      } catch (_) {
        // Query blocked — continue.
      }
    }

    for (final gradeId in scope.gradeIds) {
      final enrollSnap =
          await _enrollments.where('gradeLevelId', isEqualTo: gradeId).get();
      await _mergeEnrollmentsIntoRoster(
        enrollSnap.docs,
        byId,
        normalize,
        fallbackGradeId: gradeId,
        matchesScope: matchesScope,
        enrollmentMatches: enrollmentMatchesScope,
      );
    }

    for (final classRoomId in scope.classRoomIds) {
      final enrollSnap =
          await _enrollments.where('classRoomId', isEqualTo: classRoomId).get();
      await _mergeEnrollmentsIntoRoster(
        enrollSnap.docs,
        byId,
        normalize,
        matchesScope: matchesScope,
        enrollmentMatches: enrollmentMatchesScope,
      );
    }

    final list = byId.values.toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    return list;
  }

  Future<void> _mergeEnrollmentsIntoRoster(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    Map<String, StudentModel> byId,
    StudentModel Function(StudentModel) normalize, {
    String? fallbackGradeId,
    bool Function(StudentModel student)? matchesScope,
    bool Function(Map<String, dynamic> data)? enrollmentMatches,
  }) async {
    for (final doc in docs) {
      final data = doc.data();
      final status = data['status'] as String? ?? EnrollmentStatus.active.id;
      if (status != EnrollmentStatus.active.id) continue;
      if (enrollmentMatches != null && !enrollmentMatches(data)) continue;

      final studentId = data['studentId'] as String? ?? '';
      if (studentId.isEmpty) continue;

      final childDoc = await _children.doc(studentId).get();
      if (!childDoc.exists) continue;

      var student = normalize(
        StudentModel.fromMap(childDoc.data()!, studentId),
      );
      student = student.copyWith(
        gradeLevelId: data['gradeLevelId'] as String? ??
            fallbackGradeId ??
            student.gradeLevelId,
        classRoomId: data['classRoomId'] as String? ?? student.classRoomId,
        activeEnrollmentId: doc.id,
      );

      if (matchesScope != null && !matchesScope(student)) continue;
      byId[student.id] = student;
    }
  }

  Future<Map<String, String>> _gradeNamesByIdMap() async {
    final snap = await _db.collection(FirestoreCollections.gradeLevels).get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      map[doc.id] = doc.data()['name'] as String? ?? '';
    }
    return map;
  }

  Future<Map<String, String>> _classRoomGradeMap() async {
    final snap = await _db.collection(FirestoreCollections.classRooms).get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      map[doc.id] = doc.data()['gradeLevelId'] as String? ?? '';
    }
    return map;
  }

  Future<Map<String, String>> _classRoomNamesByIdMap() async {
    final snap = await _db.collection(FirestoreCollections.classRooms).get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      map[doc.id] = doc.data()['name'] as String? ?? '';
    }
    return map;
  }

  @override
  Future<void> linkStudentAccount({
    required String studentId,
    required String studentUserId,
  }) async {
    await _children.doc(studentId).update({
      'studentUserId': studentUserId,
      'accountMode': StudentAccountMode.selfLogin.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
