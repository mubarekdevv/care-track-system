class GradeLevelModel {
  final String id;
  final String schoolId;
  final String name;
  final int sortOrder;
  final String? band;
  final bool isActive;

  const GradeLevelModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.sortOrder,
    this.band,
    this.isActive = true,
  });

  factory GradeLevelModel.fromMap(Map<String, dynamic> map, String id) {
    return GradeLevelModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      band: map['band'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'schoolId': schoolId,
        'name': name,
        'sortOrder': sortOrder,
        if (band != null) 'band': band,
        'isActive': isActive,
      };
}
