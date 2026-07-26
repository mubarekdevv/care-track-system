import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Stores profile photos in Firestore (base64 data URL) — works on Spark without Storage.
class ProfilePhotoService {
  static const int _maxBytes = 120000;

  static String toDataUrl(Uint8List bytes) {
    if (bytes.length > _maxBytes) {
      throw Exception(
        'Photo is too large. Choose a smaller image (under ~100 KB).',
      );
    }
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  static Uint8List? bytesFromDataUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('data:image')) return null;
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  static bool isDataUrl(String? value) =>
      value != null && value.startsWith('data:image');

  static bool isHttpUrl(String? value) =>
      value != null &&
      (value.startsWith('http://') || value.startsWith('https://'));

  /// Save on the user account (parent, teacher, student login).
  static Future<String> saveForUser({
    required String uid,
    required Uint8List imageBytes,
  }) async {
    final dataUrl = toDataUrl(imageBytes);
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profilePic': dataUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return dataUrl;
  }

  /// Copy student login photo onto school child record so parents can see it.
  static Future<void> syncToChildSchoolRecord({
    required String studentId,
    required String photoValue,
  }) async {
    await FirebaseFirestore.instance.collection('children').doc(studentId).update({
      'imageUrl': photoValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
