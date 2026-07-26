import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_helpers.dart';
import '../data/firestore/firestore_student_repository.dart';
import '../firebase_options.dart';
import '../models/student_model.dart';

/// Thrown when provisioning a linked parent/student account fails.
class FamilyAccountException implements Exception {
  final String code;
  final String message;

  const FamilyAccountException(this.code, this.message);

  @override
  String toString() => message;
}

/// Result when a parent provisions a student login (Scenario 1).
class CreateStudentAccountResult {
  final String studentId;
  final String studentUserId;
  final String studentEmail;
  final String temporaryPassword;

  const CreateStudentAccountResult({
    required this.studentId,
    required this.studentUserId,
    required this.studentEmail,
    required this.temporaryPassword,
  });

  factory CreateStudentAccountResult.fromMap(Map<String, dynamic> map) {
    return CreateStudentAccountResult(
      studentId: map['studentId'] as String? ?? '',
      studentUserId: map['studentUserId'] as String? ?? '',
      studentEmail: map['studentEmail'] as String? ?? '',
      temporaryPassword: map['temporaryPassword'] as String? ?? '',
    );
  }
}

/// Result when a student provisions a parent login (Scenario 2).
class CreateParentForStudentResult {
  final String parentId;
  final String parentEmail;
  final String temporaryPassword;

  const CreateParentForStudentResult({
    required this.parentId,
    required this.parentEmail,
    required this.temporaryPassword,
  });

  factory CreateParentForStudentResult.fromMap(Map<String, dynamic> map) {
    return CreateParentForStudentResult(
      parentId: map['parentId'] as String? ?? '',
      parentEmail: map['parentEmail'] as String? ?? '',
      temporaryPassword: map['temporaryPassword'] as String? ?? '',
    );
  }
}

/// Client-side account provisioning (Firebase Spark — no Cloud Functions).
///
/// Uses a secondary [FirebaseApp] so creating another user's Auth account does
/// not sign out the currently logged-in parent or student.
class FamilyAccountService {
  static const _secondaryAppName = 'FamilyAccountProvisioner';

  final FirebaseFirestore _db;
  final FirebaseAuth _primaryAuth;
  final FirestoreStudentRepository _students;

  FamilyAccountService({
    FirebaseFirestore? db,
    FirebaseAuth? primaryAuth,
    FirestoreStudentRepository? students,
  })  : _db = db ?? FirebaseFirestore.instance,
        _primaryAuth = primaryAuth ?? FirebaseAuth.instance,
        _students = students ?? FirestoreStudentRepository();

  static String generateTempPassword([int length = 12]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#\$';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    FirebaseApp app;
    try {
      app = Firebase.app(_secondaryAppName);
    } catch (_) {
      app = await Firebase.initializeApp(
        name: _secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<void> _deleteAuthUser({
    required FirebaseAuth secondary,
    required String email,
    required String password,
  }) async {
    try {
      await secondary.signInWithEmailAndPassword(email: email, password: password);
      await secondary.currentUser?.delete();
    } catch (_) {
      // Best-effort rollback when Firestore write fails after Auth create.
    } finally {
      await secondary.signOut();
    }
  }

  Future<void> _requireRole(String uid, String expectedRole) async {
    final doc = await _db.collection(FirestoreCollections.users).doc(uid).get();
    if (!doc.exists) {
      throw const FamilyAccountException(
        'failed-precondition',
        'User profile not found.',
      );
    }
    final role = doc.data()?['role'] as String? ?? '';
    if (role != expectedRole) {
      throw FamilyAccountException(
        'permission-denied',
        'Only ${expectedRole.toLowerCase()}s can perform this action.',
      );
    }
  }

  Future<CreateStudentAccountResult> createStudentAccount({
    required String fullName,
    required String studentEmail,
    String? dateOfBirthIso,
    String? gender,
    String? gradeLevelId,
    String? classRoomId,
    String schoolId = '',
    RelationshipType relationshipType = RelationshipType.guardian,
    List<String> vaccinations = const [],
  }) async {
    final parentUser = _primaryAuth.currentUser;
    if (parentUser == null) {
      throw const FamilyAccountException(
        'unauthenticated',
        'You must be signed in as a parent.',
      );
    }
    final parentId = parentUser.uid;
    await _requireRole(parentId, 'Parent');

    final trimmedName = fullName.trim();
    final email = studentEmail.trim().toLowerCase();
    if (trimmedName.isEmpty || email.isEmpty) {
      throw const FamilyAccountException(
        'invalid-argument',
        'Name and student email are required.',
      );
    }

    final parentDoc = await _db.collection(FirestoreCollections.users).doc(parentId).get();
    final parentSchoolId = (parentDoc.data()?['schoolId'] as String?)?.isNotEmpty == true
        ? parentDoc.data()!['schoolId'] as String
        : (schoolId.isNotEmpty ? schoolId : SchoolConfig.defaultSchoolId);

    DateTime? dob;
    int? age;
    if (dateOfBirthIso != null && dateOfBirthIso.isNotEmpty) {
      dob = DateTime.tryParse(dateOfBirthIso);
      if (dob != null) {
        final now = DateTime.now();
        age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
      }
    }

    final temporaryPassword = generateTempPassword();
    final secondary = await _secondaryAuth();
    UserCredential credential;

    try {
      credential = await secondary.createUserWithEmailAndPassword(
        email: email,
        password: temporaryPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const FamilyAccountException(
          'already-exists',
          'This student email is already registered.',
        );
      }
      throw FamilyAccountException(
        'internal',
        e.message ?? 'Could not create student login.',
      );
    }

    final studentUserId = credential.user!.uid;
    await secondary.signOut();

    final studentId = _db.collection(FirestoreCollections.children).doc().id;

    try {
      final batch = _db.batch();

      batch.set(
        _db.collection(FirestoreCollections.users).doc(studentUserId),
        FirestoreHelpers.withTimestamps(
          {
            'uid': studentUserId,
            'email': email,
            'fullName': trimmedName,
            'role': 'Child',
            'schoolId': parentSchoolId,
            'linkedStudentId': studentId,
            'mustChangePassword': true,
          },
          isCreate: true,
        ),
      );

      batch.set(
        _db.collection(FirestoreCollections.children).doc(studentId),
        FirestoreHelpers.withTimestamps(
          {
            'schemaVersion': SchoolConfig.currentStudentSchemaVersion,
            'schoolId': parentSchoolId,
            'parentId': parentId,
            'fullName': trimmedName,
            'name': trimmedName,
            if (age != null) 'age': age,
            if (dob != null) 'dateOfBirth': Timestamp.fromDate(dob),
            if (gender != null) 'gender': gender,
            'vaccinations': vaccinations,
            'imageUrl': '',
            'accountMode': StudentAccountMode.selfLogin.id,
            'studentUserId': studentUserId,
            'studentEmail': email,
            'healthModuleEnabled': false,
          },
          isCreate: true,
        ),
      );

      final relId = '${parentId}_$studentId';
      batch.set(
        _db.collection(FirestoreCollections.parentStudentRelationships).doc(relId),
        FirestoreHelpers.withTimestamps(
          {
            'schoolId': parentSchoolId,
            'parentId': parentId,
            'studentId': studentId,
            'relationshipType': relationshipType.id,
            'isPrimary': true,
          },
          isCreate: true,
        ),
      );

      await batch.commit();

      if (gradeLevelId != null &&
          classRoomId != null &&
          gradeLevelId.isNotEmpty &&
          classRoomId.isNotEmpty) {
        final student = StudentModel(
          id: studentId,
          schoolId: parentSchoolId,
          parentId: parentId,
          fullName: trimmedName,
          dateOfBirth: dob,
          age: age,
          gender: gender != null ? Gender.fromId(gender) : null,
          accountMode: StudentAccountMode.selfLogin,
          studentUserId: studentUserId,
          gradeLevelId: gradeLevelId,
          classRoomId: classRoomId,
          vaccinations: vaccinations,
        );
        await _students.enrollStudent(
          student: student,
          classRoomId: classRoomId,
          gradeLevelId: gradeLevelId,
        );
      }

      return CreateStudentAccountResult(
        studentId: studentId,
        studentUserId: studentUserId,
        studentEmail: email,
        temporaryPassword: temporaryPassword,
      );
    } catch (e) {
      await _deleteAuthUser(
        secondary: secondary,
        email: email,
        password: temporaryPassword,
      );
      if (e is FamilyAccountException) rethrow;
      throw FamilyAccountException('internal', e.toString());
    }
  }

  Future<CreateParentForStudentResult> createParentForStudent({
    required String parentName,
    required String parentEmail,
    RelationshipType relationshipType = RelationshipType.guardian,
  }) async {
    final studentUser = _primaryAuth.currentUser;
    if (studentUser == null) {
      throw const FamilyAccountException(
        'unauthenticated',
        'You must be signed in as a student.',
      );
    }
    final studentUserId = studentUser.uid;
    await _requireRole(studentUserId, 'Child');

    final trimmedName = parentName.trim();
    final email = parentEmail.trim().toLowerCase();
    if (trimmedName.isEmpty || email.isEmpty) {
      throw const FamilyAccountException(
        'invalid-argument',
        'Parent name and email are required.',
      );
    }

    final studentProfile =
        await _db.collection(FirestoreCollections.users).doc(studentUserId).get();
    final studentId = studentProfile.data()?['linkedStudentId'] as String?;
    if (studentId == null || studentId.isEmpty) {
      throw const FamilyAccountException(
        'failed-precondition',
        'Student profile is not linked. Complete registration first.',
      );
    }

    final childDoc = await _db.collection(FirestoreCollections.children).doc(studentId).get();
    final schoolId = (childDoc.data()?['schoolId'] as String?)?.isNotEmpty == true
        ? childDoc.data()!['schoolId'] as String
        : SchoolConfig.defaultSchoolId;

    final temporaryPassword = generateTempPassword();
    final secondary = await _secondaryAuth();
    UserCredential credential;

    try {
      credential = await secondary.createUserWithEmailAndPassword(
        email: email,
        password: temporaryPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const FamilyAccountException(
          'already-exists',
          'This parent email is already registered.',
        );
      }
      throw FamilyAccountException(
        'internal',
        e.message ?? 'Could not create parent login.',
      );
    }

    final parentId = credential.user!.uid;
    await secondary.signOut();

    try {
      final batch = _db.batch();

      batch.set(
        _db.collection(FirestoreCollections.users).doc(parentId),
        FirestoreHelpers.withTimestamps(
          {
            'uid': parentId,
            'email': email,
            'fullName': trimmedName,
            'role': 'Parent',
            'schoolId': schoolId,
            'mustChangePassword': true,
          },
          isCreate: true,
        ),
      );

      final relId = '${parentId}_$studentId';
      batch.set(
        _db.collection(FirestoreCollections.parentStudentRelationships).doc(relId),
        FirestoreHelpers.withTimestamps(
          {
            'schoolId': schoolId,
            'parentId': parentId,
            'studentId': studentId,
            'relationshipType': relationshipType.id,
            'isPrimary': true,
          },
          isCreate: true,
        ),
      );

      batch.set(
        _db.collection(FirestoreCollections.children).doc(studentId),
        FirestoreHelpers.withTimestamps(
          {'parentId': parentId},
        ),
      );

      batch.set(
        _db.collection('parent_invitations').doc(),
        FirestoreHelpers.withTimestamps(
          {
            'schoolId': schoolId,
            'studentId': studentId,
            'studentUserId': studentUserId,
            'parentEmail': email,
            'parentName': trimmedName,
            'relationshipType': relationshipType.id,
            'status': 'accepted',
            'createdParentId': parentId,
          },
          isCreate: true,
        ),
      );

      await batch.commit();

      return CreateParentForStudentResult(
        parentId: parentId,
        parentEmail: email,
        temporaryPassword: temporaryPassword,
      );
    } catch (e) {
      await _deleteAuthUser(
        secondary: secondary,
        email: email,
        password: temporaryPassword,
      );
      if (e is FamilyAccountException) rethrow;
      throw FamilyAccountException('internal', e.toString());
    }
  }
}
