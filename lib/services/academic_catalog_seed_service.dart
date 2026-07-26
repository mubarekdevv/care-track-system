import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/catalog/academic_catalog.dart';
import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_helpers.dart';
import '../models/class_room_model.dart';
import '../models/grade_level_model.dart';
import '../models/subject_model.dart';

/// Seeds Firestore school structure from [AcademicCatalog] (idempotent when grades exist).
class AcademicCatalogSeedService {
  final FirebaseFirestore _db;

  AcademicCatalogSeedService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<bool> seedSchoolCatalogIfEmpty({String? schoolId}) async {
    final sid = schoolId ?? SchoolConfig.defaultSchoolId;
    final existing = await _db
        .collection(FirestoreCollections.gradeLevels)
        .where('schoolId', isEqualTo: sid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return false;
    await seedSchoolCatalog(schoolId: sid, force: true);
    return true;
  }

  /// [force] replaces nothing — only used when collection is empty unless force with empty check above.
  Future<void> seedSchoolCatalog({
    String? schoolId,
    bool force = false,
  }) async {
    final sid = schoolId ?? SchoolConfig.defaultSchoolId;

    if (!force) {
      final existing = await _db
          .collection(FirestoreCollections.gradeLevels)
          .where('schoolId', isEqualTo: sid)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;
    }

    final subjectNameToId = <String, String>{};

    for (final catalogGrade in AcademicCatalog.grades) {
      await _seedCatalogGrade(sid, catalogGrade, subjectNameToId);
    }
  }

  /// Adds any Grades 1–5 missing from Firestore (e.g. only Grade 1 was created manually).
  Future<int> ensureMissingCatalogGrades({String? schoolId}) async {
    final sid = schoolId ?? SchoolConfig.defaultSchoolId;
    final existingLevels = await _existingCatalogLevels(sid);
    if (existingLevels.isEmpty) {
      await seedSchoolCatalog(schoolId: sid, force: true);
      return AcademicCatalog.grades.length;
    }

    final subjectNameToId = await _loadSubjectNameMap(sid);
    var added = 0;
    for (final catalogGrade in AcademicCatalog.grades) {
      if (existingLevels.contains(catalogGrade.level)) continue;
      await _seedCatalogGrade(sid, catalogGrade, subjectNameToId);
      added++;
    }
    return added;
  }

  /// Seeds grades in [fromLevel]..[toLevel] that do not already exist (flexible range).
  Future<int> seedGradesInRange({
    required String schoolId,
    required int fromLevel,
    required int toLevel,
  }) async {
    final existingLevels = await _existingCatalogLevels(schoolId);
    final subjectNameToId = await _loadSubjectNameMap(schoolId);
    var added = 0;

    for (var level = fromLevel; level <= toLevel; level++) {
      if (existingLevels.contains(level)) continue;
      final catalogGrade = AcademicCatalog.templateForLevel(level);
      await _seedCatalogGrade(schoolId, catalogGrade, subjectNameToId);
      existingLevels.add(level);
      added++;
      // Brief pause reduces Firestore web listener assertion errors during bulk seed.
      if (level < toLevel) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    return added;
  }

  Future<Set<int>> _existingCatalogLevels(String schoolId) async {
    final snap = await _db
        .collection(FirestoreCollections.gradeLevels)
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final levels = <int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isActive'] == false) continue;
      final catalogLevel = data['catalogLevel'] as int?;
      if (catalogLevel != null && catalogLevel > 0) {
        levels.add(catalogLevel);
        continue;
      }
      final parsed = AcademicCatalog.parseGradeLevel(data['name'] as String? ?? '');
      if (parsed != null) levels.add(parsed);
    }
    return levels;
  }

  Future<Map<String, String>> _loadSubjectNameMap(String schoolId) async {
    final snap = await _db
        .collection(FirestoreCollections.subjects)
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final map = <String, String>{};
    for (final doc in snap.docs) {
      final name = doc.data()['name'] as String? ?? '';
      if (name.isNotEmpty) map[name] = doc.id;
    }
    return map;
  }

  Future<void> _seedCatalogGrade(
    String schoolId,
    CatalogGrade catalogGrade,
    Map<String, String> subjectNameToId,
  ) async {
    final gradeRef = await _db.collection(FirestoreCollections.gradeLevels).add(
          FirestoreHelpers.withTimestamps(
            GradeLevelModel(
              id: '',
              schoolId: schoolId,
              name: catalogGrade.displayName,
              sortOrder: catalogGrade.level,
              band: 'Primary',
            ).toMap()
              ..['catalogLevel'] = catalogGrade.level,
            isCreate: true,
          ),
        );

    final classRef = await _db.collection(FirestoreCollections.classRooms).add(
          FirestoreHelpers.withTimestamps(
            ClassRoomModel(
              id: '',
              schoolId: schoolId,
              gradeLevelId: gradeRef.id,
              name: catalogGrade.classSectionName,
            ).toMap(),
            isCreate: true,
          ),
        );

    for (final assignment in catalogGrade.subjects) {
      var subjectId = subjectNameToId[assignment.subjectName];
      if (subjectId == null) {
        final subjectRef = await _db.collection(FirestoreCollections.subjects).add(
              FirestoreHelpers.withTimestamps(
                SubjectModel(
                  id: '',
                  schoolId: schoolId,
                  name: assignment.subjectName,
                  code: _subjectCode(assignment.subjectName),
                ).toMap(),
                isCreate: true,
              ),
            );
        subjectId = subjectRef.id;
        subjectNameToId[assignment.subjectName] = subjectId;
      }

      await _db.collection(FirestoreCollections.classSubjects).add(
            FirestoreHelpers.withTimestamps(
              {
                'schoolId': schoolId,
                'classRoomId': classRef.id,
                'subjectId': subjectId,
                'teacherId': '',
                'isActive': true,
                'catalogTeacherName': assignment.teacherName,
                'catalogTeacherEmail': assignment.teacherEmail,
                'catalogSubjectIcon': assignment.subjectIcon,
              },
              isCreate: true,
            ),
          );
    }
  }

  static String _subjectCode(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 4)).toUpperCase();
    return parts.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }
}
