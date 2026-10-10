import '../utils/firestore_parse.dart';

/// Notificação de pagamento capturada no Android (gravada pelo serviço nativo).
class NotificationCapture {
  final String id;
  final String package;
  final String? title;
  final String? text;
  final DateTime postedAt;
  final int? amountCents;
  final String? merchant;
  final String? cardHint;
  final bool isRefund;
  final String status;
  final String? transactionId;

  const NotificationCapture({
    required this.id,
    required this.package,
    this.title,
    this.text,
    required this.postedAt,
    this.amountCents,
    this.merchant,
    this.cardHint,
    this.isRefund = false,
    required this.status,
    this.transactionId,
  });

  static const statusCreated = 'created';
  static const statusCreatedManually = 'created_manually';

  bool get hasTransaction => status == statusCreated || status == statusCreatedManually;

  /// Descrição do status para o usuário.
  String get statusLabel => switch (status) {
    statusCreated => 'Lançamento criado',
    statusCreatedManually => 'Lançado manualmente',
    'unparsed' => 'Não reconhecida',
    'unmatched_account' => 'Conta não identificada',
    'auto_disabled' => 'Criação automática desligada',
    _ => 'Erro ao processar',
  };

  factory NotificationCapture.fromMap(Map<String, dynamic> map, String id) {
    return NotificationCapture(
      id: id,
      package: map['package'] as String? ?? '',
      title: nonEmptyString(map['title']),
      text: nonEmptyString(map['text']),
      postedAt: parseDate(map['postedAt']),
      amountCents: (map['amountCents'] as num?)?.toInt(),
      merchant: nonEmptyString(map['merchant']),
      cardHint: nonEmptyString(map['cardHint']),
      isRefund: map['isRefund'] as bool? ?? false,
      status: map['status'] as String? ?? 'error',
      transactionId: nonEmptyString(map['transactionId']),
    );
  }
}
