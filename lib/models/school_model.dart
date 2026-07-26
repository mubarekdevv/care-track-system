import '../core/domain/domain_enums.dart';

class SchoolModel {
  final String id;
  final String name;
  final SchoolType type;
  final String? address;
  final String timezone;
  final bool isActive;
  final String? primaryAdminUid;
  /// Highest standard grade level (1–12) this school uses; set via starter curriculum.
  final int? maxCatalogGradeLevel;
  /// Health specialties parents/doctors can use (empty = all catalog options).
  final List<String> enabledHealthSpecialtyIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SchoolModel({
    required this.id,
    required this.name,
    this.type = SchoolType.school,
    this.address,
    this.timezone = 'UTC',
    this.isActive = true,
    this.primaryAdminUid,
    this.maxCatalogGradeLevel,
    this.enabledHealthSpecialtyIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String id) {
    return SchoolModel(
      id: id,
      name: map['name'] as String? ?? '',
      type: SchoolType.fromId(map['type'] as String?),
      address: map['address'] as String?,
      timezone: map['timezone'] as String? ?? 'UTC',
      isActive: map['isActive'] as bool? ?? true,
      primaryAdminUid: map['primaryAdminUid'] as String?,
      maxCatalogGradeLevel: (map['maxCatalogGradeLevel'] as num?)?.toInt(),
      enabledHealthSpecialtyIds: List<String>.from(
        map['enabledHealthSpecialtyIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type.id,
        if (address != null) 'address': address,
        'timezone': timezone,
        'isActive': isActive,
        if (primaryAdminUid != null) 'primaryAdminUid': primaryAdminUid,
        if (maxCatalogGradeLevel != null) 'maxCatalogGradeLevel': maxCatalogGradeLevel,
        'enabledHealthSpecialtyIds': enabledHealthSpecialtyIds,
      };

  SchoolModel copyWith({
    String? name,
    String? primaryAdminUid,
    int? maxCatalogGradeLevel,
  }) {
    return SchoolModel(
      id: id,
      name: name ?? this.name,
      type: type,
      address: address,
      timezone: timezone,
      isActive: isActive,
      primaryAdminUid: primaryAdminUid ?? this.primaryAdminUid,
      maxCatalogGradeLevel: maxCatalogGradeLevel ?? this.maxCatalogGradeLevel,
    );
  }
}
