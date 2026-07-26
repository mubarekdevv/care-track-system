import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/config/school_config.dart';
import '../core/health/health_concerns.dart';
import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_doctor_matching_repository.dart';
import '../data/firestore/firestore_family_repository.dart';
import '../data/firestore/firestore_health_repository.dart';
import '../data/firestore/firestore_student_repository.dart';
import '../models/child_model.dart';
import '../models/doctor_matching_models.dart';
import '../models/health_profile_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../services/doctor_matching_service.dart';
import '../services/family_account_service.dart';
import '../services/storage_service.dart';

class ChildProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final FirestoreStudentRepository _students = FirestoreStudentRepository();
  final FirestoreFamilyRepository _family = FirestoreFamilyRepository();
  final FamilyAccountService _familyAccounts = FamilyAccountService();

  List<ChildModel> _children = [];
  ChildModel? _linkedChild;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ChildModel>>? _childrenSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _linkedChildSubscription;

  List<ChildModel> get children => _children;
  ChildModel? get linkedChild => _linkedChild;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startListeningToChildren(String parentId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _childrenSubscription?.cancel();
    _childrenSubscription = _family.watchChildrenForParent(parentId).listen(
      (data) {
        _children = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void stopListening() {
    _childrenSubscription?.cancel();
    _childrenSubscription = null;
    _children = [];
    stopListeningToLinkedChild();
    notifyListeners();
  }

  /// Student dashboard: live profile from linked `children/{linkedStudentId}`.
  void startListeningToLinkedChild(String studentId) {
    _linkedChildSubscription?.cancel();
    _linkedChildSubscription = FirebaseFirestore.instance
        .collection('children')
        .doc(studentId)
        .snapshots()
        .listen(
      (snap) {
        if (snap.exists && snap.data() != null) {
          _linkedChild = ChildModel.fromMap(snap.data()!, snap.id);
        } else {
          _linkedChild = null;
        }
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void stopListeningToLinkedChild() {
    _linkedChildSubscription?.cancel();
    _linkedChildSubscription = null;
    _linkedChild = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateChildPhoto({
    required String childId,
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    if (imageBytes == null && imageFile == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageUrl = imageBytes != null
          ? await _storageService.uploadChildPhotoFromBytes(childId, imageBytes)
          : await _storageService.uploadChildPhotoFromFile(childId, imageFile!);

      await _dbService.updateChildFields(childId, {'imageUrl': imageUrl});

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Scenario 1: parent adds child with Firebase Auth student login (Cloud Function).
  Future<CreateStudentAccountResult?> addChildWithStudentAccount({
    required String name,
    required String studentEmail,
    required String parentId,
    required RelationshipType relationshipType,
    String schoolId = SchoolConfig.defaultSchoolId,
    String? gradeLevelId,
    String? classRoomId,
    DateTime? dateOfBirth,
    Gender? gender,
    Uint8List? imageBytes,
    File? imageFile,
    List<String> vaccinations = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _familyAccounts.createStudentAccount(
        fullName: name,
        studentEmail: studentEmail,
        dateOfBirthIso: dateOfBirth?.toIso8601String(),
        gender: gender?.id,
        gradeLevelId: gradeLevelId,
        classRoomId: classRoomId,
        schoolId: schoolId,
        relationshipType: relationshipType,
        vaccinations: vaccinations,
      );

      if (imageBytes != null || imageFile != null) {
        await _uploadChildPhoto(
          childId: result.studentId,
          imageBytes: imageBytes,
          imageFile: imageFile,
        );
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } on FamilyAccountException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Spark/free plan: profile + enrollment + 6-digit link code for student to connect later.
  Future<({bool success, String? linkCode})> addChild({
    required String name,
    required int age,
    required String parentId,
    String schoolId = SchoolConfig.defaultSchoolId,
    String? gradeLevelId,
    String? classRoomId,
    DateTime? dateOfBirth,
    Gender? gender,
    Uint8List? imageBytes,
    File? imageFile,
    List<String> vaccinations = const [],
    List<String> healthConcernIds = const [],
    bool usesPrivateDoctor = false,
    bool createEnrollment = true,
    RelationshipType relationshipType = RelationshipType.guardian,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docRef = FirebaseFirestore.instance.collection('children').doc();
      final childId = docRef.id;

      final child = ChildModel(
        id: childId,
        name: name,
        age: age,
        parentId: parentId,
        schoolId: schoolId,
        gradeLevelId: gradeLevelId,
        classRoomId: classRoomId,
        dateOfBirth: dateOfBirth,
        gender: gender,
        imageUrl: '',
        vaccinations: vaccinations,
        healthConcernIds: healthConcernIds,
        usesPrivateDoctor: usesPrivateDoctor,
      );

      await _dbService.setChild(
        childId,
        child,
        fullName: name,
        schemaVersion: SchoolConfig.currentStudentSchemaVersion,
      );

      await _family.createRelationship(
        parentId: parentId,
        studentId: childId,
        relationshipType: relationshipType,
        schoolId: schoolId,
      );

      if (createEnrollment &&
          gradeLevelId != null &&
          classRoomId != null &&
          gradeLevelId.isNotEmpty &&
          classRoomId.isNotEmpty) {
        final student = StudentModel(
          id: childId,
          schemaVersion: SchoolConfig.currentStudentSchemaVersion,
          schoolId: schoolId,
          parentId: parentId,
          fullName: name,
          dateOfBirth: dateOfBirth,
          age: age,
          gender: gender,
          imageUrl: '',
          vaccinations: vaccinations,
          gradeLevelId: gradeLevelId,
          classRoomId: classRoomId,
        );
        await _students.enrollStudent(
          student: student,
          classRoomId: classRoomId,
          gradeLevelId: gradeLevelId,
        );
      }

      String? linkCode;
      try {
        linkCode = await _family.createLinkCodeForStudent(
          studentId: childId,
          schoolId: schoolId,
          createdByUid: parentId,
          studentName: name,
        );
      } catch (_) {
        linkCode = null;
      }

      try {
        if (healthConcernIds.isNotEmpty) {
          await FirestoreHealthRepository().saveHealthProfile(
            HealthProfileModel(
              studentId: childId,
              medicalConditions: healthConcernIds
                  .map((id) => HealthConcerns.byId(id)?.label ?? id)
                  .toList(),
            ),
          );
        }

        if (!usesPrivateDoctor && healthConcernIds.isNotEmpty) {
          final hasClinicalConcerns = healthConcernIds.any(
            (id) => id.isNotEmpty && id != HealthConcerns.none,
          );
          if (hasClinicalConcerns) {
            await setHealthModuleEnabled(
              childId: childId,
              parentId: parentId,
              enabled: true,
            );
          }
          await DoctorMatchingService().processConcernsForStudent(
            schoolId: schoolId,
            parentId: parentId,
            studentId: childId,
            studentName: name,
            concernIds: healthConcernIds,
            usesPrivateDoctor: usesPrivateDoctor,
          );
        }
      } catch (_) {
        // Health/doctor sidecar must not block core enrollment.
      }

      _isLoading = false;
      notifyListeners();
      return (success: true, linkCode: linkCode);
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return (success: false, linkCode: null);
    }
  }

  Future<bool> assignDoctorToChild({
    required String childId,
    required String parentId,
    required String doctorId,
    required String specialtyId,
    required String schoolId,
  }) async {
    try {
      final repo = FirestoreDoctorMatchingRepository();
      final doctors = await repo.findDoctorsForSpecialty(
        schoolId: schoolId,
        specialtyId: specialtyId,
      );
      MatchedDoctor? doctor;
      for (final d in doctors) {
        if (d.doctorId == doctorId) {
          doctor = d;
          break;
        }
      }
      if (doctor == null) {
        _errorMessage = 'Doctor not found for this specialty.';
        notifyListeners();
        return false;
      }
      await repo.assignDoctor(
        schoolId: schoolId,
        parentId: parentId,
        studentId: childId,
        doctor: doctor,
        specialtyId: specialtyId,
      );
      final idx = _children.indexWhere((c) => c.id == childId);
      if (idx >= 0) {
        final old = _children[idx];
        _children[idx] = ChildModel(
          id: old.id,
          name: old.name,
          age: old.age,
          parentId: old.parentId,
          schoolId: old.schoolId,
          gradeLevelId: old.gradeLevelId,
          classRoomId: old.classRoomId,
          dateOfBirth: old.dateOfBirth,
          gender: old.gender,
          accountMode: old.accountMode,
          healthModuleEnabled: true,
          healthConcernIds: old.healthConcernIds,
          usesPrivateDoctor: old.usesPrivateDoctor,
          assignedDoctorId: doctorId,
          imageUrl: old.imageUrl,
          linkCode: old.linkCode,
          studentUserId: old.studentUserId,
          vaccinations: old.vaccinations,
          latestHeight: old.latestHeight,
          latestWeight: old.latestWeight,
          lastCheckup: old.lastCheckup,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> claimChildWithLinkCode({
    required String parentId,
    required String code,
    RelationshipType relationshipType = RelationshipType.guardian,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final name = await _family.claimLinkCode(
        parentId: parentId,
        code: code,
        relationshipType: relationshipType,
      );
      _isLoading = false;
      notifyListeners();
      return name;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> _uploadChildPhoto({
    required String childId,
    Uint8List? imageBytes,
    File? imageFile,
  }) async {
    final imageUrl = imageBytes != null
        ? await _storageService
            .uploadChildPhotoFromBytes(childId, imageBytes)
            .timeout(const Duration(seconds: 45))
        : await _storageService
            .uploadChildPhotoFromFile(childId, imageFile!)
            .timeout(const Duration(seconds: 45));
    await _dbService.updateChildFields(childId, {'imageUrl': imageUrl});
    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx >= 0) {
      final old = _children[idx];
      _children[idx] = ChildModel(
        id: old.id,
        name: old.name,
        age: old.age,
        parentId: old.parentId,
        schoolId: old.schoolId,
        gradeLevelId: old.gradeLevelId,
        classRoomId: old.classRoomId,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        accountMode: old.accountMode,
        healthModuleEnabled: old.healthModuleEnabled,
        imageUrl: imageUrl,
        vaccinations: old.vaccinations,
        latestHeight: old.latestHeight,
        latestWeight: old.latestWeight,
        lastCheckup: old.lastCheckup,
      );
    }
    if (_linkedChild?.id == childId) {
      final old = _linkedChild!;
      _linkedChild = ChildModel(
        id: old.id,
        name: old.name,
        age: old.age,
        parentId: old.parentId,
        schoolId: old.schoolId,
        gradeLevelId: old.gradeLevelId,
        classRoomId: old.classRoomId,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        accountMode: old.accountMode,
        healthModuleEnabled: old.healthModuleEnabled,
        imageUrl: imageUrl,
        vaccinations: old.vaccinations,
        latestHeight: old.latestHeight,
        latestWeight: old.latestWeight,
        lastCheckup: old.lastCheckup,
      );
    }
    notifyListeners();
  }

  /// Parent opt-in: share health profile with school healthcare staff.
  Future<bool> setHealthModuleEnabled({
    required String childId,
    required String parentId,
    required bool enabled,
  }) async {
    _errorMessage = null;
    try {
      await _dbService.updateChildFields(childId, {'healthModuleEnabled': enabled});
      final repo = FirestoreHealthRepository();
      if (enabled) {
        ChildModel? source;
        final idx = _children.indexWhere((c) => c.id == childId);
        if (idx >= 0) source = _children[idx];

        final existingAccess = await repo.getHealthcareAccess(childId);
        final allowed = List<String>.from(
          existingAccess?.allowedProfessionalIds ?? [],
        );
        final assignedDoctor = source?.assignedDoctorId;
        if (assignedDoctor != null &&
            assignedDoctor.isNotEmpty &&
            !allowed.contains(assignedDoctor)) {
          allowed.add(assignedDoctor);
        }

        await repo.setHealthcareAccess(
          HealthcareAccessModel(
            studentId: childId,
            parentId: parentId,
            granted: true,
            grantedAt: DateTime.now(),
            allowedProfessionalIds: allowed,
          ),
        );
        await repo.saveHealthProfile(
          HealthProfileModel(
            studentId: childId,
            vaccinations: (source?.vaccinations ?? [])
                .map((v) => VaccinationRecord(name: v))
                .toList(),
            latestHeight: source?.latestHeight,
            latestWeight: source?.latestWeight,
            lastCheckup: source != null && source.lastCheckup.isNotEmpty
                ? source.lastCheckup
                : null,
          ),
        );
      } else {
        await repo.setHealthcareAccess(
          HealthcareAccessModel(
            studentId: childId,
            parentId: parentId,
            granted: false,
            revokedAt: DateTime.now(),
          ),
        );
      }
      _patchChildHealthFlag(childId, enabled);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _patchChildHealthFlag(String childId, bool enabled) {
    final idx = _children.indexWhere((c) => c.id == childId);
    if (idx >= 0) {
      final old = _children[idx];
      _children[idx] = ChildModel(
        id: old.id,
        name: old.name,
        age: old.age,
        parentId: old.parentId,
        schoolId: old.schoolId,
        gradeLevelId: old.gradeLevelId,
        classRoomId: old.classRoomId,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        accountMode: old.accountMode,
        healthModuleEnabled: enabled,
        imageUrl: old.imageUrl,
        linkCode: old.linkCode,
        studentUserId: old.studentUserId,
        vaccinations: old.vaccinations,
        latestHeight: old.latestHeight,
        latestWeight: old.latestWeight,
        lastCheckup: old.lastCheckup,
      );
    }
    if (_linkedChild?.id == childId) {
      final old = _linkedChild!;
      _linkedChild = ChildModel(
        id: old.id,
        name: old.name,
        age: old.age,
        parentId: old.parentId,
        schoolId: old.schoolId,
        gradeLevelId: old.gradeLevelId,
        classRoomId: old.classRoomId,
        dateOfBirth: old.dateOfBirth,
        gender: old.gender,
        accountMode: old.accountMode,
        healthModuleEnabled: enabled,
        imageUrl: old.imageUrl,
        linkCode: old.linkCode,
        studentUserId: old.studentUserId,
        vaccinations: old.vaccinations,
        latestHeight: old.latestHeight,
        latestWeight: old.latestWeight,
        lastCheckup: old.lastCheckup,
      );
    }
  }

  @override
  void dispose() {
    _childrenSubscription?.cancel();
    _linkedChildSubscription?.cancel();
    super.dispose();
  }
}
