class Account {
  final String id;
  final String name;
  final String email;
  final String type;
  final double balance;
  final bool active;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.balance,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'type': type,
      'balance': balance,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map, String id) {
    return Account(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      type: map['type'] as String? ?? 'Conta Corrente',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
