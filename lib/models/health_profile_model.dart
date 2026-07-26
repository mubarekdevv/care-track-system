import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationRecord {
  final String name;
  final String? dose;
  final DateTime? date;
  final String? provider;

  const VaccinationRecord({
    required this.name,
    this.dose,
    this.date,
    this.provider,
  });

  factory VaccinationRecord.fromMap(Map<String, dynamic> map) {
    return VaccinationRecord(
      name: map['name'] as String? ?? '',
      dose: map['dose'] as String?,
      date: DateTime.tryParse(map['date']?.toString() ?? ''),
      provider: map['provider'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (dose != null) 'dose': dose,
        if (date != null) 'date': date!.toIso8601String(),
        if (provider != null) 'provider': provider,
      };
}

class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      relation: map['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };
}

class HealthProfileModel {
  final String studentId;
  final String? bloodType;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> disabilities;
  final List<EmergencyContact> emergencyContacts;
  final List<String> currentMedications;
  final double? latestHeight;
  final double? latestWeight;
  final String? lastCheckup;
  final List<VaccinationRecord> vaccinations;
  final DateTime? updatedAt;

  const HealthProfileModel({
    required this.studentId,
    this.bloodType,
    this.allergies = const [],
    this.medicalConditions = const [],
    this.disabilities = const [],
    this.emergencyContacts = const [],
    this.currentMedications = const [],
    this.latestHeight,
    this.latestWeight,
    this.lastCheckup,
    this.vaccinations = const [],
    this.updatedAt,
  });

  factory HealthProfileModel.fromMap(Map<String, dynamic> map, String studentId) {
    return HealthProfileModel(
      studentId: studentId,
      bloodType: map['bloodType'] as String?,
      allergies: List<String>.from(map['allergies'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      disabilities: List<String>.from(map['disabilities'] ?? []),
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? [])
          .map((e) => EmergencyContact.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      latestHeight: (map['latestHeight'] as num?)?.toDouble(),
      latestWeight: (map['latestWeight'] as num?)?.toDouble(),
      lastCheckup: map['lastCheckup'] as String?,
      vaccinations: (map['vaccinations'] as List<dynamic>? ?? [])
          .map((e) => VaccinationRecord.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        if (bloodType != null) 'bloodType': bloodType,
        'allergies': allergies,
        'medicalConditions': medicalConditions,
        'disabilities': disabilities,
        'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
        'currentMedications': currentMedications,
        if (latestHeight != null) 'latestHeight': latestHeight,
        if (latestWeight != null) 'latestWeight': latestWeight,
        if (lastCheckup != null) 'lastCheckup': lastCheckup,
        'vaccinations': vaccinations.map((v) => v.toMap()).toList(),
      };
}

class HealthcareAccessModel {
  final String studentId;
  final String parentId;
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? revokedAt;
  final List<String> allowedProfessionalIds;

  const HealthcareAccessModel({
    required this.studentId,
    required this.parentId,
    this.granted = false,
    this.grantedAt,
    this.revokedAt,
    this.allowedProfessionalIds = const [],
  });

  factory HealthcareAccessModel.fromMap(Map<String, dynamic> map, String studentId) {
    return HealthcareAccessModel(
      studentId: studentId,
      parentId: map['parentId'] as String? ?? '',
      granted: map['granted'] as bool? ?? false,
      grantedAt: DateTime.tryParse(map['grantedAt']?.toString() ?? ''),
      revokedAt: DateTime.tryParse(map['revokedAt']?.toString() ?? ''),
      allowedProfessionalIds:
          List<String>.from(map['allowedProfessionalIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'parentId': parentId,
        'granted': granted,
        if (grantedAt != null) 'grantedAt': grantedAt,
        if (revokedAt != null) 'revokedAt': revokedAt,
        'allowedProfessionalIds': allowedProfessionalIds,
      };
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
