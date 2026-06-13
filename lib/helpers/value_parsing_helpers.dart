import 'package:cloud_firestore/cloud_firestore.dart';

double? asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

Map<String, dynamic> toDynamicMap(Map<String, Object?> source) {
  return source.map(
    (String key, Object? value) => MapEntry<String, dynamic>(
      key,
      toDynamicValue(value),
    ),
  );
}

dynamic toDynamicValue(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) return value;
  if (value is Map) {
    return value.map<String, dynamic>(
      (dynamic key, dynamic nestedValue) => MapEntry<String, dynamic>(
        key.toString(),
        toDynamicValue(nestedValue),
      ),
    );
  }
  if (value is Iterable) {
    return value.map<dynamic>(toDynamicValue).toList(growable: false);
  }
  return value;
}
