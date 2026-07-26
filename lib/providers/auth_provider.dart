import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/auth/auth_error_messages.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  // ⏱️ Auto checks auth session on startup
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    User? firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      try {
        _currentUser = await _authService.getUserData(firebaseUser.uid);
      } catch (e) {
        print("Auth initialization error: $e");
        _errorMessage = "Failed to load user profile.";
        _currentUser = null;
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // 🧹 Helper to clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 🔑 Sign In Action
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final normalizedEmail = email.trim().toLowerCase();

    try {
      User? user = await _authService.signIn(normalizedEmail, password);
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        _currentUser ??= await _authService.ensureUserProfile(
            uid: user.uid,
            email: user.email ?? normalizedEmail,
          );
        if (_currentUser == null) {
          throw FirebaseAuthException(
            code: 'profile-not-found',
            message: AuthErrorMessages.fromCode('profile-not-found'),
          );
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: AuthErrorMessages.fromCode('user-not-found'),
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  // 🚀 Sign Up Action
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      User? user = await _authService.signUp(email, password, name, role);
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Registration failed. Please try again.',
      );
    } catch (e) {
      _isLoading = false;
      if (e is FirebaseAuthException) {
        _errorMessage = e.message ?? "Registration failed";
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      if (e is FirebaseAuthException) {
        _errorMessage = e.message ?? 'Could not send reset email';
      } else {
        _errorMessage = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto({required Uint8List imageBytes}) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final imageUrl = await _storageService.uploadUserPhotoFromBytes(_currentUser!.uid, imageBytes);
      await _authService.updateProfilePic(_currentUser!.uid, imageUrl);
      _currentUser = _currentUser!.copyWith(profilePic: imageUrl);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 🚪 Sign Out Action
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
