import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/catalog/academic_catalog.dart';
import '../../core/domain/domain_enums.dart';
import '../../models/class_room_model.dart';
import '../../models/class_subject_model.dart';
import '../../models/grade_level_model.dart';
import '../../models/school_model.dart';
import '../../models/subject_model.dart';
import '../../models/user_model.dart';
import '../repositories/school_structure_repository.dart';
import 'firestore_helpers.dart';
import 'firestore_user_repository.dart';

class FirestoreSchoolStructureRepository implements SchoolStructureRepository {
  final FirebaseFirestore _db;
  final FirestoreUserRepository _users;

  FirestoreSchoolStructureRepository({
    FirebaseFirestore? db,
    FirestoreUserRepository? users,
  })  : _db = db ?? FirebaseFirestore.instance,
        _users = users ?? FirestoreUserRepository(db: db);

  @override
  Future<SchoolModel?> getSchool(String schoolId) async {
    final doc = await _db.collection(FirestoreCollections.schools).doc(schoolId).get();
    if (!doc.exists) return null;
    return SchoolModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Stream<SchoolModel?> watchSchool(String schoolId) {
    return _db.collection(FirestoreCollections.schools).doc(schoolId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SchoolModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> updateSchoolName(String schoolId, String name) async {
    await _db.collection(FirestoreCollections.schools).doc(schoolId).set(
      {
        'name': name.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateMaxCatalogGradeLevel(String schoolId, int level) async {
    await _db.collection(FirestoreCollections.schools).doc(schoolId).set(
      {
        'maxCatalogGradeLevel': level.clamp(1, 12),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateEnabledHealthSpecialties(
    String schoolId,
    List<String> specialtyIds,
  ) async {
    await _db.collection(FirestoreCollections.schools).doc(schoolId).set(
      {
        'enabledHealthSpecialtyIds': specialtyIds,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Stream<List<GradeLevelModel>> watchGradeLevels(String schoolId) {
    return _db
        .collection(FirestoreCollections.gradeLevels)
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => GradeLevelModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return list;
        });
  }

  @override
  Future<String> createGradeLevel(GradeLevelModel grade) async {
    final ref = await _db.collection(FirestoreCollections.gradeLevels).add(
          FirestoreHelpers.withTimestamps(grade.toMap(), isCreate: true),
        );
    return ref.id;
  }

  @override
  Future<void> updateGradeLevel(GradeLevelModel grade) async {
    await _db.collection(FirestoreCollections.gradeLevels).doc(grade.id).update(
          FirestoreHelpers.withTimestamps(grade.toMap()),
        );
  }

  @override
  Future<GradeLevelModel?> findGradeByCatalogLevel(
    String schoolId,
    int catalogLevel,
  ) async {
    final snap = await _db
        .collection(FirestoreCollections.gradeLevels)
        .where('schoolId', isEqualTo: schoolId)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final grade = GradeLevelModel.fromMap(data, doc.id);
      final stored = data['catalogLevel'] as int?;
      final level = stored != null && stored > 0
          ? stored
          : AcademicCatalog.parseGradeLevel(grade.name);
      if (level == catalogLevel) return grade;
    }
    return null;
  }

  @override
  Future<List<ClassRoomModel>> fetchClassRoomsForGrade(
    String schoolId,
    String gradeLevelId,
  ) async {
    final snap = await _db
        .collection(FirestoreCollections.classRooms)
        .where('schoolId', isEqualTo: schoolId)
        .where('gradeLevelId', isEqualTo: gradeLevelId)
        .get();
    final list = snap.docs.map((d) => ClassRoomModel.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Stream<List<ClassRoomModel>> watchClassRooms(String schoolId, {String? gradeLevelId}) {
    Query<Map<String, dynamic>> query =
        _db.collection(FirestoreCollections.classRooms).where('schoolId', isEqualTo: schoolId);
    if (gradeLevelId != null) {
      query = query.where('gradeLevelId', isEqualTo: gradeLevelId);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs.map((d) => ClassRoomModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  @override
  Future<String> createClassRoom(ClassRoomModel classRoom) async {
    final ref = await _db.collection(FirestoreCollections.classRooms).add(
          FirestoreHelpers.withTimestamps(classRoom.toMap(), isCreate: true),
        );
    return ref.id;
  }

  @override
  Future<void> updateClassRoom(ClassRoomModel classRoom) async {
    await _db.collection(FirestoreCollections.classRooms).doc(classRoom.id).update(
          FirestoreHelpers.withTimestamps(classRoom.toMap()),
        );
  }

  @override
  Stream<List<SubjectModel>> watchSubjects(String schoolId) {
    return _db
        .collection(FirestoreCollections.subjects)
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => SubjectModel.fromMap(d.data(), d.id)).toList();
          list.sort((a, b) => a.name.compareTo(b.name));
          return list;
        });
  }

  @override
  Future<String> createSubject(SubjectModel subject) async {
    final ref = await _db.collection(FirestoreCollections.subjects).add(
          FirestoreHelpers.withTimestamps(subject.toMap(), isCreate: true),
        );
    return ref.id;
  }

  @override
  Future<void> updateSubject(SubjectModel subject) async {
    await _db.collection(FirestoreCollections.subjects).doc(subject.id).update(
          FirestoreHelpers.withTimestamps(subject.toMap()),
        );
  }

  @override
  Stream<List<ClassSubjectModel>> watchClassSubjects(String classRoomId) {
    return _db
        .collection(FirestoreCollections.classSubjects)
        .where('classRoomId', isEqualTo: classRoomId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassSubjectModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<ClassSubjectModel>> watchSchoolClassSubjects(String schoolId) {
    return _db
        .collection(FirestoreCollections.classSubjects)
        .where('schoolId', isEqualTo: schoolId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ClassSubjectModel.fromMap(d.data(), d.id)).toList());
  }

  @override
  Stream<List<ClassSubjectModel>> watchTeacherAssignments(String teacherId) {
    return _db
        .collection(FirestoreCollections.classSubjects)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ClassSubjectModel.fromMap(d.data(), d.id))
            .where((a) => a.isActive)
            .toList());
  }

  @override
  Future<String> assignTeacherToClassSubject(ClassSubjectModel assignment) async {
    final ref = await _db.collection(FirestoreCollections.classSubjects).add(
          FirestoreHelpers.withTimestamps(assignment.toMap(), isCreate: true),
        );
    return ref.id;
  }

  @override
  Future<void> removeClassSubject(String classSubjectId) async {
    await _db.collection(FirestoreCollections.classSubjects).doc(classSubjectId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<AssignedTeacherView>> getAssignedTeachersForClass(String classRoomId) async {
    final assignments = await _db
        .collection(FirestoreCollections.classSubjects)
        .where('classRoomId', isEqualTo: classRoomId)
        .where('isActive', isEqualTo: true)
        .get();

    final views = <AssignedTeacherView>[];
    for (final doc in assignments.docs) {
      final assignment = ClassSubjectModel.fromMap(doc.data(), doc.id);
      final subjectDoc = await _db
          .collection(FirestoreCollections.subjects)
          .doc(assignment.subjectId)
          .get();
      if (!subjectDoc.exists) continue;

      final linked = assignment.teacherId.isNotEmpty;
      UserModel? teacher;
      if (linked) {
        teacher = await _users.getUser(assignment.teacherId);
      }

      final displayName = teacher?.fullName ??
          assignment.catalogTeacherName ??
          'Teacher pending';

      views.add(
        AssignedTeacherView(
          subject: SubjectModel.fromMap(subjectDoc.data()!, subjectDoc.id),
          teacherId: assignment.teacherId,
          teacherName: displayName,
          teacherEmail: teacher?.email ?? assignment.catalogTeacherEmail,
          subjectIconKey: assignment.catalogSubjectIcon,
          isLinked: linked && teacher != null,
        ),
      );
    }
    views.sort((a, b) => a.subject.name.compareTo(b.subject.name));
    return views;
  }

  @override
  Stream<List<UserModel>> watchTeachers(String schoolId) {
    return _db
        .collection(FirestoreCollections.users)
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'Teacher')
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['uid'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();
        });
  }

  @override
  Stream<List<UserModel>> watchHealthcareStaff(String schoolId) {
    return _db
        .collection(FirestoreCollections.users)
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: 'Healthcare')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['uid'] = doc.id;
            return UserModel.fromMap(data);
          }).toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return list;
        });
  }

  @override
  Stream<List<UserModel>> watchPendingTeachers() {
    return _db
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'Teacher')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .where((doc) {
                final sid = doc.data()['schoolId'] as String? ?? '';
                return sid.isEmpty;
              })
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['uid'] = doc.id;
                return UserModel.fromMap(data);
              })
              .toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return list;
        });
  }

  @override
  Stream<List<UserModel>> watchPendingHealthcare() {
    return _db
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'Healthcare')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .where((doc) {
                final sid = doc.data()['schoolId'] as String? ?? '';
                return sid.isEmpty;
              })
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['uid'] = doc.id;
                return UserModel.fromMap(data);
              })
              .toList();
          list.sort((a, b) => a.fullName.compareTo(b.fullName));
          return list;
        });
  }
}
