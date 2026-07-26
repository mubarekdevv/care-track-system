/// One grade level and the subjects this teacher can teach there.
class TeacherGradeTeaching {
  final String gradeLevelId;
  final List<String> subjectIds;

  const TeacherGradeTeaching({
    required this.gradeLevelId,
    required this.subjectIds,
  });

  factory TeacherGradeTeaching.fromMap(Map<String, dynamic> map) {
    final raw = map['subjectIds'];
    final ids = raw is List
        ? raw.map((e) => e.toString()).where((id) => id.isNotEmpty).toList()
        : <String>[];
    return TeacherGradeTeaching(
      gradeLevelId: map['gradeLevelId'] as String? ?? '',
      subjectIds: ids,
    );
  }

  Map<String, dynamic> toMap() => {
        'gradeLevelId': gradeLevelId,
        'subjectIds': subjectIds,
      };
}

/// Optional staff profile fields stored on `users/{uid}`.
class TeacherProfile {
  final String? employeeId;
  final String? department;
  final String? preferredGradeLevelId;
  /// @deprecated Use [teachingsByGrade]. Kept for older accounts.
  final String? preferredSubjectId;
  /// Flat list of all subject IDs (union). Synced on save for legacy queries.
  final List<String> teachableSubjectIds;
  /// Per-grade subjects — source of truth for assignment matching.
  final List<TeacherGradeTeaching> teachingsByGrade;

  const TeacherProfile({
    this.employeeId,
    this.department,
    this.preferredGradeLevelId,
    this.preferredSubjectId,
    this.teachableSubjectIds = const [],
    this.teachingsByGrade = const [],
  });

  factory TeacherProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TeacherProfile();

    var teachings = <TeacherGradeTeaching>[];
    final rawGrades = map['teachingsByGrade'];
    if (rawGrades is List) {
      for (final item in rawGrades) {
        if (item is Map<String, dynamic>) {
          final t = TeacherGradeTeaching.fromMap(item);
          if (t.gradeLevelId.isNotEmpty && t.subjectIds.isNotEmpty) {
            teachings.add(t);
          }
        }
      }
    }

    final rawIds = map['teachableSubjectIds'];
    var flatIds = <String>[];
    if (rawIds is List) {
      flatIds = rawIds.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
    }
    final legacyGrade = map['preferredGradeLevelId'] as String?;
    final legacySubject = map['preferredSubjectId'] as String?;
    if (teachings.isEmpty &&
        legacyGrade != null &&
        legacyGrade.isNotEmpty &&
        flatIds.isNotEmpty) {
      teachings = [
        TeacherGradeTeaching(gradeLevelId: legacyGrade, subjectIds: flatIds),
      ];
    } else if (flatIds.isEmpty && teachings.isNotEmpty) {
      flatIds = teachings.expand((t) => t.subjectIds).toSet().toList();
    }

    return TeacherProfile(
      employeeId: map['employeeId'] as String?,
      department: map['department'] as String?,
      preferredGradeLevelId: legacyGrade ?? teachings.firstOrNull?.gradeLevelId,
      preferredSubjectId: legacySubject,
      teachableSubjectIds: flatIds,
      teachingsByGrade: teachings,
    );
  }

  Map<String, dynamic> toMap() {
    final flat = teachingsByGrade.isNotEmpty
        ? teachingsByGrade.expand((t) => t.subjectIds).toSet().toList()
        : teachableSubjectIds;
    return {
      if (employeeId != null) 'employeeId': employeeId,
      if (department != null) 'department': department,
      if (teachingsByGrade.isNotEmpty)
        'teachingsByGrade': teachingsByGrade.map((t) => t.toMap()).toList(),
      if (flat.isNotEmpty) 'teachableSubjectIds': flat,
      if (teachingsByGrade.isNotEmpty) ...{
        'preferredGradeLevelId': teachingsByGrade.first.gradeLevelId,
        'preferredSubjectId': teachingsByGrade.first.subjectIds.first,
      },
    };
  }

  bool teachesSubjectForGrade(String gradeLevelId, String subjectId) {
    if (gradeLevelId.isEmpty || subjectId.isEmpty) return false;
    for (final t in teachingsByGrade) {
      if (t.gradeLevelId == gradeLevelId && t.subjectIds.contains(subjectId)) {
        return true;
      }
    }
    return false;
  }

  bool teachesSubject(String subjectId, {String? gradeLevelId}) {
    if (subjectId.isEmpty) return false;
    if (gradeLevelId != null && gradeLevelId.isNotEmpty) {
      return teachesSubjectForGrade(gradeLevelId, subjectId);
    }
    if (teachingsByGrade.isNotEmpty) {
      return teachingsByGrade.any((t) => t.subjectIds.contains(subjectId));
    }
    if (teachableSubjectIds.isNotEmpty) {
      return teachableSubjectIds.contains(subjectId);
    }
    return preferredSubjectId == subjectId;
  }

  bool get isSetupComplete =>
      teachingsByGrade.isNotEmpty &&
      teachingsByGrade.every((t) => t.subjectIds.isNotEmpty);
}

class HealthcareProfile {
  final String? clinicName;
  final String? licenseId;
  final String? room;
  final List<String> specialtyIds;

  const HealthcareProfile({
    this.clinicName,
    this.licenseId,
    this.room,
    this.specialtyIds = const [],
  });

  factory HealthcareProfile.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HealthcareProfile();
    return HealthcareProfile(
      clinicName: map['clinicName'] as String?,
      licenseId: map['licenseId'] as String?,
      room: map['room'] as String?,
      specialtyIds: List<String>.from(map['specialtyIds'] ?? []),
    );
  }

  bool coversSpecialty(String specialtyId) =>
      specialtyIds.contains(specialtyId);

  bool get isSetupComplete => specialtyIds.isNotEmpty;

  Map<String, dynamic> toMap() => {
        if (clinicName != null) 'clinicName': clinicName,
        if (licenseId != null) 'licenseId': licenseId,
        if (room != null) 'room': room,
        'specialtyIds': specialtyIds,
      };
}
