class Transaction {
  final String id;
  final DateTime date;
  final String accountId;
  final double amount;
  final String? details;
  final String? tagId;
  final String type; // 'debit' or 'credit'

  Transaction({
    required this.id,
    required this.date,
    required this.accountId,
    required this.amount,
    this.details,
    this.tagId,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'accountId': accountId,
      'amount': amount,
      'details': details ?? '',
      'tagId': tagId ?? '',
      'type': type,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      accountId: map['accountId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      details: (map['details'] as String?)?.isNotEmpty == true ? map['details'] as String : null,
      tagId: (map['tagId'] as String?)?.isNotEmpty == true ? map['tagId'] as String : null,
      type: map['type'] as String? ?? 'debit',
    );
  }
}
