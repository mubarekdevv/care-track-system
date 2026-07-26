// Backfill legacy `children` docs with schema v1 fields.
//
// Run from project root:
//   flutter run -t tool/backfill_student_schema.dart -d windows
//
// Or paste the update logic into Firebase Console for each doc.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'package:child_and_student_care_and_tracking_app/core/config/school_config.dart';
import 'package:child_and_student_care_and_tracking_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;
  final snap = await db.collection('children').get();
  var updated = 0;

  for (final doc in snap.docs) {
    final data = doc.data();
    if (data['schemaVersion'] != null) continue;

    await doc.reference.set({
      'schemaVersion': SchoolConfig.currentStudentSchemaVersion,
      'schoolId': SchoolConfig.defaultSchoolId,
      'fullName': data['name'] ?? data['fullName'] ?? '',
      'accountMode': 'parent_managed',
      'healthModuleEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
      if (data['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    updated++;
    // ignore: avoid_print
    print('Updated ${doc.id}');
  }

  // ignore: avoid_print
  print('Done. Updated $updated document(s).');
}
