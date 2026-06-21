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
    'createdAt': createdAt.toIso8601String(),
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingItem(
      id: id,
      categoryId: map['categoryId'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
