import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Resilient Firestore document read with retries for slow/cold connections.
Future<DocumentSnapshot<Map<String, dynamic>>> readDocumentWithRetry(
  DocumentReference<Map<String, dynamic>> ref, {
  int maxAttempts = 3,
  Duration baseTimeout = const Duration(seconds: 15),
}) async {
  Object? lastError;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      // On web, avoid serverAndCache toggling — it can trigger SDK internal errors.
      final source = kIsWeb ? Source.server : (attempt == 0 ? Source.serverAndCache : Source.server);
      return await ref
          .get(GetOptions(source: source))
          .timeout(baseTimeout + Duration(seconds: attempt * 5));
    } on TimeoutException catch (e) {
      lastError = e;
      debugPrint('Firestore read timeout (${attempt + 1}/$maxAttempts): ${ref.path}');
    } on FirebaseException catch (e) {
      if ((e.code == 'unavailable' || e.code == 'deadline-exceeded') &&
          attempt < maxAttempts - 1) {
        lastError = e;
      } else {
        rethrow;
      }
    }

    if (attempt < maxAttempts - 1) {
      await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
  }

  throw lastError ??
      TimeoutException(
        'Firestore read timed out for ${ref.path}',
        baseTimeout,
      );
}
