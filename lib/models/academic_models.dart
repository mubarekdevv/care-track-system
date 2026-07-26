import '../core/domain/domain_enums.dart';
import '../data/firestore/firestore_helpers.dart';

class AttendanceRecordModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String classRoomId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final DateTime markedAt;

  const AttendanceRecordModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.classRoomId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedAt,
  });

  static String compositeId(String studentId, DateTime date) {
    final d = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${studentId}_$d';
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecordModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      classRoomId: map['classRoomId'] as String? ?? '',
      date: FirestoreHelpers.toDateTime(map['date']) ?? DateTime.now(),
      status: AttendanceStatus.fromId(map['status'] as String?),
      markedBy: map['markedBy'] as String? ?? '',
      markedAt: FirestoreHelpers.toDateTime(map['markedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'studentId': studentId,
        'classRoomId': classRoomId,
        'date': date,
        'status': status.id,
        'markedBy': markedBy,
        'markedAt': markedAt,
      };
}

class AssessmentModel {
  final String id;
  final String schoolId;
  final String studentId;
  final String enrollmentId;
  final String subjectId;
  final String teacherId;
  final String title;
  final double score;
  final double maxScore;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const AssessmentModel({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.enrollmentId,
    required this.subjectId,
    required this.teacherId,
    required this.title,
    required this.score,
    required this.maxScore,
    this.publishedAt,
    required this.createdAt,
  });

  bool get isPublished => publishedAt != null;

  double? get percentage =>
      maxScore > 0 ? (score / maxScore * 100).clamp(0, 100) : null;

  factory AssessmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssessmentModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      enrollmentId: map['enrollmentId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0,
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 100,
      publishedAt: FirestoreHelpers.toDateTime(map['publishedAt']),
      createdAt: FirestoreHelpers.toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'studentId': studentId,
        'enrollmentId': enrollmentId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'title': title,
        'score': score,
        'maxScore': maxScore,
        if (publishedAt != null) 'publishedAt': publishedAt,
        'createdAt': createdAt,
      };
}

class AssignmentModel {
  final String id;
  final String schoolId;
  final String classRoomId;
  final String subjectId;
  final String teacherId;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final DateTime createdAt;
  final List<String> attachmentUrls;

  const AssignmentModel({
    required this.id,
    required this.schoolId,
    required this.classRoomId,
    required this.subjectId,
    required this.teacherId,
    required this.title,
    this.description,
    this.dueAt,
    required this.createdAt,
    this.attachmentUrls = const [],
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      classRoomId: map['classRoomId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      dueAt: FirestoreHelpers.toDateTime(map['dueAt']),
      createdAt: FirestoreHelpers.toDateTime(map['createdAt']) ?? DateTime.now(),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classRoomId': classRoomId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'title': title,
        if (description != null) 'description': description,
        if (dueAt != null) 'dueAt': dueAt,
        'createdAt': createdAt,
        'attachmentUrls': attachmentUrls,
      };
}

/// Student turned in homework — visible to the assigning teacher.
class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String schoolId;
  final String classRoomId;
  final String teacherId;
  final String studentId;
  final String studentName;
  final String assignmentTitle;
  final String submittedByUserId;
  final DateTime submittedAt;

  const AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.schoolId,
    required this.classRoomId,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.assignmentTitle,
    required this.submittedByUserId,
    required this.submittedAt,
  });

  static String compositeId(String assignmentId, String studentId) =>
      '${assignmentId}_$studentId';

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentSubmissionModel(
      id: id,
      assignmentId: map['assignmentId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      classRoomId: map['classRoomId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      assignmentTitle: map['assignmentTitle'] as String? ?? '',
      submittedByUserId: map['submittedByUserId'] as String? ?? '',
      submittedAt: FirestoreHelpers.toDateTime(map['submittedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'assignmentId': assignmentId,
        'schoolId': schoolId,
        'classRoomId': classRoomId,
        'teacherId': teacherId,
        'studentId': studentId,
        'studentName': studentName,
        'assignmentTitle': assignmentTitle,
        'submittedByUserId': submittedByUserId,
        'submittedAt': submittedAt,
      };
}
