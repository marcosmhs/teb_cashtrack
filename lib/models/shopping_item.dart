import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../utils/firestore_parse.dart';

class ShoppingItem {
  final String id;
  final String categoryId;
  final String description;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.categoryId,
    required this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'description': description,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingItem(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: parseDate(map['createdAt']),
    );
  }
}
