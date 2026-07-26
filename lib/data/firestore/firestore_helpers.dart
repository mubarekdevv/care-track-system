import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelpers {
  FirestoreHelpers._();

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static dynamic toFirestoreDate(DateTime? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value);
  }

  static Map<String, dynamic> withTimestamps(
    Map<String, dynamic> data, {
    bool isCreate = false,
  }) {
    final now = FieldValue.serverTimestamp();
    return {
      ...data,
      if (isCreate) 'createdAt': now,
      'updatedAt': now,
    };
  }
}
