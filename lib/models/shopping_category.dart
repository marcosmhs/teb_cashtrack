class ShoppingCategory {
  final String id;
  final String name;

  ShoppingCategory({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'name': name};

  factory ShoppingCategory.fromMap(Map<String, dynamic> map, String id) {
    return ShoppingCategory(id: id, name: map['name'] as String? ?? '');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ShoppingCategory && runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
