import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart' show IconData, Icons;

import '../utils/firestore_parse.dart';

enum AccountType {
  checking('checking', 'Conta Corrente', Icons.account_balance_outlined),
  creditCard('creditCard', 'Cartão de Crédito', Icons.credit_card),

  /// Mantido apenas para contas antigas; não é oferecido em novos cadastros.
  investment('investment', 'Investimento', Icons.trending_up);

  const AccountType(this.storageKey, this.label, this.icon);

  final String storageKey;
  final String label;
  final IconData icon;

  /// Tipos oferecidos no cadastro de contas.
  static const selectable = [checking, creditCard];

  /// Aceita a chave atual ou o rótulo gravado pelas versões antigas.
  static AccountType parse(Object? value) {
    return AccountType.values.firstWhere(
      (t) => t.storageKey == value || t.label == value,
      orElse: () => AccountType.checking,
    );
  }
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final int initialBalanceCents;
  final bool active;
  final DateTime createdAt;

  /// Dia de fechamento da fatura (1–31). Usado apenas por cartões de crédito.
  final int? closingDay;

  /// Meio de pagamento principal: já vem selecionado em novos lançamentos.
  /// Apenas uma conta do usuário fica marcada (ver [AccountController.saveAccount]).
  final bool isDefault;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalanceCents,
    required this.active,
    required this.createdAt,
    this.closingDay,
    this.isDefault = false,
  });

  bool get isCreditCard => type == AccountType.creditCard;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.storageKey,
      'initialBalanceCents': initialBalanceCents,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'closingDay': isCreditCard ? closingDay : null,
      'isDefault': isDefault,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map, String id) {
    final closingDay = (map['closingDay'] as num?)?.toInt();
    return Account(
      id: id,
      name: map['name'] as String? ?? '',
      type: AccountType.parse(map['type']),
      initialBalanceCents: parseCents(map, 'initialBalanceCents', 'balance'),
      active: map['active'] as bool? ?? true,
      createdAt: parseDate(map['createdAt']),
      closingDay: closingDay != null && closingDay >= 1 && closingDay <= 31 ? closingDay : null,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
