import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth error codes (and generic exceptions) to friendly,
/// user-facing messages so the UI never shows raw technical errors.
class AuthErrorMessages {
  const AuthErrorMessages._();

  static const String _fallback =
      'Something went wrong. Please try again in a moment.';

  static const Map<String, String> _messages = {
    'invalid-email': 'That email address doesn\'t look right.',
    'user-disabled': 'This account has been disabled. Contact support.',
    'user-not-found': 'No account found with those details.',
    'wrong-password': 'Incorrect email or password.',
    'invalid-credential': 'Incorrect email or password.',
    'email-already-in-use': 'An account already exists for that email.',
    'operation-not-allowed': 'This sign-in method is not enabled.',
    'weak-password': 'Please choose a stronger password (6+ characters).',
    'too-many-requests':
        'Too many attempts. Please wait a moment and try again.',
    'network-request-failed':
        'Network error. Check your connection and try again.',
    'requires-recent-login':
        'Please sign in again to complete this action.',
    'profile-not-found':
        'We couldn\'t load your profile. Please try again.',
    'registration-failed': 'Registration failed. Please try again.',
  };

  /// Returns a friendly message for a known Firebase error [code].
  static String fromCode(String code) => _messages[code] ?? _fallback;

  /// Extracts a friendly message from any thrown [error] object.
  static String fromException(Object error) {
    if (error is FirebaseAuthException) {
      return _messages[error.code] ?? (error.message ?? _fallback);
    }
    return _fallback;
  }
}
