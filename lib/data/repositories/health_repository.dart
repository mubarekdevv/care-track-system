import '../../models/health_appointment_model.dart';
import '../../models/health_profile_model.dart';

/// Opt-in health module with parent permission gate.
abstract class HealthRepository {
  Stream<HealthProfileModel?> watchHealthProfile(String studentId);
  Future<void> saveHealthProfile(HealthProfileModel profile);

  Stream<HealthcareAccessModel?> watchHealthcareAccess(String studentId);
  Future<void> setHealthcareAccess(HealthcareAccessModel access);

  /// Only students with granted access — for healthcare dashboard.
  Stream<List<String>> watchAccessibleStudentIds(String healthcareUserId);

  Stream<List<HealthAppointment>> watchAppointments({String? studentId});
  Future<void> scheduleAppointment(HealthAppointment appointment);
}
