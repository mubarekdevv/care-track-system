import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/auth/auth_error_messages.dart';
import '../core/constants/user_role.dart';
import '../data/firestore/firestore_family_repository.dart';
import '../models/user_model.dart';
import '../core/photo/profile_photo_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreFamilyRepository _family = FirestoreFamilyRepository();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profilePhotoPreview;
  bool _profilePhotoUploading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get mustChangePassword => _currentUser?.mustChangePassword == true;
  Uint8List? get profilePhotoPreview => _profilePhotoPreview;
  bool get profilePhotoUploading => _profilePhotoUploading;

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
        await _ensureStudentLinkOnUserDoc();
      } catch (e) {
        debugPrint('Auth initialization error: $e');
        if (_currentUser == null) {
          _errorMessage = 'Failed to load user profile.';
        }
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
        await _ensureStudentLinkOnUserDoc();
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
      debugPrint('Login error: $e');
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

    final normalizedEmail = email.trim().toLowerCase();

    try {
      User? user = await _authService.signUp(normalizedEmail, password, name.trim(), role);
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
        _currentUser ??= UserModel(
            uid: user.uid,
            email: normalizedEmail,
            fullName: name.trim(),
            role: role,
          );
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
      _errorMessage = AuthErrorMessages.fromException(e);
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

  /// Shows [bytes] on every avatar immediately; uploads in the background.
  Future<bool> updateProfilePhoto({required Uint8List imageBytes}) async {
    if (_currentUser == null) return false;

    _profilePhotoPreview = imageBytes;
    _profilePhotoUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoValue = await ProfilePhotoService.saveForUser(
        uid: _currentUser!.uid,
        imageBytes: imageBytes,
      );
      final linkedStudentId = _currentUser!.linkedStudentId;
      if (linkedStudentId != null && linkedStudentId.isNotEmpty) {
        await ProfilePhotoService.syncToChildSchoolRecord(
          studentId: linkedStudentId,
          photoValue: photoValue,
        );
      }
      _currentUser = _currentUser!.copyWith(profilePic: photoValue);
      _profilePhotoPreview = null;
      _profilePhotoUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _profilePhotoUploading = false;
      notifyListeners();
      return false;
    }
  }

  void clearProfilePhotoPreview() {
    _profilePhotoPreview = null;
    notifyListeners();
  }

  Future<bool> completePasswordChange({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      await _authService.clearMustChangePassword(_currentUser!.uid);
      _currentUser = _currentUser!.copyWith(mustChangePassword: false);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = AuthErrorMessages.fromException(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUserProfile() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    _currentUser = await _authService.getUserData(uid);
    await _ensureStudentLinkOnUserDoc();
    notifyListeners();
  }

  /// If the student already linked once, restore [linkedStudentId] on the user doc.
  Future<void> _ensureStudentLinkOnUserDoc() async {
    final user = _currentUser;
    if (user == null) return;
    if (UserRole.fromLabel(user.role) != UserRole.child) return;
    if (user.linkedStudentId != null && user.linkedStudentId!.isNotEmpty) {
      return;
    }

    try {
      final studentId = await _family.findStudentIdForAuthUser(user.uid);
      if (studentId == null || studentId.isEmpty) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'linkedStudentId': studentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUser = user.copyWith(linkedStudentId: studentId);
    } catch (e) {
      debugPrint('Student link repair skipped: $e');
    }
  }

  bool get isStudentProfileComplete {
    final user = _currentUser;
    if (user == null) return false;
    if (UserRole.fromLabel(user.role) != UserRole.child) return true;
    return user.linkedStudentId != null && user.linkedStudentId!.isNotEmpty;
  }

  bool get isTeacherProfileComplete {
    final user = _currentUser;
    if (user == null) return false;
    if (UserRole.fromLabel(user.role) != UserRole.teacher) return true;
    return user.teacherProfile?.isSetupComplete ?? false;
  }

  bool get isHealthcareProfileComplete {
    final user = _currentUser;
    if (user == null) return false;
    if (UserRole.fromLabel(user.role) != UserRole.healthcare) return true;
    return user.healthcareProfile?.isSetupComplete ?? false;
  }

  bool get shouldShowTeacherProfileSetup {
    final user = _currentUser;
    if (user == null) return false;
    if (UserRole.fromLabel(user.role) != UserRole.teacher) return false;
    if (isTeacherProfileComplete) return false;
    return !user.teacherProfileSetupDeferred;
  }

  bool get shouldShowHealthcareProfileSetup {
    final user = _currentUser;
    if (user == null) return false;
    if (UserRole.fromLabel(user.role) != UserRole.healthcare) return false;
    if (isHealthcareProfileComplete) return false;
    return !user.healthcareProfileSetupDeferred;
  }

  Future<bool> deferTeacherProfileSetup() async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'teacherProfileSetupDeferred': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUser = user.copyWith(teacherProfileSetupDeferred: true);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Defer teacher profile setup: $e');
      return false;
    }
  }

  Future<bool> deferHealthcareProfileSetup() async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'healthcareProfileSetupDeferred': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUser = user.copyWith(healthcareProfileSetupDeferred: true);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Defer healthcare profile setup: $e');
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
