import '../../models/user_model.dart';

abstract class UserRepository {
  Stream<UserModel?> watchUser(String uid);
  Future<UserModel?> getUser(String uid);
  Future<void> updateUser(UserModel user);
  Future<List<UserModel>> getUsersByRole(String schoolId, String role);
  Stream<List<UserModel>> watchUsersByRole(String schoolId, String role);
  Future<UserModel?> findUserByEmail(String email);
}

/// Admin-only operations — Phase 3 implementation.
abstract class AdminRepository {
  Future<void> bootstrapSchool(SchoolBootstrapRequest request);
  Future<bool> isAdminBootstrapNeeded(String schoolId);
}

class SchoolBootstrapRequest {
  final String schoolName;
  final String adminUid;
  final String adminEmail;
  final String adminFullName;

  const SchoolBootstrapRequest({
    required this.schoolName,
    required this.adminUid,
    required this.adminEmail,
    required this.adminFullName,
  });
}
