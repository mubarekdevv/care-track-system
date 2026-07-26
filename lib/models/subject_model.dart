class SubjectModel {
  final String id;
  final String schoolId;
  final String name;
  final String? code;
  final bool isActive;

  const SubjectModel({
    required this.id,
    required this.schoolId,
    required this.name,
    this.code,
    this.isActive = true,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String id) {
    return SubjectModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      code: map['code'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'name': name,
        if (code != null) 'code': code,
        'isActive': isActive,
      };
}
