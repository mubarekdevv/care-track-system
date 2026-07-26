import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_helpers.dart';

class EnrollmentModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String parentId;
  final String classRoomId;
  final String gradeLevelId;
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final DateTime? withdrawnAt;

  const EnrollmentModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.parentId,
    required this.classRoomId,
    required this.gradeLevelId,
    this.status = EnrollmentStatus.active,
    required this.enrolledAt,
    this.withdrawnAt,
  });

  bool get isActive => status == EnrollmentStatus.active;

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      classRoomId: map['classRoomId'] as String? ?? '',
      gradeLevelId: map['gradeLevelId'] as String? ?? '',
      status: EnrollmentStatus.fromId(map['status'] as String?),
      enrolledAt: FirestoreHelpers.toDateTime(map['enrolledAt']) ?? DateTime.now(),
      withdrawnAt: FirestoreHelpers.toDateTime(map['withdrawnAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'studentId': studentId,
        'parentId': parentId,
        'classRoomId': classRoomId,
        'gradeLevelId': gradeLevelId,
        'status': status.id,
        'enrolledAt': enrolledAt,
        if (withdrawnAt != null) 'withdrawnAt': withdrawnAt,
      };
}
