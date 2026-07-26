import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config/school_config.dart';
import '../core/domain/domain_enums.dart';
import '../core/firebase/firestore_read.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Sign up with Email and Password
 Future<User?> signUp(
      String email, String password, String name, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        final schoolDoc = await _db
            .collection(FirestoreCollections.schools)
            .doc(SchoolConfig.defaultSchoolId)
            .get();
        final schoolId =
            schoolDoc.exists ? SchoolConfig.defaultSchoolId : null;

        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          fullName: name,
          role: role,
          schoolId: schoolId,
        );

        // ⏱️ Add a timeout. If Firestore is slow, it won't hang the app.
        await _db
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap())
            .timeout(const Duration(seconds: 10));
      }
      return user;
    } on FirebaseAuthException {
      // 🚀 Rethrow the specific Firebase error so the UI can show the right message
      rethrow;
    } catch (e) {
      print("Sign up error: $e");
      rethrow;
    }
  }

  // 🔑 Sign in with Email and Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      print("Login error: $e");
      rethrow;
    }
  }

// 🧐 Get User Data (To check their Role)
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await readDocumentWithRetry(_db.collection('users').doc(uid));
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data['uid'] = uid;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Get user data error (retry path): $e');
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 15));
        if (doc.exists) {
          final data = Map<String, dynamic>.from(doc.data()!);
          data['uid'] = uid;
          return UserModel.fromMap(data);
        }
        return null;
      } catch (e2) {
        print('Get user data error (fallback): $e2');
        rethrow;
      }
    }
  }

  Future<UserModel?> ensureUserProfile({
    required String uid,
    required String email,
    String fullName = 'KidCare User',
    String role = 'Parent',
  }) async {
    try {
      final existing = await getUserData(uid);
      if (existing != null) return existing;

      final profile = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        role: role,
      );
      await _db.collection('users').doc(uid).set(profile.toMap()).timeout(const Duration(seconds: 10));
      return profile;
    } catch (e) {
      print('Ensure user profile error: $e');
      return null;
    }
  }

  Future<void> updateProfilePic(String uid, String profilePicUrl) async {
    await _db.collection('users').doc(uid).update({'profilePic': profilePicUrl}).timeout(const Duration(seconds: 10));
  }

  /// Re-authenticates then sets a new password (force-change / profile flows).
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> clearMustChangePassword(String uid) async {
    await _db.collection('users').doc(uid).update({
      'mustChangePassword': false,
    }).timeout(const Duration(seconds: 10));
  }
}
