import '../core/health/health_concerns.dart';

class DoctorMatchRequest {
  final String id;
  final String schoolId;
  final String parentId;
  final String studentId;
  final String studentName;
  final String specialtyId;
  final String specialtyLabel;
  final String status;
  final String? parentNote;
  final DateTime? createdAt;

  const DoctorMatchRequest({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.studentName,
    required this.specialtyId,
    required this.specialtyLabel,
    this.status = 'pending',
    this.parentNote,
    this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isFulfilled => status == 'fulfilled';

  factory DoctorMatchRequest.fromMap(Map<String, dynamic> map, String id) {
    return DoctorMatchRequest(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      specialtyId: map['specialtyId'] as String? ?? '',
      specialtyLabel: map['specialtyLabel'] as String? ??
          HealthConcerns.byId(map['specialtyId'] as String?)?.label ??
          'Specialist',
      status: map['status'] as String? ?? 'pending',
      parentNote: map['parentNote'] as String?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? ''),
    );
  }
}

class StudentDoctorAssignment {
  final String id;
  final String schoolId;
  final String studentId;
  final String parentId;
  final String doctorId;
  final String doctorName;
  final String specialtyId;
  final String specialtyLabel;
  final String status;
  final DateTime? assignedAt;

  const StudentDoctorAssignment({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.parentId,
    required this.doctorId,
    required this.doctorName,
    required this.specialtyId,
    required this.specialtyLabel,
    this.status = 'active',
    this.assignedAt,
  });

  bool get isActive => status == 'active';

  factory StudentDoctorAssignment.fromMap(Map<String, dynamic> map, String id) {
    return StudentDoctorAssignment(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? 'Doctor',
      specialtyId: map['specialtyId'] as String? ?? '',
      specialtyLabel: map['specialtyLabel'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      assignedAt: DateTime.tryParse(map['assignedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'studentId': studentId,
        'parentId': parentId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'specialtyId': specialtyId,
        'specialtyLabel': specialtyLabel,
        'status': status,
        if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
      };
}

class MatchedDoctor {
  final String doctorId;
  final String fullName;
  final String email;
  final List<String> specialtyIds;
  final String? clinicName;

  const MatchedDoctor({
    required this.doctorId,
    required this.fullName,
    required this.email,
    required this.specialtyIds,
    this.clinicName,
  });
}
