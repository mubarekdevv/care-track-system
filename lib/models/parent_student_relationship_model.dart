import '../core/domain/domain_enums.dart';

class ParentStudentRelationshipModel {
  final String id;
  final String schoolId;
  final String parentId;
  final String studentId;
  final RelationshipType relationshipType;
  final bool isPrimary;
  final DateTime? createdAt;

  const ParentStudentRelationshipModel({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.studentId,
    required this.relationshipType,
    this.isPrimary = true,
    this.createdAt,
  });

  factory ParentStudentRelationshipModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ParentStudentRelationshipModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      parentId: map['parentId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      relationshipType:
          RelationshipType.fromId(map['relationshipType'] as String?),
      isPrimary: map['isPrimary'] as bool? ?? true,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'parentId': parentId,
        'studentId': studentId,
        'relationshipType': relationshipType.id,
        'isPrimary': isPrimary,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
