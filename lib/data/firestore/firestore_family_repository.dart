import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/school_config.dart';
import '../../core/domain/domain_enums.dart';
import '../../models/child_model.dart';
import '../../models/parent_student_relationship_model.dart';
import 'firestore_helpers.dart';

class FirestoreFamilyRepository {
  final FirebaseFirestore _db;

  FirestoreFamilyRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _relationships =>
      _db.collection(FirestoreCollections.parentStudentRelationships);

  CollectionReference<Map<String, dynamic>> get _children =>
      _db.collection(FirestoreCollections.children);

  Future<void> createRelationship({
    required String parentId,
    required String studentId,
    required RelationshipType relationshipType,
    String schoolId = SchoolConfig.defaultSchoolId,
    bool isPrimary = true,
  }) async {
    final existing = await _relationships
        .where('parentId', isEqualTo: parentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final relId = '${parentId}_$studentId';
    await _relationships.doc(relId).set(
      FirestoreHelpers.withTimestamps(
        {
          'schoolId': schoolId,
          'parentId': parentId,
          'studentId': studentId,
          'relationshipType': relationshipType.id,
          'isPrimary': isPrimary,
        },
        isCreate: true,
      ),
    );
  }

  /// Parent dashboard: children linked via relationship (with legacy parentId fallback).
  Stream<List<ChildModel>> watchChildrenForParent(String parentId) {
    return _relationships
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .asyncMap((relSnap) async {
      final studentIds = relSnap.docs
          .map((d) => d.data()['studentId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (studentIds.isEmpty) {
        return _loadLegacyChildrenByParentId(parentId);
      }

      final children = <ChildModel>[];
      for (final studentId in studentIds) {
        final doc = await _children.doc(studentId).get();
        if (doc.exists) {
          children.add(ChildModel.fromMap(doc.data()!, doc.id));
        }
      }
      children.sort((a, b) => a.name.compareTo(b.name));
      return children;
    });
  }

  Future<List<ChildModel>> _loadLegacyChildrenByParentId(String parentId) async {
    final snap = await _children.where('parentId', isEqualTo: parentId).get();
    final list = snap.docs
        .map((d) => ChildModel.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<ParentStudentRelationshipModel>> watchRelationshipsForParent(
    String parentId,
  ) {
    return _relationships
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ParentStudentRelationshipModel.fromMap(d.data(), d.id))
            .toList());
  }

  static String generateLinkCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<String> createLinkCodeForStudent({
    required String studentId,
    required String schoolId,
    required String createdByUid,
    String? studentName,
  }) async {
    final code = generateLinkCode();
    await _db.collection(FirestoreCollections.familyLinkCodes).doc(code).set(
      FirestoreHelpers.withTimestamps(
        {
          'schoolId': schoolId,
          'studentId': studentId,
          'createdBy': createdByUid,
          if (studentName != null && studentName.trim().isNotEmpty)
            'studentName': studentName.trim(),
        },
        isCreate: true,
      ),
    );
    await _children.doc(studentId).set(
      {'linkCode': code, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    return code;
  }

  /// Parent enters code from student — links accounts (no Cloud Functions).
  Future<String> claimLinkCode({
    required String parentId,
    required String code,
    RelationshipType relationshipType = RelationshipType.guardian,
  }) async {
    final normalized = code.trim();
    if (normalized.length != 6) {
      throw Exception('Enter the 6-digit code from your child.');
    }

    final linkDoc =
        await _db.collection(FirestoreCollections.familyLinkCodes).doc(normalized).get();
    if (!linkDoc.exists) {
      throw Exception('Invalid or expired link code.');
    }

    final studentId = linkDoc.data()?['studentId'] as String? ?? '';
    if (studentId.isEmpty) throw Exception('Invalid link code data.');

    final childDoc = await _children.doc(studentId).get();
    if (!childDoc.exists) throw Exception('Student profile not found.');

    final schoolId =
        childDoc.data()?['schoolId'] as String? ?? SchoolConfig.defaultSchoolId;
    final studentName =
        childDoc.data()?['fullName'] as String? ?? childDoc.data()?['name'] as String? ?? 'Student';

    await createRelationship(
      parentId: parentId,
      studentId: studentId,
      relationshipType: relationshipType,
      schoolId: schoolId,
    );

    await _children.doc(studentId).set(
      {
        'parentId': parentId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return studentName;
  }

  /// Student enters parent-provided code and links their auth user
  /// to an existing student profile without re-entering full profile data.
  Future<String> linkStudentAuthWithCode({
    required String code,
    required String studentUserId,
    required String studentEmail,
    required String studentFullName,
  }) async {
    final normalized = code.trim();
    if (normalized.length != 6) {
      throw Exception('Enter the 6-digit code from your parent.');
    }

    final linkDoc =
        await _db.collection(FirestoreCollections.familyLinkCodes).doc(normalized).get();
    if (!linkDoc.exists) {
      throw Exception('Invalid or expired link code.');
    }

    final studentId = linkDoc.data()?['studentId'] as String? ?? '';
    if (studentId.isEmpty) throw Exception('Invalid link code data.');

    final alreadyLinked =
        linkDoc.data()?['linkedStudentUserId'] as String? ?? '';
    if (alreadyLinked.isNotEmpty && alreadyLinked != studentUserId) {
      throw Exception('This code was already used. Ask your parent for a new code.');
    }

    final expectedName = (linkDoc.data()?['studentName'] as String? ?? '').trim();
    if (expectedName.isNotEmpty &&
        expectedName.toLowerCase() != studentFullName.trim().toLowerCase()) {
      throw Exception(
        'Name mismatch: this code is for "$expectedName". '
        'Sign out and register with that exact name, or ask your parent to re-add you.',
      );
    }

    // Do not read children/{studentId} here — students cannot read that doc
    // until linked; validation uses family_link_codes only.
    final linkRef =
        _db.collection(FirestoreCollections.familyLinkCodes).doc(normalized);
    final childRef = _children.doc(studentId);

    final batch = _db.batch();
    batch.set(
      childRef,
      {
        'studentUserId': studentUserId,
        'studentEmail': studentEmail,
        'accountMode': StudentAccountMode.selfLogin.id,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.update(linkRef, {
      'linkedStudentUserId': studentUserId,
      'linkedAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Could not link your profile. Please sign out and back in, then try again. '
          'If it persists, ask your parent to create a new link code.',
        );
      }
      rethrow;
    }

    return studentId;
  }

  /// Parent can show this anytime; reads `children.linkCode` or matching code doc.
  Future<String?> getLinkCodeForStudent(String studentId) async {
    final codes = await _db
        .collection(FirestoreCollections.familyLinkCodes)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (codes.docs.isNotEmpty) return codes.docs.first.id;

    try {
      final childDoc = await _children.doc(studentId).get();
      if (!childDoc.exists) return null;
      final onChild = childDoc.data()?['linkCode'] as String? ?? '';
      if (onChild.length == 6) return onChild;
    } catch (_) {
      // Students may not have permission to read children/{id} yet.
    }

    return null;
  }

  /// Creates a fresh code if none exists (parent must own the child).
  Future<String> ensureLinkCodeForStudent({
    required String studentId,
    required String schoolId,
    required String createdByUid,
    required String studentName,
  }) async {
    final existing = await getLinkCodeForStudent(studentId);
    if (existing != null && existing.length == 6) return existing;

    return createLinkCodeForStudent(
      studentId: studentId,
      schoolId: schoolId,
      createdByUid: createdByUid,
      studentName: studentName,
    );
  }

  /// Child already linked to a school profile (by user doc or children record).
  Future<String?> findStudentIdForAuthUser(String studentUserId) async {
    final snap = await _children
        .where('studentUserId', isEqualTo: studentUserId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<bool> parentHasAccessToStudent({
    required String parentId,
    required String studentId,
  }) async {
    final rel = await _relationships
        .where('parentId', isEqualTo: parentId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (rel.docs.isNotEmpty) return true;

    final child = await _children.doc(studentId).get();
    if (!child.exists) return false;
    return child.data()?['parentId'] == parentId;
  }
}
