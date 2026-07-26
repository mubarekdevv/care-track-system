import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Prepares Firestore before the first read/write (especially on web).
Future<void> configureFirestore() async {
  final db = FirebaseFirestore.instance;

  if (kIsWeb) {
    db.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  try {
    await db.enableNetwork().timeout(const Duration(seconds: 8));
  } catch (_) {
    // Offline or slow network — reads may still succeed from cache.
  }
}
