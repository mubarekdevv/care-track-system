import 'subject_model.dart';

/// Teacher assignment: one teacher teaches one subject in one class.
class ClassSubjectModel {
  final String id;
  final String schoolId;
  final String classRoomId;
  final String subjectId;
  final String teacherId;
  final bool isActive;
  final String? catalogTeacherName;
  final String? catalogTeacherEmail;
  final String? catalogSubjectIcon;

  const ClassSubjectModel({
    required this.id,
    required this.schoolId,
    required this.classRoomId,
    required this.subjectId,
    required this.teacherId,
    this.isActive = true,
    this.catalogTeacherName,
    this.catalogTeacherEmail,
    this.catalogSubjectIcon,
  });

  factory ClassSubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassSubjectModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      classRoomId: map['classRoomId'] as String? ?? '',
      subjectId: map['subjectId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      catalogTeacherName: map['catalogTeacherName'] as String?,
      catalogTeacherEmail: map['catalogTeacherEmail'] as String?,
      catalogSubjectIcon: map['catalogSubjectIcon'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'classRoomId': classRoomId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'isActive': isActive,
        if (catalogTeacherName != null) 'catalogTeacherName': catalogTeacherName,
        if (catalogTeacherEmail != null) 'catalogTeacherEmail': catalogTeacherEmail,
        if (catalogSubjectIcon != null) 'catalogSubjectIcon': catalogSubjectIcon,
      };
}

/// Resolved view for parent UI after enrollment.
class AssignedTeacherView {
  final SubjectModel subject;
  final String teacherId;
  final String teacherName;
  final String? teacherEmail;
  final String? subjectIconKey;
  final bool isLinked;

  const AssignedTeacherView({
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    this.teacherEmail,
    this.subjectIconKey,
    this.isLinked = false,
  });
}
