import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth errors to clear, actionable copy for the UI.
class AuthErrorMessages {
  AuthErrorMessages._();

  static String fromException(Object error) {
    if (error is FirebaseAuthException) {
      return fromCode(error.code, fallback: error.message);
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Database access denied. Ask your admin to deploy the latest Firestore rules, then try again.';
      }
      if (error.code == 'unavailable' || error.code == 'deadline-exceeded') {
        return 'Could not reach the database. Check your internet connection, then try again.';
      }
      if (error.code == 'internal') {
        return 'Database connection error. Refresh the page and try signing in again.';
      }
    }
    if (error is TimeoutException) {
      return 'Could not load your profile in time. Check your internet connection, then try again.';
    }
    final message = error.toString();
    if (message.contains('INTERNAL ASSERTION') ||
        message.contains('firestore') && message.contains('Unexpected state')) {
      return 'Database connection error. Refresh the page (Ctrl+F5) and try signing in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String fromCode(String code, {String? fallback}) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support for help.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password. If you are new, create an account first, or use Forgot password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app. Enable Email/Password in Firebase Authentication.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'profile-not-found':
        return 'Your account signed in, but the profile is missing. Try registering again or contact support.';
      case 'permission-denied':
        return 'Database access denied. Deploy the latest Firestore rules and try again.';
      default:
        return fallback ?? 'Authentication failed. Please try again.';
    }
  }
}
