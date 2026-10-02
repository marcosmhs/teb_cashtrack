import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'shopping_category_list_view.dart';
import 'shopping_purchase_list_view.dart';

/// Aba "Compras": cadastro de itens recorrentes e listas de compras.
class ShoppingListView extends StatelessWidget {
  const ShoppingListView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compras'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShoppingCategoryListView())),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Categorias'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Listas'),
              Tab(text: 'Itens'),
            ],
          ),
        ),
        body: const TabBarView(children: [ShoppingPurchaseListsTab(), _ShoppingItemsTab()]),
      ),
    );
  }
}

class _ShoppingItemsTab extends StatefulWidget {
  const _ShoppingItemsTab();

  @override
  State<_ShoppingItemsTab> createState() => _ShoppingItemsTabState();
}

class _ShoppingItemsTabState extends State<_ShoppingItemsTab> with AutomaticKeepAliveClientMixin {
  final _itemController = ShoppingItemController();
  final _descriptionController = TextEditingController();
  late final Stream<(List<ShoppingCategory>, List<ShoppingItem>)> _data = Rx.combineLatest2(
    ShoppingCategoryController().getCategories(),
    _itemController.getItems(),
    (List<ShoppingCategory> c, List<ShoppingItem> i) => (c, i),
  );

  /// Categoria do novo item (independente do filtro da lista).
  String? _newItemCategoryId;
  final Set<String> _filterCategoryIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final description = _descriptionController.text.trim();
    if (_newItemCategoryId == null || description.isEmpty) {
      showMessage(context, 'Escolha a categoria e digite a descrição do item.');
      return;
    }
    try {
      await _itemController.saveItem(
        ShoppingItem(
          id: _itemController.newId(),
          categoryId: _newItemCategoryId!,
          description: description,
        ),
      );
      _descriptionController.clear();
    } catch (e) {
      debugPrint('Erro ao adicionar item: $e');
      if (mounted) showMessage(context, 'Não foi possível adicionar o item.');
    }
  }

  Future<void> _editItem(ShoppingItem item) async {
    final description = await promptText(
      context,
      title: 'Editar item',
      label: 'Descrição',
      initialValue: item.description,
    );
    if (description == null) return;
    await _itemController.saveItem(
      ShoppingItem(
        id: item.id,
        categoryId: item.categoryId,
        description: description,
        createdAt: item.createdAt,
      ),
    );
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final confirmed = await confirmAction(
      context,
      title: 'Excluir item?',
      message: 'Excluir "${item.description}"? Ele também deixará de aparecer nas listas.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (confirmed) await _itemController.deleteItem(item.id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      stream: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error);
        final data = snapshot.data;
        if (data == null) return const LoadingView();
        final (categories, allItems) = data;

        if (categories.isEmpty) {
          return EmptyState(
            icon: Icons.category_outlined,
            title: 'Cadastre categorias primeiro.',
            message: 'Ex.: Hortifruti, Limpeza, Padaria.',
            action: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShoppingCategoryListView())),
              child: const Text('Gerenciar categorias'),
            ),
          );
        }

        final categoryNames = {for (final c in categories) c.id: c.name};
        _filterCategoryIds.removeWhere((id) => !categoryNames.containsKey(id));
        if (!categoryNames.containsKey(_newItemCategoryId)) _newItemCategoryId = null;
        final items = _filterCategoryIds.isEmpty
            ? allItems
            : allItems.where((i) => _filterCategoryIds.contains(i.categoryId)).toList();

        return ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Novo item', style: context.text.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _newItemCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _newItemCategoryId = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _addItem(),
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle),
                          tooltip: 'Adicionar item',
                          color: context.colors.primary,
                          onPressed: _addItem,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  FilterChip(
                    label: const Text('Todas'),
                    selected: _filterCategoryIds.isEmpty,
                    onSelected: (_) => setState(_filterCategoryIds.clear),
                  ),
                  for (final c in categories)
                    FilterChip(
                      label: Text(c.name),
                      selected: _filterCategoryIds.contains(c.id),
                      onSelected: (selected) => setState(() {
                        selected ? _filterCategoryIds.add(c.id) : _filterCategoryIds.remove(c.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: allItems.isEmpty
                      ? 'Nenhum item cadastrado ainda.'
                      : 'Nenhum item nas categorias selecionadas.',
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, item) in items.indexed) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          title: Text(item.description),
                          subtitle: Text(categoryNames[item.categoryId] ?? 'Sem categoria'),
                          onTap: () => _editItem(item),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: context.colors.error),
                            tooltip: 'Excluir ${item.description}',
                            onPressed: () => _deleteItem(item),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
