import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/domain/domain_enums.dart';
import '../../models/child_model.dart';
import '../../models/health_appointment_model.dart';
import '../../models/health_profile_model.dart';
import '../repositories/health_repository.dart';
import 'firestore_doctor_matching_repository.dart';
import 'firestore_helpers.dart';

class FirestoreHealthRepository implements HealthRepository {
  final FirebaseFirestore _db;

  FirestoreHealthRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection(FirestoreCollections.healthProfiles);

  CollectionReference<Map<String, dynamic>> get _access =>
      _db.collection(FirestoreCollections.healthcareAccess);

  @override
  Stream<HealthProfileModel?> watchHealthProfile(String studentId) {
    return _profiles.doc(studentId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HealthProfileModel.fromMap(snap.data()!, snap.id);
    });
  }

  @override
  Future<void> saveHealthProfile(HealthProfileModel profile) async {
    await _profiles.doc(profile.studentId).set(
          FirestoreHelpers.withTimestamps(profile.toMap(), isCreate: true),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<HealthcareAccessModel?> watchHealthcareAccess(String studentId) {
    return _access.doc(studentId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return HealthcareAccessModel.fromMap(snap.data()!, snap.id);
    });
  }

  Future<HealthcareAccessModel?> getHealthcareAccess(String studentId) async {
    final doc = await _access.doc(studentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return HealthcareAccessModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> setHealthcareAccess(HealthcareAccessModel access) async {
    final data = access.toMap();
    if (access.grantedAt != null) {
      data['grantedAt'] = Timestamp.fromDate(access.grantedAt!);
    }
    if (access.revokedAt != null) {
      data['revokedAt'] = Timestamp.fromDate(access.revokedAt!);
    }
    await _access.doc(access.studentId).set(
          FirestoreHelpers.withTimestamps(data, isCreate: true),
          SetOptions(merge: true),
        );
  }

  @override
  Stream<List<String>> watchAccessibleStudentIds(String healthcareUserId) {
    return _access.where('granted', isEqualTo: true).snapshots().map((snap) {
      final ids = <String>[];
      for (final doc in snap.docs) {
        final allowed = List<String>.from(doc.data()['allowedProfessionalIds'] ?? []);
        if (allowed.isNotEmpty && !allowed.contains(healthcareUserId)) continue;
        ids.add(doc.id);
      }
      return ids;
    });
  }

  /// Loads child records the healthcare user may view (opt-in access + direct assignments).
  Stream<List<ChildModel>> watchAccessiblePatients(String healthcareUserId) {
    return watchPatientsForHealthcareProfessional(healthcareUserId);
  }

  Stream<List<ChildModel>> watchPatientsForHealthcareProfessional(
    String healthcareUserId,
  ) {
    final doctorRepo = FirestoreDoctorMatchingRepository();
    final controller = StreamController<List<ChildModel>>.broadcast();
    Set<String> accessIds = {};
    Set<String> assignedIds = {};

    Future<void> emitPatients() async {
      final ids = {...accessIds, ...assignedIds};
      if (ids.isEmpty) {
        if (!controller.isClosed) controller.add([]);
        return;
      }

      final patients = <ChildModel>[];
      for (final id in ids) {
        final doc =
            await _db.collection(FirestoreCollections.children).doc(id).get();
        if (!doc.exists) continue;
        final child = ChildModel.fromMap(doc.data()!, doc.id);
        final directlyAssigned = assignedIds.contains(id);
        if (!child.healthModuleEnabled &&
            !directlyAssigned &&
            child.healthConcernIds.isEmpty) {
          continue;
        }
        patients.add(child);
      }
      patients.sort((a, b) => a.name.compareTo(b.name));
      if (!controller.isClosed) controller.add(patients);
    }

    StreamSubscription<List<String>>? accessSub;
    StreamSubscription<List<String>>? assignedSub;

    controller.onListen = () {
      accessSub = watchAccessibleStudentIds(healthcareUserId).listen(
        (ids) {
          accessIds = ids.toSet();
          emitPatients();
        },
        onError: controller.addError,
      );
      assignedSub =
          doctorRepo.watchAssignedStudentIdsForDoctor(healthcareUserId).listen(
        (ids) {
          assignedIds = ids.toSet();
          emitPatients();
        },
        onError: controller.addError,
      );
    };

    controller.onCancel = () {
      accessSub?.cancel();
      assignedSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<HealthAppointment>> watchAppointments({String? studentId}) {
    Query<Map<String, dynamic>> query = _db.collection('health_appointments');
    if (studentId != null) {
      query = query.where('childId', isEqualTo: studentId);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => HealthAppointment.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return list;
    });
  }

  @override
  Future<void> scheduleAppointment(HealthAppointment appointment) async {
    await _db.collection('health_appointments').add(appointment.toMap());
  }
}
