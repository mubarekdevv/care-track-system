import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_helpers.dart';
/// When a grade is not ready for enrollment, parents alert admins; admins alert parents when ready.
class EnrollmentReadinessService {
  final FirebaseFirestore _db;

  EnrollmentReadinessService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Parent selected a grade that is not fully staffed — notify school admin once.
  Future<void> reportParentInterest({
    required String parentId,
    required String gradeLevelId,
    required String gradeName,
    required String classRoomId,
    required String schoolId,
    List<String> missingSubjects = const [],
  }) async {
    if (classRoomId.isEmpty) return;

    final existing = await _db
        .collection(FirestoreCollections.enrollmentReadinessRequests)
        .where('parentId', isEqualTo: parentId)
        .where('classRoomId', isEqualTo: classRoomId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final ref = await _db
        .collection(FirestoreCollections.enrollmentReadinessRequests)
        .add(
      FirestoreHelpers.withTimestamps(
        {
          'schoolId': schoolId,
          'parentId': parentId,
          'gradeLevelId': gradeLevelId,
          'gradeName': gradeName,
          'classRoomId': classRoomId,
          'missingSubjects': missingSubjects,
          'status': 'pending',
        },
        isCreate: true,
      ),
    );

    final subjects = missingSubjects.isEmpty
        ? 'some subjects'
        : missingSubjects.join(', ');
    await _notifyAdmins(
      schoolId: schoolId,
      title: 'Parent waiting to enroll',
      body:
          'A parent wants to enroll a child in $gradeName but teachers are missing for: $subjects. '
          'Assign teachers in Staff tab, then they can complete enrollment.',
      relatedEntityId: ref.id,
    );
  }

  /// After admin assigns a teacher, notify parents who were waiting on this class.
  Future<void> notifyParentsIfSectionReady({
    required String classRoomId,
    required String gradeName,
    required bool canEnroll,
  }) async {
    if (!canEnroll) return;

    final snap = await _db
        .collection(FirestoreCollections.enrollmentReadinessRequests)
        .where('classRoomId', isEqualTo: classRoomId)
        .where('status', isEqualTo: 'pending')
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    final notifiedParents = <String>{};

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'status': 'fulfilled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final parentId = doc.data()['parentId'] as String? ?? '';
      if (parentId.isEmpty || notifiedParents.contains(parentId)) continue;
      notifiedParents.add(parentId);

      await _db.collection(FirestoreCollections.notifications).add({
        'recipientId': parentId,
        'recipientRole': 'Parent',
        'type': NotificationType.enrollmentReady.id,
        'title': 'Enrollment now open',
        'body':
            '$gradeName is ready. All teachers are assigned — you can enroll your child now.',
        'relatedStudentId': classRoomId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> watchPendingForSchool(String schoolId) {
    return _db
        .collection(FirestoreCollections.enrollmentReadinessRequests)
        .where('schoolId', isEqualTo: schoolId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> _notifyAdmins({
    required String schoolId,
    required String title,
    required String body,
    required String relatedEntityId,
  }) async {
    final admins = await _db
        .collection(FirestoreCollections.users)
        .where('role', isEqualTo: 'Admin')
        .get();

    for (final doc in admins.docs) {
      final data = doc.data();
      final adminSchool = data['schoolId'] as String?;
      if (adminSchool != null &&
          adminSchool.isNotEmpty &&
          adminSchool != schoolId) {
        continue;
      }
      await _db.collection(FirestoreCollections.notifications).add({
        'recipientId': doc.id,
        'recipientRole': 'Admin',
        'type': NotificationType.announcement.id,
        'title': title,
        'body': body,
        'relatedEntityId': relatedEntityId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
