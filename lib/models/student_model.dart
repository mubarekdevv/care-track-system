import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import 'child_model.dart';

/// Canonical student profile — maps to Firestore `children/{id}`.
class StudentModel {
  final String id;
  final int schemaVersion;
  final String schoolId;
  final String parentId;
  final String fullName;
  final DateTime? dateOfBirth;
  final int? age;
  final Gender? gender;
  final String imageUrl;
  final StudentAccountMode accountMode;
  final String? studentUserId;
  final String? activeEnrollmentId;
  final String? gradeLevelId;
  final String? classRoomId;
  final bool healthModuleEnabled;
  final List<String> vaccinations;
  final double? latestHeight;
  final double? latestWeight;
  final String lastCheckup;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentModel({
    required this.id,
    this.schemaVersion = SchoolConfig.currentStudentSchemaVersion,
    required this.schoolId,
    required this.parentId,
    required this.fullName,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.imageUrl = '',
    this.accountMode = StudentAccountMode.parentManaged,
    this.studentUserId,
    this.activeEnrollmentId,
    this.gradeLevelId,
    this.classRoomId,
    this.healthModuleEnabled = false,
    this.vaccinations = const [],
    this.latestHeight,
    this.latestWeight,
    this.lastCheckup = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Display age — from DOB when available, else legacy field.
  int? get displayAge {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      var years = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        years--;
      }
      return years;
    }
    return age;
  }

  bool get hasSchoolEnrollment =>
      activeEnrollmentId != null && classRoomId != null && gradeLevelId != null;

  bool get hasSelfLogin =>
      accountMode == StudentAccountMode.selfLogin && studentUserId != null;

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      id: documentId,
      schemaVersion: map['schemaVersion'] as int? ?? 0,
      schoolId: map['schoolId'] as String? ?? SchoolConfig.defaultSchoolId,
      parentId: map['parentId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? map['name'] as String? ?? '',
      dateOfBirth: _timestampToDateTime(map['dateOfBirth']),
      age: (map['age'] as num?)?.toInt(),
      gender: Gender.fromId(map['gender'] as String?),
      imageUrl: map['imageUrl'] as String? ?? '',
      accountMode: StudentAccountMode.fromId(map['accountMode'] as String?),
      studentUserId: map['studentUserId'] as String?,
      activeEnrollmentId: map['activeEnrollmentId'] as String?,
      gradeLevelId: map['gradeLevelId'] as String?,
      classRoomId: map['classRoomId'] as String?,
      healthModuleEnabled: map['healthModuleEnabled'] as bool? ?? false,
      vaccinations: List<String>.from(map['vaccinations'] ?? []),
      latestHeight: (map['latestHeight'] as num?)?.toDouble(),
      latestWeight: (map['latestWeight'] as num?)?.toDouble(),
      lastCheckup: map['lastCheckup'] as String? ?? '',
      createdAt: _timestampToDateTime(map['createdAt']),
      updatedAt: _timestampToDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'schoolId': schoolId,
      'parentId': parentId,
      'fullName': fullName,
      'name': fullName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender!.id,
      'imageUrl': imageUrl,
      'accountMode': accountMode.id,
      if (studentUserId != null) 'studentUserId': studentUserId,
      if (activeEnrollmentId != null) 'activeEnrollmentId': activeEnrollmentId,
      if (gradeLevelId != null) 'gradeLevelId': gradeLevelId,
      if (classRoomId != null) 'classRoomId': classRoomId,
      'healthModuleEnabled': healthModuleEnabled,
      'vaccinations': vaccinations,
      if (latestHeight != null) 'latestHeight': latestHeight,
      if (latestWeight != null) 'latestWeight': latestWeight,
      if (lastCheckup.isNotEmpty) 'lastCheckup': lastCheckup,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  StudentModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    int? age,
    Gender? gender,
    String? imageUrl,
    StudentAccountMode? accountMode,
    String? studentUserId,
    String? activeEnrollmentId,
    String? gradeLevelId,
    String? classRoomId,
    bool? healthModuleEnabled,
    List<String>? vaccinations,
    double? latestHeight,
    double? latestWeight,
    String? lastCheckup,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id,
      schemaVersion: schemaVersion,
      schoolId: schoolId,
      parentId: parentId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      imageUrl: imageUrl ?? this.imageUrl,
      accountMode: accountMode ?? this.accountMode,
      studentUserId: studentUserId ?? this.studentUserId,
      activeEnrollmentId: activeEnrollmentId ?? this.activeEnrollmentId,
      gradeLevelId: gradeLevelId ?? this.gradeLevelId,
      classRoomId: classRoomId ?? this.classRoomId,
      healthModuleEnabled: healthModuleEnabled ?? this.healthModuleEnabled,
      vaccinations: vaccinations ?? this.vaccinations,
      latestHeight: latestHeight ?? this.latestHeight,
      latestWeight: latestWeight ?? this.latestWeight,
      lastCheckup: lastCheckup ?? this.lastCheckup,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Bridge from legacy [ChildModel] during migration.
  factory StudentModel.fromLegacyChild(ChildModel child) {
    return StudentModel(
      id: child.id,
      schemaVersion: 0,
      schoolId: SchoolConfig.defaultSchoolId,
      parentId: child.parentId,
      fullName: child.name,
      age: child.age,
      imageUrl: child.imageUrl,
      vaccinations: child.vaccinations,
      latestHeight: child.latestHeight,
      latestWeight: child.latestWeight,
      lastCheckup: child.lastCheckup,
    );
  }

  ChildModel toLegacyChild() {
    return ChildModel(
      id: id,
      name: fullName,
      age: displayAge ?? age ?? 0,
      parentId: parentId,
      imageUrl: imageUrl,
      vaccinations: vaccinations,
      latestHeight: latestHeight,
      latestWeight: latestWeight,
      lastCheckup: lastCheckup,
    );
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    // Firestore Timestamp handled at repository layer in Phase 3.
    return null;
  }
}
