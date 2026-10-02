import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import '../utils/firestore_parse.dart';

class ShoppingPurchaseList {
  final String id;
  final DateTime date;
  final List<String> itemIds;
  final List<String> boughtItemIds;

  ShoppingPurchaseList({
    required this.id,
    required this.date,
    required List<String> itemIds,
    List<String> boughtItemIds = const [],
  }) : itemIds = List.unmodifiable(itemIds),
       boughtItemIds = List.unmodifiable(boughtItemIds);

  bool get isComplete => itemIds.isNotEmpty && boughtItemIds.length >= itemIds.length;

  ShoppingPurchaseList withBought(String itemId, bool bought) {
    final updated = {...boughtItemIds};
    bought ? updated.add(itemId) : updated.remove(itemId);
    return ShoppingPurchaseList(
      id: id,
      date: date,
      itemIds: itemIds,
      boughtItemIds: updated.where(itemIds.contains).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'itemIds': itemIds,
    'boughtItemIds': boughtItemIds,
  };

  factory ShoppingPurchaseList.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingPurchaseList(
      id: id,
      date: parseDate(map['date']),
      itemIds: List<String>.from(map['itemIds'] as List<dynamic>? ?? []),
      boughtItemIds: List<String>.from(map['boughtItemIds'] as List<dynamic>? ?? []),
    );
  }
}
