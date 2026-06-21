import 'package:flutter/material.dart';
import '../controllers/transaction_controller.dart';
import '../controllers/tag_controller.dart';
import '../models/tag.dart';
import '../models/transaction.dart';
import 'transaction_edit_view.dart';

class TransactionStatementView extends StatelessWidget {
  final List<String> accountIds;
  final String accountName;

  const TransactionStatementView({super.key, required this.accountIds, required this.accountName});

  @override
  Widget build(BuildContext context) {
    final TransactionController txController = TransactionController();
    final TagController tagController = TagController();
    return Scaffold(
      appBar: AppBar(
        title: Text('Extrato - $accountName'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF10B981)),
        elevation: 0,
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: txController.getTransactionsForAccountIds(accountIds),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          final txs = snapshot.data ?? [];
          if (txs.isEmpty) return const Center(child: Text('Nenhum lançamento encontrado.'));
          final total = txs.fold<double>(0.0, (sum, tx) {
            return sum + (tx.type == 'debit' ? -tx.amount : tx.amount);
          });
          final totalText = total < 0
              ? '- R\$ ${total.abs().toStringAsFixed(2)}'
              : 'R\$ ${total.toStringAsFixed(2)}';
          final totalColor = total < 0 ? const Color(0xFFB91C1C) : const Color(0xFF10B981);
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total exibido',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      totalText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: totalColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TransactionEditView(transaction: tx)),
                      ),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        backgroundColor: tx.type == 'debit'
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFDCFCE7),
                        child: Icon(
                          tx.type == 'debit' ? Icons.remove : Icons.add,
                          color: tx.type == 'debit'
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF10B981),
                        ),
                      ),
                      title: Text(tx.details ?? (tx.type == 'debit' ? 'Débito' : 'Crédito')),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('', style: const TextStyle(color: Color(0xFF94A3B8))),
                          if (tx.tagId != null && tx.tagId!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            FutureBuilder<Tag?>(
                              future: tagController.getTagById(tx.tagId!),
                              builder: (context, snap) {
                                if (!snap.hasData || snap.data == null) {
                                  return const SizedBox.shrink();
                                }
                                final tag = snap.data as Tag;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tag.name,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        '',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: tx.type == 'debit'
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
