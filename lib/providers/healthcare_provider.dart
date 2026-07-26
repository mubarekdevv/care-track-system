import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/firestore/firestore_health_repository.dart';
import '../models/child_model.dart';
import '../models/health_appointment_model.dart';
import '../models/health_profile_model.dart';
import '../services/database_service.dart';

class HealthcareProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirestoreHealthRepository _healthRepo = FirestoreHealthRepository();

  List<ChildModel> _patients = [];
  List<HealthAppointment> _appointments = [];
  List<HealthAppointment> _allAppointments = [];
  Set<String> _accessibleStudentIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<ChildModel>>? _patientsSubscription;
  StreamSubscription<List<String>>? _accessSubscription;
  StreamSubscription<List<HealthAppointment>>? _appointmentsSubscription;

  List<ChildModel> get patients => _patients;
  List<HealthAppointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get activePatientCount => _patients.length;

  int get totalVaccineRecords =>
      _patients.fold(0, (sum, child) => sum + child.vaccinations.length);

  List<HealthAppointment> get todayAppointments {
    final now = DateTime.now();
    final list = _appointments.where((appointment) {
      return appointment.scheduledAt.year == now.year &&
          appointment.scheduledAt.month == now.month &&
          appointment.scheduledAt.day == now.day;
    }).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  List<HealthAppointment> get upcomingAppointments {
    final list = List<HealthAppointment>.from(_appointments);
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  void startListening({required String healthcareUserId}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _patientsSubscription?.cancel();
    _accessSubscription?.cancel();
    _appointmentsSubscription?.cancel();

    _patientsSubscription =
        _healthRepo.watchPatientsForHealthcareProfessional(healthcareUserId).listen(
      (data) {
        _patients = data;
        _accessibleStudentIds = data.map((p) => p.id).toSet();
        _applyAppointmentFilter();
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _appointmentsSubscription = _healthRepo.watchAppointments().listen(
      (data) {
        _allAppointments = data;
        _applyAppointmentFilter();
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void _applyAppointmentFilter() {
    if (_accessibleStudentIds.isEmpty) {
      _appointments = [];
      return;
    }
    _appointments = _allAppointments
        .where((a) => _accessibleStudentIds.contains(a.childId))
        .toList();
  }

  void stopListening() {
    _patientsSubscription?.cancel();
    _accessSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    _patientsSubscription = null;
    _accessSubscription = null;
    _appointmentsSubscription = null;
    _patients = [];
    _appointments = [];
    _allAppointments = [];
    _accessibleStudentIds = {};
    _errorMessage = null;
    notifyListeners();
  }

  List<ChildModel> searchPatients(String query) {
    if (query.trim().isEmpty) return _patients;
    final normalized = query.toLowerCase();
    return _patients
        .where((patient) => patient.name.toLowerCase().contains(normalized))
        .toList();
  }

  Future<bool> updateGrowthMetrics({
    required String childId,
    required double height,
    required double weight,
  }) async {
    try {
      final checkup = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      await _dbService.updateChildFields(childId, {
        'latestHeight': height,
        'latestWeight': weight,
        'lastCheckup': checkup,
      });
      await _healthRepo.saveHealthProfile(
        HealthProfileModel(
          studentId: childId,
          latestHeight: height,
          latestWeight: weight,
          lastCheckup: checkup,
        ),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addVaccine({
    required String childId,
    required String vaccineName,
  }) async {
    try {
      final child = _patients.firstWhere((patient) => patient.id == childId);
      final updated = List<String>.from(child.vaccinations)..add(vaccineName);
      await _dbService.updateChildFields(childId, {'vaccinations': updated});
      await _healthRepo.saveHealthProfile(
        HealthProfileModel(
          studentId: childId,
          vaccinations: updated.map((v) => VaccinationRecord(name: v)).toList(),
          latestHeight: child.latestHeight,
          latestWeight: child.latestWeight,
          lastCheckup: child.lastCheckup.isNotEmpty ? child.lastCheckup : null,
        ),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> scheduleAppointment({
    required String childId,
    required String childName,
    required String title,
    required DateTime scheduledAt,
  }) async {
    try {
      final appointment = HealthAppointment(
        id: '',
        childId: childId,
        childName: childName,
        title: title,
        scheduledAt: scheduledAt,
      );
      await _healthRepo.scheduleAppointment(appointment);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _patientsSubscription?.cancel();
    _accessSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    super.dispose();
  }
}
