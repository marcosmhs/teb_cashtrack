class ShoppingPurchaseList {
  final String id;
  final DateTime date;
  final List<String> itemIds;
  final List<String> boughtItemIds;

  ShoppingPurchaseList({
    required this.id,
    required this.date,
    required this.itemIds,
    List<String>? boughtItemIds,
  }) : boughtItemIds = boughtItemIds ?? [];

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'itemIds': itemIds,
    'boughtItemIds': boughtItemIds,
  };

  factory ShoppingPurchaseList.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingPurchaseList(
      id: id,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      itemIds: List<String>.from(map['itemIds'] as List<dynamic>? ?? []),
      boughtItemIds: List<String>.from(map['boughtItemIds'] as List<dynamic>? ?? []),
    );
  }
}
