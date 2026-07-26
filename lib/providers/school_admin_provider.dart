import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

import '../core/academic/grade_naming.dart';
import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_admin_repository.dart';
import '../data/firestore/firestore_school_structure_repository.dart';
import '../data/firestore/firestore_user_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/class_room_model.dart';
import '../models/class_subject_model.dart';
import '../models/grade_level_model.dart';
import '../models/school_model.dart';
import '../models/subject_model.dart';
import '../models/user_model.dart';
import '../services/academic_catalog_seed_service.dart';
import '../services/enrollment_readiness_service.dart';
import '../core/health/health_concerns.dart';
import '../core/catalog/academic_catalog.dart';

/// Admin school setup — grades, classes, subjects, teacher links.
class SchoolAdminProvider with ChangeNotifier {
  final FirestoreSchoolStructureRepository _structure;
  final FirestoreAdminRepository _admin;
  final UserRepository _users;

  SchoolAdminProvider({
    FirestoreSchoolStructureRepository? structure,
    FirestoreAdminRepository? admin,
    UserRepository? users,
  })  : _structure = structure ?? FirestoreSchoolStructureRepository(),
        _admin = admin ?? FirestoreAdminRepository(),
        _users = users ?? FirestoreUserRepository();

  String get schoolId => SchoolConfig.defaultSchoolId;

  SchoolModel? school;
  List<GradeLevelModel> grades = [];
  List<ClassRoomModel> classes = [];
  List<SubjectModel> subjects = [];
  List<UserModel> teachers = [];
  List<UserModel> healthcareStaff = [];
  List<UserModel> pendingTeachers = [];
  List<UserModel> pendingHealthcare = [];
  List<UserModel> admins = [];
  List<ClassSubjectModel> classAssignments = [];

  bool isLoading = true;
  bool isBusy = false;
  bool bootstrapNeeded = true;
  bool canClaimAdmin = false;
  String? error;

  StreamSubscription<SchoolModel?>? _schoolSub;
  StreamSubscription<List<GradeLevelModel>>? _gradesSub;
  StreamSubscription<List<ClassRoomModel>>? _classesSub;
  StreamSubscription<List<SubjectModel>>? _subjectsSub;
  StreamSubscription<List<UserModel>>? _teachersSub;
  StreamSubscription<List<UserModel>>? _healthcareSub;
  StreamSubscription<List<ClassSubjectModel>>? _classSubjectsSub;
  StreamSubscription<List<UserModel>>? _adminsSub;
  StreamSubscription<List<UserModel>>? _pendingTeachersSub;
  StreamSubscription<List<UserModel>>? _pendingHealthcareSub;

  String? get primaryAdminUid => school?.primaryAdminUid;

  bool isPrimaryAdmin(String uid) {
    final primary = primaryAdminUid;
    if (primary != null && primary.isNotEmpty) return primary == uid;
    return admins.length == 1 && admins.first.uid == uid;
  }

  void startListening() {
    stopListening();
    isLoading = true;
    notifyListeners();
    _refreshBootstrapFlags();

    _schoolSub = _structure.watchSchool(schoolId).listen((value) {
      school = value;
      bootstrapNeeded = value == null;
      isLoading = false;
      notifyListeners();
    });

    _gradesSub = _structure.watchGradeLevels(schoolId).listen((value) {
      grades = value.where((g) => g.isActive).toList();
      notifyListeners();
    });

    _classesSub = _structure.watchClassRooms(schoolId).listen((value) {
      classes = value.where((c) => c.isActive).toList();
      notifyListeners();
    });

    _subjectsSub = _structure.watchSubjects(schoolId).listen((value) {
      subjects = value.where((s) => s.isActive).toList();
      notifyListeners();
    });

    _teachersSub = _structure.watchTeachers(schoolId).listen((value) {
      teachers = value;
      notifyListeners();
    });

    _healthcareSub = _structure.watchHealthcareStaff(schoolId).listen((value) {
      healthcareStaff = value;
      notifyListeners();
    });

    _pendingTeachersSub = _structure.watchPendingTeachers().listen((value) {
      pendingTeachers = value;
      notifyListeners();
    });

    _pendingHealthcareSub = _structure.watchPendingHealthcare().listen((value) {
      pendingHealthcare = value;
      notifyListeners();
    });

    _classSubjectsSub = _structure.watchSchoolClassSubjects(schoolId).listen((value) {
      classAssignments = value;
      notifyListeners();
    });

    _adminsSub = _users.watchUsersByRole('', 'Admin').listen((value) {
      admins = value..sort((a, b) => a.fullName.compareTo(b.fullName));
      notifyListeners();
    });
  }

  void stopListening() {
    _schoolSub?.cancel();
    _schoolSub = null;
    _gradesSub?.cancel();
    _gradesSub = null;
    _classesSub?.cancel();
    _classesSub = null;
    _subjectsSub?.cancel();
    _subjectsSub = null;
    _teachersSub?.cancel();
    _teachersSub = null;
    _healthcareSub?.cancel();
    _healthcareSub = null;
    _classSubjectsSub?.cancel();
    _classSubjectsSub = null;
    _adminsSub?.cancel();
    _adminsSub = null;
    _pendingTeachersSub?.cancel();
    _pendingTeachersSub = null;
    _pendingHealthcareSub?.cancel();
    _pendingHealthcareSub = null;
  }

  /// Backfill primary admin on schools created before governance was added.
  Future<void> ensurePrimaryAdminRecord(String fallbackAdminUid) async {
    if (fallbackAdminUid.isEmpty) return;
    await _admin.ensurePrimaryAdminUid(
      schoolId: schoolId,
      adminUid: fallbackAdminUid,
    );
  }

  Future<bool> promoteUserToAdminByEmail(String email) async {
    error = null;
    notifyListeners();
    try {
      final user = await _users.findUserByEmail(email);
      if (user == null) {
        error = 'No account found with that email. They must register first.';
        notifyListeners();
        return false;
      }
      if (user.role == 'Admin') {
        error = '${user.fullName} is already an admin.';
        notifyListeners();
        return false;
      }
      await _admin.promoteToAdmin(targetUid: user.uid, schoolId: schoolId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAdminRole({
    required UserModel target,
    required String actingAdminUid,
  }) async {
    error = null;
    notifyListeners();
    try {
      if (admins.length <= 1) {
        error = 'Cannot remove the only admin. Promote someone else first.';
        notifyListeners();
        return false;
      }
      if (target.uid == actingAdminUid && isPrimaryAdmin(actingAdminUid)) {
        error = 'Transfer main admin to someone else before removing yourself.';
        notifyListeners();
        return false;
      }
      if (isPrimaryAdmin(target.uid)) {
        final next = admins.firstWhere((a) => a.uid != target.uid);
        await _admin.transferPrimaryAdmin(
          schoolId: schoolId,
          newPrimaryAdminUid: next.uid,
        );
      }
      final fallbackRole = target.teacherProfile != null ? 'Teacher' : 'Parent';
      await _admin.demoteAdmin(targetUid: target.uid, fallbackRole: fallbackRole);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferPrimaryAdmin({
    required String actingAdminUid,
    required String newPrimaryAdminUid,
  }) async {
    error = null;
    notifyListeners();
    try {
      if (!isPrimaryAdmin(actingAdminUid)) {
        error = 'Only the main admin can transfer that role.';
        notifyListeners();
        return false;
      }
      if (newPrimaryAdminUid == actingAdminUid) {
        error = 'Choose a different admin.';
        notifyListeners();
        return false;
      }
      if (!admins.any((a) => a.uid == newPrimaryAdminUid)) {
        error = 'Selected user is not an admin.';
        notifyListeners();
        return false;
      }
      await _admin.transferPrimaryAdmin(
        schoolId: schoolId,
        newPrimaryAdminUid: newPrimaryAdminUid,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _refreshBootstrapFlags() async {
    try {
      bootstrapNeeded = await _admin.isAdminBootstrapNeeded(schoolId);
      canClaimAdmin = await _admin.canClaimFirstAdmin();
    } catch (e) {
      debugPrint('Bootstrap check error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> bootstrapSchool({
    required String schoolName,
    required UserModel admin,
  }) async {
    error = null;
    notifyListeners();
    try {
      await _admin.bootstrapSchool(
        SchoolBootstrapRequest(
          schoolName: schoolName,
          adminUid: admin.uid,
          adminEmail: admin.email,
          adminFullName: admin.fullName,
        ),
      );
      bootstrapNeeded = false;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> claimFirstAdmin({
    required String schoolName,
    required UserModel user,
  }) async {
    error = null;
    notifyListeners();
    try {
      await _admin.claimFirstAdminAndBootstrap(
        SchoolBootstrapRequest(
          schoolName: schoolName,
          adminUid: user.uid,
          adminEmail: user.email,
          adminFullName: user.fullName,
        ),
      );
      bootstrapNeeded = false;
      canClaimAdmin = false;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Add a grade from the standard catalog (dropdown) — avoids typos like "Grade1" vs "Grade 1".
  Future<bool> addGradeFromCatalogLevel(int catalogLevel) async {
    if (isBusy) return false;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      final max = effectiveMaxCatalogGradeLevel;
      if (max <= 0) {
        error =
            'Set your school grade range first (Home → Load starter curriculum).';
        notifyListeners();
        return false;
      }
      if (catalogLevel > max) {
        error =
            'Your school is set up through Grade $max only. '
            'Increase the range on Home (load curriculum or change max grade).';
        notifyListeners();
        return false;
      }
      final template = AcademicCatalog.templateForLevel(catalogLevel);
      final existing = await _structure.findGradeByCatalogLevel(schoolId, catalogLevel);
      if (existing != null) {
        if (existing.isActive) {
          error = '${template.displayName} is already in your school.';
          notifyListeners();
          return false;
        }
        return await _reactivateCatalogGrade(existing, catalogLevel, template);
      }
      final service = AcademicCatalogSeedService();
      final added = await service.seedGradesInRange(
        schoolId: schoolId,
        fromLevel: catalogLevel,
        toLevel: catalogLevel,
      );
      if (added == 0) {
        error =
            'Could not add ${template.displayName}. Refresh and try again, '
            'or remove any old "${template.displayName}" data in Firebase.';
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      error =
          'Could not add grade. Refresh the browser and try again, or add one grade at a time.';
      notifyListeners();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> addGradeLevel(String name, {String? band}) async {
    error = null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      error = 'Enter a grade name.';
      notifyListeners();
      return false;
    }
    if (_gradeNameExists(trimmed)) {
      error = '"$trimmed" already exists. Each grade level must have a unique name.';
      notifyListeners();
      return false;
    }
    final catalogLevel = AcademicCatalog.parseGradeLevel(trimmed);
    if (catalogLevel != null) {
      return addGradeFromCatalogLevel(catalogLevel);
    }
    if (isBusy) return false;
    isBusy = true;
    notifyListeners();
    try {

      final sortOrder = GradeNaming.computeSortOrder(
        trimmed,
        grades.map((g) => g.sortOrder),
      );
      final gradeId = await _structure.createGradeLevel(
        GradeLevelModel(
          id: '',
          schoolId: schoolId,
          name: trimmed,
          sortOrder: sortOrder,
          band: band,
        ),
      );
      final sectionName =
          SchoolConfig.gradeOnlyEnrollment ? trimmed : '$trimmed-A';
      final classId = await _structure.createClassRoom(
        ClassRoomModel(
          id: '',
          schoolId: schoolId,
          gradeLevelId: gradeId,
          name: sectionName,
        ),
      );
      await _ensureSubjectSlotsForSection(
        classRoomId: classId,
        gradeLevelId: gradeId,
      );
      return true;
    } catch (e) {
      error =
          'Could not add grade. Refresh the page and try again.\n${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  bool _gradeNameExists(String name) {
    final key = GradeNaming.normalizeKey(name);
    return grades.any((g) => GradeNaming.normalizeKey(g.name) == key);
  }

  /// Restores a soft-deleted grade and its class + subject slots.
  Future<bool> _reactivateCatalogGrade(
    GradeLevelModel grade,
    int catalogLevel,
    CatalogGrade template,
  ) async {
    try {
      await _dbUpdateGradeWithCatalogLevel(grade, catalogLevel, template.displayName);
      final rooms = await _structure.fetchClassRoomsForGrade(schoolId, grade.id);
      String classRoomId;
      if (rooms.isEmpty) {
        classRoomId = await _structure.createClassRoom(
          ClassRoomModel(
            id: '',
            schoolId: schoolId,
            gradeLevelId: grade.id,
            name: template.classSectionName,
          ),
        );
      } else {
        final room = rooms.first;
        classRoomId = room.id;
        if (!room.isActive) {
          await _structure.updateClassRoom(
            ClassRoomModel(
              id: room.id,
              schoolId: room.schoolId,
              gradeLevelId: room.gradeLevelId,
              name: template.classSectionName,
              homeroomTeacherId: room.homeroomTeacherId,
              capacity: room.capacity,
              isActive: true,
            ),
          );
        }
      }
      await _ensureSubjectSlotsForSection(
        classRoomId: classRoomId,
        gradeLevelId: grade.id,
      );
      return true;
    } catch (e) {
      error = 'Could not restore ${template.displayName}: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> _dbUpdateGradeWithCatalogLevel(
    GradeLevelModel grade,
    int catalogLevel,
    String displayName,
  ) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.gradeLevels)
        .doc(grade.id)
        .update({
      'schoolId': grade.schoolId,
      'name': displayName,
      'sortOrder': catalogLevel,
      'catalogLevel': catalogLevel,
      if (grade.band != null) 'band': grade.band,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _catalogLevelForGrade(GradeLevelModel g) {
    if (g.sortOrder > 0) return g.sortOrder;
    return AcademicCatalog.parseGradeLevel(g.name) ?? 0;
  }

  int _highestCatalogLevelAmongGrades() {
    var highest = 0;
    for (final g in grades) {
      final level = _catalogLevelForGrade(g);
      if (level > highest) highest = level;
    }
    return highest;
  }

  int get highestCatalogLevelAmongGrades => _highestCatalogLevelAmongGrades();

  /// Stored cap from Firestore (0 = not set).
  int get configuredMaxCatalogGradeLevel => school?.maxCatalogGradeLevel ?? 0;

  /// Cap used for add-grade dropdowns and validation.
  int get effectiveMaxCatalogGradeLevel {
    final configured = configuredMaxCatalogGradeLevel;
    if (configured > 0) return configured.clamp(1, 12);
    final fromGrades = _highestCatalogLevelAmongGrades();
    if (fromGrades > 0) return fromGrades;
    return 0;
  }

  String get maxGradeLabel => effectiveMaxCatalogGradeLevel > 0
      ? 'Grade $effectiveMaxCatalogGradeLevel'
      : 'Not set';

  Future<bool> setMaxCatalogGradeLevel(int level) async {
    if (level < 1 || level > 12) {
      error = 'Choose a grade between 1 and 12.';
      notifyListeners();
      return false;
    }
    final highestUsed = _highestCatalogLevelAmongGrades();
    if (highestUsed > 0 && level < highestUsed) {
      error =
          'Cannot set max below Grade $highestUsed — remove that grade first.';
      notifyListeners();
      return false;
    }
    try {
      await _structure.updateMaxCatalogGradeLevel(schoolId, level);
      school = school?.copyWith(maxCatalogGradeLevel: level);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _applyMaxCatalogGradeLevel(int toLevel) async {
    final next = toLevel.clamp(1, 12);
    final current = configuredMaxCatalogGradeLevel;
    if (current >= next) return;
    await _structure.updateMaxCatalogGradeLevel(schoolId, next);
    school = school?.copyWith(maxCatalogGradeLevel: next);
  }

  Future<bool> updateSchoolName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      error = 'School name cannot be empty.';
      notifyListeners();
      return false;
    }
    try {
      await _structure.updateSchoolName(schoolId, trimmed);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Copy subject slots from a sibling section, or use school-wide subjects.
  Future<void> _ensureSubjectSlotsForSection({
    required String classRoomId,
    required String gradeLevelId,
    String? templateSectionId,
  }) async {
    final existing = assignmentsForSection(classRoomId);
    if (existing.isNotEmpty) return;

    var subjectIds = <String>[];
    if (templateSectionId != null && templateSectionId.isNotEmpty) {
      subjectIds = assignmentsForSection(templateSectionId)
          .map((a) => a.subjectId)
          .where((id) => id.isNotEmpty)
          .toList();
    }
    if (subjectIds.isEmpty && subjects.isNotEmpty) {
      subjectIds = subjects.map((s) => s.id).toList();
    }
    if (subjectIds.isEmpty) {
      for (final assignment in AcademicCatalog.defaultCoreSubjects) {
        final id = await _findOrCreateSubjectByName(assignment.subjectName);
        subjectIds.add(id);
      }
    }

    for (final subjectId in subjectIds) {
      final already = classAssignments.any(
        (a) => a.classRoomId == classRoomId && a.subjectId == subjectId,
      );
      if (already) continue;
      await _structure.assignTeacherToClassSubject(
        ClassSubjectModel(
          id: '',
          schoolId: schoolId,
          classRoomId: classRoomId,
          subjectId: subjectId,
          teacherId: '',
        ),
      );
    }
  }

  Future<String> _findOrCreateSubjectByName(String name) async {
    for (final s in subjects) {
      if (s.name.toLowerCase() == name.toLowerCase()) return s.id;
    }
    return _structure.createSubject(
      SubjectModel(id: '', schoolId: schoolId, name: name),
    );
  }

  SectionEnrollmentStatus sectionEnrollmentStatus(String classRoomId) {
    final slots = assignmentsForSection(classRoomId);
    if (slots.isEmpty) {
      return const SectionEnrollmentStatus(
        hasSubjectSlots: false,
        canEnroll: false,
      );
    }
    final assigned = <String>[];
    final unassigned = <String>[];
    for (final slot in slots) {
      final subjectName = subjectNameForId(slot.subjectId) ?? 'Subject';
      if (slot.teacherId.isNotEmpty) {
        assigned.add(subjectName);
      } else {
        unassigned.add(subjectName);
      }
    }
    return SectionEnrollmentStatus(
      hasSubjectSlots: true,
      canEnroll: unassigned.isEmpty,
      assignedSubjectNames: assigned,
      unassignedSubjectNames: unassigned,
    );
  }

  (int linked, int total) sectionAssignmentCounts(String classRoomId) {
    final slots = assignmentsForSection(classRoomId);
    if (slots.isEmpty) return (0, 0);
    final linked = slots.where((a) => a.teacherId.isNotEmpty).length;
    return (linked, slots.length);
  }

  Future<bool> addClassRoom({
    required String name,
    required String gradeLevelId,
    String? homeroomTeacherId,
  }) async {
    try {
      await _structure.createClassRoom(
        ClassRoomModel(
          id: '',
          schoolId: schoolId,
          gradeLevelId: gradeLevelId,
          name: name,
          homeroomTeacherId: homeroomTeacherId,
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSubject(String name, {String? code}) async {
    try {
      await _structure.createSubject(
        SubjectModel(
          id: '',
          schoolId: schoolId,
          name: name,
          code: code,
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTeacher({
    required String classRoomId,
    required String subjectId,
    required String teacherId,
  }) async {
    UserModel? teacher;
    for (final t in teachers) {
      if (t.uid == teacherId) {
        teacher = t;
        break;
      }
    }
    String? gradeLevelId;
    for (final c in classes) {
      if (c.id == classRoomId) {
        gradeLevelId = c.gradeLevelId;
        break;
      }
    }
    if (teacher != null &&
        !teacherCanTeachSubject(
          teacher,
          subjectId,
          gradeLevelId: gradeLevelId,
        )) {
      final subjectName = subjectNameForId(subjectId) ?? 'this subject';
      final gradeName =
          gradeLevelId != null ? gradeNameForId(gradeLevelId) : null;
      error = gradeName != null
          ? '${teacher.fullName} did not register to teach $subjectName in $gradeName. '
              'They must update their teacher profile.'
          : '${teacher.fullName} did not register to teach $subjectName. '
              'They must update their teacher profile first.';
      notifyListeners();
      return false;
    }
    try {
      final existing = await FirebaseFirestore.instance
          .collection(FirestoreCollections.classSubjects)
          .where('classRoomId', isEqualTo: classRoomId)
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      String? previousTeacherId;
      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        previousTeacherId = doc.data()['teacherId'] as String? ?? '';
        await doc.reference.update({
          'teacherId': teacherId,
          if (gradeLevelId != null && gradeLevelId.isNotEmpty)
            'gradeLevelId': gradeLevelId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _structure.assignTeacherToClassSubject(
          ClassSubjectModel(
            id: '',
            schoolId: schoolId,
            classRoomId: classRoomId,
            subjectId: subjectId,
            teacherId: teacherId,
          ),
        );
        if (gradeLevelId != null && gradeLevelId.isNotEmpty) {
          final created = await FirebaseFirestore.instance
              .collection(FirestoreCollections.classSubjects)
              .where('classRoomId', isEqualTo: classRoomId)
              .where('subjectId', isEqualTo: subjectId)
              .where('teacherId', isEqualTo: teacherId)
              .limit(1)
              .get();
          if (created.docs.isNotEmpty) {
            await created.docs.first.reference.update({
              'gradeLevelId': gradeLevelId,
            });
          }
        }
      }

      // Core assignment succeeded — optional steps must not show a false failure.
      try {
        await syncTeacherAssignedClasses(teacherId);
        if (previousTeacherId != null &&
            previousTeacherId.isNotEmpty &&
            previousTeacherId != teacherId) {
          await syncTeacherAssignedClasses(previousTeacherId);
        }
      } catch (e) {
        debugPrint('Teacher roster sync skipped: $e');
      }

      try {
        final enrollStatus = sectionEnrollmentStatus(classRoomId);
        var gradeLabel = 'this grade';
        for (final c in classes) {
          if (c.id == classRoomId) {
            gradeLabel = gradeNameForId(c.gradeLevelId) ?? c.name;
            break;
          }
        }
        await EnrollmentReadinessService().notifyParentsIfSectionReady(
          classRoomId: classRoomId,
          gradeName: gradeLabel,
          canEnroll: enrollStatus.canEnroll,
        );
      } catch (e) {
        debugPrint('Parent enrollment notify skipped: $e');
      }

      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// School subjects not yet added as slots in this grade's class.
  List<SubjectModel> subjectsAvailableToAddToGrade(String gradeLevelId) {
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return [];
    final used = assignmentsForSection(room.id)
        .map((a) => a.subjectId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return subjects.where((s) => !used.contains(s.id)).toList();
  }

  List<ClassSubjectModel> subjectSlotsForGrade(String gradeLevelId) {
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return [];
    return assignmentsForSection(room.id);
  }

  /// Add a school-wide subject to one grade (creates an empty teacher slot).
  Future<bool> addSubjectToGrade({
    required String gradeLevelId,
    required String subjectId,
  }) async {
    error = null;
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) {
      error = 'This grade has no class yet. Re-add the grade from the menu above.';
      notifyListeners();
      return false;
    }
    final exists = classAssignments.any(
      (a) => a.classRoomId == room.id && a.subjectId == subjectId,
    );
    if (exists) {
      error = 'That subject is already in this grade.';
      notifyListeners();
      return false;
    }
    try {
      await _structure.assignTeacherToClassSubject(
        ClassSubjectModel(
          id: '',
          schoolId: schoolId,
          classRoomId: room.id,
          subjectId: subjectId,
          teacherId: '',
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSubjectFromGrade({
    required String gradeLevelId,
    required String subjectId,
  }) async {
    error = null;
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return false;
    ClassSubjectModel? slot;
    for (final a in classAssignments) {
      if (a.classRoomId == room.id && a.subjectId == subjectId) {
        slot = a;
        break;
      }
    }
    if (slot == null || slot.id.isEmpty) {
      error = 'Subject slot not found.';
      notifyListeners();
      return false;
    }
    try {
      await _structure.removeClassSubject(slot.id);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Denormalizes class room IDs onto the teacher user doc for Firestore security rules.
  Future<void> syncTeacherAssignedClasses(String teacherId) async {
    if (teacherId.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreCollections.classSubjects)
        .where('teacherId', isEqualTo: teacherId)
        .where('isActive', isEqualTo: true)
        .get();
    final classIds = snap.docs
        .map((d) => d.data()['classRoomId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(teacherId).set(
      {
        'assignedClassRoomIds': classIds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Syncs school link + class access for every teacher account.
  Future<int> linkAllTeachersToSchool() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'Teacher')
        .get();
    var count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};
      if (data['schoolId'] == null || data['schoolId'] == '') {
        updates['schoolId'] = schoolId;
      }
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await doc.reference.set(updates, SetOptions(merge: true));
        count++;
      }
      await syncTeacherAssignedClasses(doc.id);
    }
    return count;
  }

  /// Link one pending teacher account to this school.
  Future<bool> linkTeacherToSchool(String teacherId) async {
    if (teacherId.isEmpty) return false;
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(teacherId)
          .set(
        {
          'schoolId': schoolId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await syncTeacherAssignedClasses(teacherId);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<String> get enabledHealthSpecialtyIds =>
      school?.enabledHealthSpecialtyIds ?? const [];

  List<HealthConcernOption> get enabledHealthConcerns =>
      HealthConcerns.forSchool(enabledHealthSpecialtyIds);

  Future<bool> updateEnabledHealthSpecialties(List<String> specialtyIds) async {
    try {
      await _structure.updateEnabledHealthSpecialties(
        schoolId,
        specialtyIds.toSet().toList()..sort(),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> linkAllHealthcareToSchool() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'Healthcare')
        .get();
    var count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['schoolId'] == null || data['schoolId'] == '') {
        await doc.reference.set(
          {
            'schoolId': schoolId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        count++;
      }
    }
    return count;
  }

  Future<bool> linkHealthcareToSchool(String healthcareUserId) async {
    if (healthcareUserId.isEmpty) return false;
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(healthcareUserId)
          .set(
        {
          'schoolId': schoolId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Display label for a subject slot — linked account or catalog sample name.
  String assignmentTeacherLabel(ClassSubjectModel slot) {
    if (slot.teacherId.isNotEmpty) {
      for (final t in teachers) {
        if (t.uid == slot.teacherId) return t.fullName;
      }
      return 'Linked teacher';
    }
    final catalog = slot.catalogTeacherName?.trim();
    if (catalog != null && catalog.isNotEmpty) {
      return '$catalog (sample — not a real account)';
    }
    return 'No teacher assigned';
  }

  bool isAssignmentLinked(ClassSubjectModel slot) => slot.teacherId.isNotEmpty;

  /// Subject IDs configured for a grade (from that grade's class slots).
  List<String> subjectIdsForGradeLevel(String gradeLevelId) {
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return [];
    return assignmentsForSection(room.id)
        .map((a) => a.subjectId)
        .where((id) => id.isNotEmpty)
        .toList();
  }

  /// Whether a linked teacher registered this subject for the given grade.
  bool teacherCanTeachSubject(
    UserModel teacher,
    String subjectId, {
    String? gradeLevelId,
  }) {
    return teacher.teacherProfile?.teachesSubject(
          subjectId,
          gradeLevelId: gradeLevelId,
        ) ??
        false;
  }

  List<UserModel> teachersEligibleForSubject(
    String subjectId, {
    String? classRoomId,
  }) {
    String? gradeLevelId;
    if (classRoomId != null) {
      for (final c in classes) {
        if (c.id == classRoomId) {
          gradeLevelId = c.gradeLevelId;
          break;
        }
      }
    }
    return teachers
        .where(
          (t) => teacherCanTeachSubject(
            t,
            subjectId,
            gradeLevelId: gradeLevelId,
          ),
        )
        .toList();
  }

  String? gradeLevelIdForClassRoom(String classRoomId) {
    for (final c in classes) {
      if (c.id == classRoomId) return c.gradeLevelId;
    }
    return null;
  }

  String teachableSubjectsLabel(UserModel teacher) {
    final byGrade = teacher.teacherProfile?.teachingsByGrade ?? [];
    if (byGrade.isNotEmpty) {
      return byGrade
          .map((t) {
            final grade = gradeNameForId(t.gradeLevelId) ?? 'Grade';
            final subs = t.subjectIds
                .map((id) => subjectNameForId(id) ?? '')
                .where((n) => n.isNotEmpty)
                .join(', ');
            return '$grade: $subs';
          })
          .join(' · ');
    }
    final ids = teacher.teacherProfile?.teachableSubjectIds ?? [];
    if (ids.isEmpty) return 'No subjects selected';
    return ids
        .map((id) => subjectNameForId(id) ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  /// Load starter curriculum for a grade range (skips grades that already exist).
  Future<String> seedGradesRange({required int fromLevel, required int toLevel}) async {
    if (isBusy) return 'Please wait for the current operation to finish.';
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      if (fromLevel < 1 || toLevel < fromLevel) {
        error = 'Choose a valid grade range (e.g. 1 to 8).';
        return error!;
      }
      if (toLevel > 12) {
        error = 'Maximum catalog level is Grade 12.';
        return error!;
      }
      final service = AcademicCatalogSeedService();
      final previousMax = configuredMaxCatalogGradeLevel;
      final added = await service.seedGradesInRange(
        schoolId: schoolId,
        fromLevel: fromLevel,
        toLevel: toLevel,
      );
      await _applyMaxCatalogGradeLevel(toLevel);
      if (added > 0) {
        return 'Added $added grade(s). Highest grade is now Grade $toLevel. '
            'Assign teachers in Staff before parents can enroll.';
      }
      if (previousMax < toLevel || previousMax == 0) {
        return 'Grade range updated to Grade $toLevel. '
            'Add missing grades from the Grades tab.';
      }
      return 'No new grades added — those levels may already exist.';
    } catch (e) {
      error = e.toString();
      return 'Could not load curriculum. Refresh the browser, then add grades one at a time from the Grades tab.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// @deprecated Use [seedGradesRange] instead.
  Future<String> seedDefaultCatalog() async {
    return seedGradesRange(fromLevel: 1, toLevel: 5);
  }

  List<ClassRoomModel> sectionsForGrade(String gradeLevelId) {
    return classes.where((c) => c.gradeLevelId == gradeLevelId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  String? gradeNameForId(String gradeLevelId) {
    for (final g in grades) {
      if (g.id == gradeLevelId) return g.name;
    }
    return null;
  }

  /// Admin UI label for a class (grade-only → "Grade 2", not "1-A" or "Grade 2-A").
  String classDisplayLabel(ClassRoomModel classroom) {
    if (SchoolConfig.gradeOnlyEnrollment) {
      final gradeName = gradeNameForId(classroom.gradeLevelId);
      if (gradeName != null && gradeName.isNotEmpty) return gradeName;
    }
    return classroom.name;
  }

  String? gradeNameForClassRoom(String classRoomId) {
    for (final c in classes) {
      if (c.id == classRoomId) {
        return gradeNameForId(c.gradeLevelId) ?? c.name;
      }
    }
    return null;
  }

  String? subjectNameForId(String subjectId) {
    for (final s in subjects) {
      if (s.id == subjectId) return s.name;
    }
    return null;
  }

  /// Parent enrollment preview — built from live admin cache (no extra Firestore round-trip).
  List<AssignedTeacherView> assignedTeacherViewsForClass(String classRoomId) {
    final slots = assignmentsForSection(classRoomId);
    final views = <AssignedTeacherView>[];
    for (final slot in slots) {
      if (!slot.isActive) continue;

      SubjectModel? subject;
      for (final s in subjects) {
        if (s.id == slot.subjectId) {
          subject = s;
          break;
        }
      }
      subject ??= SubjectModel(
        id: slot.subjectId,
        schoolId: schoolId,
        name: subjectNameForId(slot.subjectId) ?? 'Subject',
      );

      UserModel? teacher;
      if (slot.teacherId.isNotEmpty) {
        for (final t in teachers) {
          if (t.uid == slot.teacherId) {
            teacher = t;
            break;
          }
        }
      }

      final linked = slot.teacherId.isNotEmpty && teacher != null;
      views.add(
        AssignedTeacherView(
          subject: subject,
          teacherId: slot.teacherId,
          teacherName: teacher?.fullName ??
              slot.catalogTeacherName ??
              'Teacher pending',
          teacherEmail: teacher?.email ?? slot.catalogTeacherEmail,
          subjectIconKey: slot.catalogSubjectIcon,
          isLinked: linked,
        ),
      );
    }
    views.sort((a, b) => a.subject.name.compareTo(b.subject.name));
    return views;
  }

  List<ClassSubjectModel> assignmentsForSection(String classRoomId) {
    final slots = classAssignments.where((a) => a.classRoomId == classRoomId).toList();
    // One row per subject (legacy data may have duplicate slots).
    final bySubjectName = <String, ClassSubjectModel>{};
    for (final slot in slots) {
      final name = (subjectNameForId(slot.subjectId) ?? slot.subjectId).toLowerCase();
      final existing = bySubjectName[name];
      if (existing == null) {
        bySubjectName[name] = slot;
        continue;
      }
      if (existing.teacherId.isEmpty && slot.teacherId.isNotEmpty) {
        bySubjectName[name] = slot;
      }
    }
    final list = bySubjectName.values.toList();
    list.sort((a, b) => (subjectNameForId(a.subjectId) ?? '')
        .compareTo(subjectNameForId(b.subjectId) ?? ''));
    return list;
  }

  bool sectionHasLinkedTeacher(String classRoomId) {
    return assignmentsForSection(classRoomId)
        .any((a) => a.teacherId.isNotEmpty);
  }

  /// Sections with no teacher linked to any subject slot.
  List<ClassRoomModel> get sectionsWithoutTeachers {
    return classes.where((c) => !sectionHasLinkedTeacher(c.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  int get unlinkedSubjectSlotCount {
    return classAssignments.where((a) => a.teacherId.isEmpty).length;
  }

  /// Primary class for a grade (grade-only mode uses the grade-named room).
  ClassRoomModel? primaryClassForGrade(String gradeLevelId) {
    final sections = sectionsForGrade(gradeLevelId);
    if (sections.isEmpty) return null;
    final gradeName = gradeNameForId(gradeLevelId) ?? '';

    ClassRoomModel? bestPartial;
    var bestPartialScore = -1;

    for (final s in sections) {
      final legacy = _isLegacySectionName(s.name, gradeName);
      final counts = sectionAssignmentCounts(s.id);
      if (counts.$2 == 0) continue;

      if (sectionEnrollmentStatus(s.id).canEnroll && !legacy) {
        return s;
      }
      if (sectionEnrollmentStatus(s.id).canEnroll) {
        return s;
      }

      final score = counts.$1 * 10 + (legacy ? 0 : 100);
      if (score > bestPartialScore) {
        bestPartialScore = score;
        bestPartial = s;
      }
    }

    if (bestPartial != null) return bestPartial;

    if (gradeName.isNotEmpty) {
      for (final s in sections) {
        if (s.name == gradeName) return s;
      }
      for (final s in sections) {
        if (!_isLegacySectionName(s.name, gradeName)) return s;
      }
    }
    return sections.first;
  }

  /// Enrollment readiness for parent UI — uses the best class for this grade.
  SectionEnrollmentStatus? gradeEnrollmentStatus(String gradeLevelId) {
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return null;
    return sectionEnrollmentStatus(room.id);
  }

  static bool _isLegacySectionName(String roomName, String gradeName) {
    final n = roomName.trim();
    final lower = n.toLowerCase();
    if (lower.contains('section')) return true;
    if (RegExp(r'^\d+-[A-Za-z]$').hasMatch(n)) return true;
    if (n.contains('—') || n.contains('-')) {
      if (lower.contains('section') || RegExp(r'\d+\s*-\s*[A-Za-z]').hasMatch(n)) {
        return true;
      }
    }
    return n != gradeName && n.length <= 4;
  }

  bool isGradeReadyForEnrollment(String gradeLevelId) {
    final room = primaryClassForGrade(gradeLevelId);
    if (room == null) return false;
    return sectionEnrollmentStatus(room.id).canEnroll;
  }

  int get gradesReadyCount =>
      grades.where((g) => isGradeReadyForEnrollment(g.id)).length;

  int get gradesPendingTeachersCount => grades.length - gradesReadyCount;

  /// Standard levels not yet added, capped by [effectiveMaxCatalogGradeLevel].
  List<int> availableCatalogLevelsToAdd() {
    final max = effectiveMaxCatalogGradeLevel;
    if (max <= 0) return [];
    final used = <int>{};
    for (final g in grades) {
      final level = _catalogLevelForGrade(g);
      if (level > 0) used.add(level);
    }
    return List.generate(max, (i) => i + 1).where((l) => !used.contains(l)).toList();
  }

  /// Section label shown to parents, e.g. "Grade 1-A" → section "A".
  static String sectionLabel(ClassRoomModel section, String gradeName) {
    final prefix = '$gradeName-';
    if (section.name.startsWith(prefix)) {
      return section.name.substring(prefix.length);
    }
    if (section.name.startsWith(gradeName)) {
      return section.name.substring(gradeName.length).replaceFirst(RegExp(r'^[\s\-–]+'), '');
    }
    return section.name;
  }

  Future<bool> addSectionToGrade({
    required String gradeLevelId,
    required String sectionCode,
  }) async {
    final gradeName = gradeNameForId(gradeLevelId);
    if (gradeName == null) return false;
    final code = sectionCode.trim().toUpperCase();
    if (code.isEmpty) return false;
    final fullName = '$gradeName-$code';
    final exists = classes.any(
      (c) => c.gradeLevelId == gradeLevelId && c.name.toLowerCase() == fullName.toLowerCase(),
    );
    if (exists) {
      error = 'Section $fullName already exists.';
      notifyListeners();
      return false;
    }
    try {
      final classId = await _structure.createClassRoom(
        ClassRoomModel(
          id: '',
          schoolId: schoolId,
          gradeLevelId: gradeLevelId,
          name: fullName,
        ),
      );
      final siblings = sectionsForGrade(gradeLevelId);
      await _ensureSubjectSlotsForSection(
        classRoomId: classId,
        gradeLevelId: gradeLevelId,
        templateSectionId: siblings.isNotEmpty ? siblings.first.id : null,
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  GradeLevelModel? _gradeById(String id) {
    for (final g in grades) {
      if (g.id == id) return g;
    }
    return null;
  }

  ClassRoomModel? _classById(String id) {
    for (final c in classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  SubjectModel? _subjectById(String id) {
    for (final s in subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<bool> removeGradeLevel(String gradeId) async {
    try {
      final grade = _gradeById(gradeId);
      if (grade == null) return false;
      await _structure.updateGradeLevel(
        GradeLevelModel(
          id: grade.id,
          schoolId: grade.schoolId,
          name: grade.name,
          sortOrder: grade.sortOrder,
          band: grade.band,
          isActive: false,
        ),
      );
      for (final section in sectionsForGrade(gradeId)) {
        await removeClassRoom(section.id);
      }
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeClassRoom(String classRoomId) async {
    try {
      final room = _classById(classRoomId);
      if (room == null) return false;
      await _structure.updateClassRoom(
        ClassRoomModel(
          id: room.id,
          schoolId: room.schoolId,
          gradeLevelId: room.gradeLevelId,
          name: room.name,
          homeroomTeacherId: room.homeroomTeacherId,
          capacity: room.capacity,
          isActive: false,
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSubject(String subjectId) async {
    try {
      final subject = _subjectById(subjectId);
      if (subject == null) return false;
      await _structure.updateSubject(
        SubjectModel(
          id: subject.id,
          schoolId: subject.schoolId,
          name: subject.name,
          code: subject.code,
          isActive: false,
        ),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeTeacherFromSchool(String teacherUid) async {
    try {
      final teacher = await _users.getUser(teacherUid);
      if (teacher == null) return false;
      await _users.updateUser(
        teacher.copyWith(schoolId: ''),
      );
      final assignments = await FirebaseFirestore.instance
          .collection(FirestoreCollections.classSubjects)
          .where('teacherId', isEqualTo: teacherUid)
          .where('isActive', isEqualTo: true)
          .get();
      for (final doc in assignments.docs) {
        await _structure.removeClassSubject(doc.id);
      }
      await FirebaseFirestore.instance.collection(FirestoreCollections.users).doc(teacherUid).set(
        {
          'assignedClassRoomIds': <String>[],
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
