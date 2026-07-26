/// Supported app roles — keep labels in sync with Firestore `users.role`.
enum UserRole {
  admin('Admin'),
  parent('Parent'),
  teacher('Teacher'),
  child('Child'),
  healthcare('Healthcare');

  const UserRole(this.label);

  final String label;

  static UserRole? fromLabel(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.label == value) return role;
    }
    return null;
  }

  static List<String> get labels => UserRole.values.map((r) => r.label).toList();

  /// Roles shown on public sign-up (Admin is assigned separately).
  static List<String> get registerableLabels =>
      UserRole.values.where((r) => r != UserRole.admin).map((r) => r.label).toList();

  bool get isStaff => this == UserRole.admin || this == UserRole.teacher || this == UserRole.healthcare;
}
