import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Linha de lançamento usada na Home, no extrato e na busca.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.tagName,
    this.accountName,
    this.onTap,
  });

  final Transaction transaction;
  final String? tagName;
  final String? accountName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final finance = context.finance;
    final subtitle = [formatDate(t.date), ?accountName].join(' • ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.isDebit ? finance.expenseContainer : finance.incomeContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Icon(
                t.isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                size: 20,
                color: t.isDebit ? finance.onExpenseContainer : finance.onIncomeContainer,
                semanticLabel: t.type.label,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                  ),
                  if (tagName != null) ...[const SizedBox(height: 4), TagChip(tagName!)],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AmountText(
              t.signedCents,
              signed: true,
              style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
