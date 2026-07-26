import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/config/school_config.dart';
import '../../core/domain/domain_enums.dart';
import '../../models/school_model.dart';
import '../../models/user_model.dart';
import '../../services/academic_catalog_seed_service.dart';
import '../repositories/user_repository.dart';
import 'firestore_helpers.dart';
import 'firestore_user_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _db;
  final FirestoreUserRepository _users;

  FirestoreAdminRepository({
    FirebaseFirestore? db,
    FirestoreUserRepository? users,
  })  : _db = db ?? FirebaseFirestore.instance,
        _users = users ?? FirestoreUserRepository(db: db);

  @override
  Future<bool> isAdminBootstrapNeeded(String schoolId) async {
    final doc = await _db.collection(FirestoreCollections.schools).doc(schoolId).get();
    return !doc.exists;
  }

  /// True when no school exists and no Admin user is registered yet.
  Future<bool> canClaimFirstAdmin() async {
    final needsBootstrap = await isAdminBootstrapNeeded(SchoolConfig.defaultSchoolId);
    if (!needsBootstrap) return false;
    return !(await _users.hasAnyAdmin());
  }

  @override
  Future<void> bootstrapSchool(SchoolBootstrapRequest request) async {
    const schoolId = SchoolConfig.defaultSchoolId;
    final schoolRef = _db.collection(FirestoreCollections.schools).doc(schoolId);
    final userRef = _db.collection(FirestoreCollections.users).doc(request.adminUid);

    final school = SchoolModel(
      id: schoolId,
      name: request.schoolName,
      type: SchoolType.school,
      isActive: true,
    );

    final batch = _db.batch();
    batch.set(
      schoolRef,
      FirestoreHelpers.withTimestamps({
        ...school.toMap(),
        'primaryAdminUid': request.adminUid,
      }, isCreate: true),
    );
    batch.set(
      userRef,
      {
        'role': 'Admin',
        'schoolId': schoolId,
        'fullName': request.adminFullName,
        'email': request.adminEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    await AcademicCatalogSeedService(db: _db).seedSchoolCatalogIfEmpty(schoolId: schoolId);
  }

  /// First registered user can become Admin when no school is set up yet.
  Future<void> claimFirstAdminAndBootstrap(SchoolBootstrapRequest request) async {
    if (!await canClaimFirstAdmin()) {
      throw StateError('School setup is already complete or an admin exists.');
    }
    await bootstrapSchool(request);
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    var snap = await _db
        .collection(FirestoreCollections.users)
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = Map<String, dynamic>.from(doc.data());
    data['uid'] = doc.id;
    return UserModel.fromMap(data);
  }

  Future<void> promoteToAdmin({
    required String targetUid,
    required String schoolId,
  }) async {
    await _db.collection(FirestoreCollections.users).doc(targetUid).set(
      {
        'role': 'Admin',
        'schoolId': schoolId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> demoteAdmin({
    required String targetUid,
    required String fallbackRole,
  }) async {
    await _db.collection(FirestoreCollections.users).doc(targetUid).set(
      {
        'role': fallbackRole,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> transferPrimaryAdmin({
    required String schoolId,
    required String newPrimaryAdminUid,
  }) async {
    await _db.collection(FirestoreCollections.schools).doc(schoolId).set(
      {
        'primaryAdminUid': newPrimaryAdminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> ensurePrimaryAdminUid({
    required String schoolId,
    required String adminUid,
  }) async {
    final schoolRef = _db.collection(FirestoreCollections.schools).doc(schoolId);
    final doc = await schoolRef.get();
    if (!doc.exists) return;
    if ((doc.data()?['primaryAdminUid'] as String? ?? '').isNotEmpty) return;
    await schoolRef.set(
      {
        'primaryAdminUid': adminUid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
