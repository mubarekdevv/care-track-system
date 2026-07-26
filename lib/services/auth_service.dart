import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        UserModel newUser =
            UserModel(uid: user.uid, email: email, fullName: name, role: role);

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
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        data['uid'] = uid;
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print("Get user data error: $e");
      rethrow;
    }
  }

  Future<void> updateProfilePic(String uid, String profilePicUrl) async {
    await _db.collection('users').doc(uid).update({'profilePic': profilePicUrl}).timeout(const Duration(seconds: 10));
  }

  /// Ensures an authenticated user has a Firestore profile document.
  ///
  /// If the profile already exists it is returned; otherwise a default
  /// profile is created so a user who authenticated but has no profile
  /// (e.g. an interrupted sign-up) can still sign in.
  Future<UserModel?> ensureUserProfile({
    required String uid,
    required String email,
    String? fullName,
    String role = 'Parent',
  }) async {
    final docRef = _db.collection('users').doc(uid);
    final snapshot = await docRef.get().timeout(const Duration(seconds: 10));

    if (snapshot.exists) {
      final data =
          Map<String, dynamic>.from(snapshot.data() as Map<String, dynamic>);
      data['uid'] = uid;
      return UserModel.fromMap(data);
    }

    final newUser = UserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? email.split('@').first,
      role: role,
    );

    await docRef.set(newUser.toMap()).timeout(const Duration(seconds: 10));
    return newUser;
  }
}
