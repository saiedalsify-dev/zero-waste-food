import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readFirebaseDate(Object? value, {DateTime? fallback}) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }
  return fallback ?? DateTime.now();
}

Object writeFirebaseDate(DateTime value) => Timestamp.fromDate(value);
