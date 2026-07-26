import '../core/domain/domain_enums.dart';

class ChildModel {
  final String id;
  final String name;
  final int age;
  final String parentId;
  final String schoolId;
  final String? gradeLevelId;
  final String? classRoomId;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String accountMode;
  final bool healthModuleEnabled;
  final List<String> healthConcernIds;
  final bool usesPrivateDoctor;
  final String? assignedDoctorId;
  final String imageUrl;
  final String? linkCode;
  final String? studentUserId;
  final List<String> vaccinations;
  final double? latestHeight;
  final double? latestWeight;
  final String lastCheckup;
  final int gamificationXp;
  final int gamificationLevel;
  final List<String> unlockedBadges;

  ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.parentId,
    this.schoolId = '',
    this.gradeLevelId,
    this.classRoomId,
    this.dateOfBirth,
    this.gender,
    this.accountMode = 'parent_managed',
    this.healthModuleEnabled = false,
    this.healthConcernIds = const [],
    this.usesPrivateDoctor = false,
    this.assignedDoctorId,
    required this.imageUrl,
    this.linkCode,
    this.studentUserId,
    this.vaccinations = const [],
    this.latestHeight,
    this.latestWeight,
    this.lastCheckup = '',
    this.gamificationXp = 0,
    this.gamificationLevel = 1,
    this.unlockedBadges = const [],
  });

  String get heightLabel =>
      latestHeight != null ? '${latestHeight!.toStringAsFixed(1)} cm' : 'Not recorded';

  String get weightLabel =>
      latestWeight != null ? '${latestWeight!.toStringAsFixed(1)} kg' : 'Not recorded';

  String get checkupLabel => lastCheckup.isNotEmpty ? lastCheckup : 'Not recorded';

  /// True when a student Firebase Auth account is connected to this school record.
  bool get isAccountLinked =>
      studentUserId != null && studentUserId!.isNotEmpty;

  // Convert Firebase Document to Flutter Object
  factory ChildModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChildModel(
      id: documentId,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? map['name'] as String
          : (map['fullName'] as String? ?? ''),
      age: map['age'] ?? 0,
      parentId: map['parentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      gradeLevelId: map['gradeLevelId'],
      classRoomId: map['classRoomId'],
      dateOfBirth: map['dateOfBirth'] is String
          ? DateTime.tryParse(map['dateOfBirth'])
          : (map['dateOfBirth'] is DateTime ? map['dateOfBirth'] : null),
      gender: Gender.fromId(map['gender'] as String?),
      accountMode: map['accountMode'] ?? 'parent_managed',
      healthModuleEnabled: map['healthModuleEnabled'] == true,
      healthConcernIds: List<String>.from(map['healthConcernIds'] ?? []),
      usesPrivateDoctor: map['usesPrivateDoctor'] == true,
      assignedDoctorId: map['assignedDoctorId'] as String?,
      imageUrl: map['imageUrl'] ?? '',
      linkCode: map['linkCode'] as String?,
      studentUserId: map['studentUserId'] as String?,
      vaccinations: List<String>.from(map['vaccinations'] ?? []),
      latestHeight: (map['latestHeight'] as num?)?.toDouble(),
      latestWeight: (map['latestWeight'] as num?)?.toDouble(),
      lastCheckup: map['lastCheckup'] ?? '',
      gamificationXp: (map['gamificationXp'] as num?)?.toInt() ?? 0,
      gamificationLevel: (map['gamificationLevel'] as num?)?.toInt() ?? 1,
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? []),
    );
  }

  // Convert Flutter Object to Map to save to Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'parentId': parentId,
      if (schoolId.isNotEmpty) 'schoolId': schoolId,
      if (gradeLevelId != null) 'gradeLevelId': gradeLevelId,
      if (classRoomId != null) 'classRoomId': classRoomId,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (gender != null) 'gender': gender!.id,
      'accountMode': accountMode,
      'healthModuleEnabled': healthModuleEnabled,
      'healthConcernIds': healthConcernIds,
      'usesPrivateDoctor': usesPrivateDoctor,
      if (assignedDoctorId != null) 'assignedDoctorId': assignedDoctorId,
      'imageUrl': imageUrl,
      'vaccinations': vaccinations,
      if (latestHeight != null) 'latestHeight': latestHeight,
      if (latestWeight != null) 'latestWeight': latestWeight,
      if (lastCheckup.isNotEmpty) 'lastCheckup': lastCheckup,
    };
  }
}
