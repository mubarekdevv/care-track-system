class ClassRoomModel {
  final String id;
  final String schoolId;
  final String gradeLevelId;
  final String name;
  final String? homeroomTeacherId;
  final int? capacity;
  final bool isActive;

  const ClassRoomModel({
    required this.id,
    required this.schoolId,
    required this.gradeLevelId,
    required this.name,
    this.homeroomTeacherId,
    this.capacity,
    this.isActive = true,
  });

  factory ClassRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassRoomModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      gradeLevelId: map['gradeLevelId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      homeroomTeacherId: map['homeroomTeacherId'] as String?,
      capacity: (map['capacity'] as num?)?.toInt(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'gradeLevelId': gradeLevelId,
        'name': name,
        if (homeroomTeacherId != null) 'homeroomTeacherId': homeroomTeacherId,
        if (capacity != null) 'capacity': capacity,
        'isActive': isActive,
      };
}
