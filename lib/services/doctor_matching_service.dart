import '../core/health/health_concerns.dart';
import '../data/firestore/firestore_doctor_matching_repository.dart';

/// Matches students to school doctors by health concern, or escalates to admin.
class DoctorMatchingService {
  final FirestoreDoctorMatchingRepository _repo;

  DoctorMatchingService({FirestoreDoctorMatchingRepository? repo})
      : _repo = repo ?? FirestoreDoctorMatchingRepository();

  /// Specialty labels with no registered school doctor yet (for parent enrollment UI).
  Future<List<String>> missingDoctorSpecialtyLabels({
    required String schoolId,
    required List<String> concernIds,
  }) async {
    final missing = <String>[];
    final unique = concernIds.toSet().where((id) => id.isNotEmpty).toList();
    for (final specialtyId in unique) {
      if (specialtyId == HealthConcerns.none) continue;
      final doctors = await _repo.findDoctorsForSpecialty(
        schoolId: schoolId,
        specialtyId: specialtyId,
      );
      if (doctors.isEmpty) {
        missing.add(HealthConcerns.byId(specialtyId)?.label ?? specialtyId);
      }
    }
    return missing;
  }

  Future<void> processConcernsForStudent({
    required String schoolId,
    required String parentId,
    required String studentId,
    required String studentName,
    required List<String> concernIds,
    required bool usesPrivateDoctor,
  }) async {
    if (usesPrivateDoctor || concernIds.isEmpty) return;

    final unique = concernIds.toSet().where((id) => id.isNotEmpty).toList();

    for (final specialtyId in unique) {
      if (specialtyId == HealthConcerns.none) continue;

      final doctors = await _repo.findDoctorsForSpecialty(
        schoolId: schoolId,
        specialtyId: specialtyId,
      );

      if (doctors.isEmpty) {
        final requestId = await _repo.createMatchRequest(
          schoolId: schoolId,
          parentId: parentId,
          studentId: studentId,
          studentName: studentName,
          specialtyId: specialtyId,
        );
        await _repo.notifyAdminsOfDoctorRequest(
          schoolId: schoolId,
          studentName: studentName,
          specialtyLabel: HealthConcerns.byId(specialtyId)?.label ?? specialtyId,
          requestId: requestId,
          parentId: parentId,
        );
      } else {
        final doctor = doctors.first;
        await _repo.assignDoctor(
          schoolId: schoolId,
          parentId: parentId,
          studentId: studentId,
          doctor: doctor,
          specialtyId: specialtyId,
        );
      }
    }
  }
}
