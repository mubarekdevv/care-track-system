import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register User
  Future<User?> registerUser(
      String email, String password, String name, String role) async {
    // 1. Create User in Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;

    // 2. Create User Profile in Firestore using the UserModel
    if (user != null) {
      UserModel newUser =
          UserModel(uid: user.uid, email: email, fullName: name, role: role);
      await _db.collection('users').doc(user.uid).set(newUser.toMap());
    }
    return user;
  }
}


