import '../models/tag.dart';
import '../models/transaction.dart';

/// Total de uma tag em um conjunto de lançamentos. [tagId] nulo = lançamentos sem tag.
class TagTotal {
  const TagTotal({required this.tagId, required this.cents, required this.count});

  final String? tagId;
  final int cents;
  final int count;
}

class TagStats {
  const TagStats._();

  /// Janela usada para ordenar as tags por uso recente.
  static const recentUsageDays = 30;

  /// Soma os lançamentos do [type] por tag, do maior para o menor valor.
  static List<TagTotal> totalsByTag(Iterable<Transaction> transactions, TransactionType type) {
    final cents = <String?, int>{};
    final counts = <String?, int>{};
    for (final t in transactions.where((t) => t.type == type)) {
      cents[t.tagId] = (cents[t.tagId] ?? 0) + t.amountCents;
      counts[t.tagId] = (counts[t.tagId] ?? 0) + 1;
    }
    return [for (final id in cents.keys) TagTotal(tagId: id, cents: cents[id]!, count: counts[id]!)]
      ..sort((a, b) => b.cents.compareTo(a.cents));
  }

  /// Ordena as tags pelo número de lançamentos nos últimos [days] dias (mais usadas primeiro).
  /// Empates (inclusive tags sem uso) ficam em ordem alfabética.
  static List<Tag> sortByRecentUsage(
    List<Tag> tags,
    Iterable<Transaction> transactions,
    DateTime now, {
    int days = recentUsageDays,
  }) {
    final since = now.subtract(Duration(days: days));
    final usage = <String, int>{};
    for (final t in transactions) {
      final tagId = t.tagId;
      if (tagId == null || t.date.isBefore(since) || t.date.isAfter(now)) continue;
      usage[tagId] = (usage[tagId] ?? 0) + 1;
    }
    return [...tags]..sort((a, b) {
      final byUsage = (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0);
      return byUsage != 0 ? byUsage : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}
