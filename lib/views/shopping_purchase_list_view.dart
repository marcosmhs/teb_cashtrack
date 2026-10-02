import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../controllers/shopping_purchase_list_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_purchase_list.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'shopping_purchase_list_create_view.dart';

Future<bool> _confirmDeleteList(BuildContext context, ShoppingPurchaseList list) {
  return confirmAction(
    context,
    title: 'Excluir lista?',
    message: 'Excluir a lista de ${formatDate(list.date)}? Os itens cadastrados não são afetados.',
    confirmLabel: 'Excluir',
    destructive: true,
  );
}

void _openEditor(BuildContext context, [ShoppingPurchaseList? list]) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ShoppingPurchaseListCreateView(purchaseList: list)));
}

/// Aba com as listas de compras, da mais recente para a mais antiga.
class ShoppingPurchaseListsTab extends StatefulWidget {
  const ShoppingPurchaseListsTab({super.key});

  @override
  State<ShoppingPurchaseListsTab> createState() => _ShoppingPurchaseListsTabState();
}

class _ShoppingPurchaseListsTabState extends State<ShoppingPurchaseListsTab>
    with AutomaticKeepAliveClientMixin {
  final _controller = ShoppingPurchaseListController();
  late final Stream<List<ShoppingPurchaseList>> _lists = _controller.getPurchaseLists();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<ShoppingPurchaseList>>(
      stream: _lists,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error);
        final lists = snapshot.data;
        if (lists == null) return const LoadingView();

        return ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Nova lista de compras'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (lists.isEmpty)
                const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Nenhuma lista de compras ainda.',
                  message: 'Cadastre itens na aba Itens e monte sua primeira lista.',
                )
              else
                for (final list in lists) ...[
                  _PurchaseListCard(
                    list: list,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShoppingPurchaseListDetailView(listId: list.id),
                      ),
                    ),
                    onEdit: () => _openEditor(context, list),
                    onDelete: () async {
                      if (await _confirmDeleteList(context, list)) {
                        await _controller.deletePurchaseList(list.id);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseListCard extends StatelessWidget {
  const _PurchaseListCard({
    required this.list,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final ShoppingPurchaseList list;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final total = list.itemIds.length;
    final bought = list.boughtItemIds.length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    list.isComplete ? Icons.check_circle : Icons.shopping_cart_outlined,
                    color: list.isComplete
                        ? context.finance.income
                        : context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lista de ${formatDate(list.date)}', style: context.text.titleMedium),
                        Text(
                          '$bought de $total itens comprados',
                          style: context.text.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<VoidCallback>(
                    tooltip: 'Mais opções',
                    onSelected: (action) => action(),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: onEdit, child: const Text('Editar itens')),
                      PopupMenuItem(value: onDelete, child: const Text('Excluir lista')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : bought / total,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailData {
  final ShoppingPurchaseList? list;
  final List<ShoppingItem> items;
  final Map<String, String> categoryNames;
  final List<ShoppingCategory> categories;

  _DetailData(this.list, this.items, this.categories)
    : categoryNames = {for (final c in categories) c.id: c.name};
}

/// Lista de compras em uso: marca itens como comprados, sincronizando em tempo real.
class ShoppingPurchaseListDetailView extends StatefulWidget {
  const ShoppingPurchaseListDetailView({super.key, required this.listId});

  final String listId;

  @override
  State<ShoppingPurchaseListDetailView> createState() => _ShoppingPurchaseListDetailViewState();
}

class _ShoppingPurchaseListDetailViewState extends State<ShoppingPurchaseListDetailView> {
  final _listController = ShoppingPurchaseListController();
  late final Stream<_DetailData> _data = Rx.combineLatest3(
    _listController.watchPurchaseList(widget.listId),
    ShoppingItemController().getItems(),
    ShoppingCategoryController().getCategories(),
    _DetailData.new,
  );
  final Set<String> _filterCategoryIds = {};
  bool _hideBought = false;

  Future<void> _toggle(ShoppingPurchaseList list, String itemId, bool bought) async {
    try {
      await _listController.savePurchaseList(list.withBought(itemId, bought));
    } catch (e) {
      debugPrint('Erro ao atualizar lista: $e');
      if (mounted) showMessage(context, 'Não foi possível atualizar o item.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_DetailData>(
      stream: _data,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final list = data?.list;
        return Scaffold(
          appBar: AppBar(
            title: Text(list == null ? 'Lista de compras' : 'Lista de ${formatDate(list.date)}'),
            actions: [
              if (list != null) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar itens',
                  onPressed: () => _openEditor(context, list),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: context.colors.error),
                  tooltip: 'Excluir lista',
                  onPressed: () async {
                    if (!await _confirmDeleteList(context, list)) return;
                    await _listController.deletePurchaseList(list.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            ],
          ),
          body: snapshot.hasError
              ? ErrorView(error: snapshot.error)
              : data == null
              ? const LoadingView()
              : list == null
              ? const EmptyState(icon: Icons.delete_outline, title: 'Esta lista foi excluída.')
              : _buildBody(data, list),
        );
      },
    );
  }

  Widget _buildBody(_DetailData data, ShoppingPurchaseList list) {
    final itemsById = {for (final i in data.items) i.id: i};
    var entries = list.itemIds
        .map(
          (id) =>
              itemsById[id] ??
              ShoppingItem(id: id, categoryId: '', description: 'Item removido do cadastro'),
        )
        .toList();
    if (_filterCategoryIds.isNotEmpty) {
      entries = entries.where((i) => _filterCategoryIds.contains(i.categoryId)).toList();
    }
    if (_hideBought) {
      entries = entries.where((i) => !list.boughtItemIds.contains(i.id)).toList();
    }
    entries.sort((a, b) => a.description.toLowerCase().compareTo(b.description.toLowerCase()));

    final usedCategories = data.categories
        .where((c) => list.itemIds.any((id) => itemsById[id]?.categoryId == c.id))
        .toList();
    final total = list.itemIds.length;
    final bought = list.boughtItemIds.length;

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('$bought de $total comprados', style: context.text.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : bought / total,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                SwitchListTile(
                  value: _hideBought,
                  onChanged: (v) => setState(() => _hideBought = v),
                  title: const Text('Ocultar itens comprados'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (usedCategories.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final c in usedCategories)
                  FilterChip(
                    label: Text(c.name),
                    selected: _filterCategoryIds.contains(c.id),
                    onSelected: (selected) => setState(() {
                      selected ? _filterCategoryIds.add(c.id) : _filterCategoryIds.remove(c.id);
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            const EmptyState(icon: Icons.done_all, title: 'Nenhum item para exibir.')
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, item) in entries.indexed) ...[
                    if (i > 0) const Divider(),
                    _buildItem(list, item, data.categoryNames),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(
    ShoppingPurchaseList list,
    ShoppingItem item,
    Map<String, String> categoryNames,
  ) {
    final bought = list.boughtItemIds.contains(item.id);
    return CheckboxListTile(
      value: bought,
      title: Text(
        item.description,
        style: bought
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: context.colors.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: Text(categoryNames[item.categoryId] ?? 'Sem categoria'),
      onChanged: (v) => _toggle(list, item.id, v ?? false),
    );
  }
}
