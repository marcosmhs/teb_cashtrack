import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../controllers/shopping_purchase_list_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_purchase_list.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

/// Cria ou edita uma lista de compras escolhendo itens do cadastro.
class ShoppingPurchaseListCreateView extends StatefulWidget {
  const ShoppingPurchaseListCreateView({super.key, this.purchaseList});

  final ShoppingPurchaseList? purchaseList;

  @override
  State<ShoppingPurchaseListCreateView> createState() => _ShoppingPurchaseListCreateViewState();
}

class _ShoppingPurchaseListCreateViewState extends State<ShoppingPurchaseListCreateView> {
  final _listController = ShoppingPurchaseListController();
  late final Stream<(List<ShoppingCategory>, List<ShoppingItem>)> _data = Rx.combineLatest2(
    ShoppingCategoryController().getCategories(),
    ShoppingItemController().getItems(),
    (List<ShoppingCategory> c, List<ShoppingItem> i) => (c, i),
  );

  late DateTime _date = widget.purchaseList?.date ?? DateTime.now();
  late final Set<String> _selectedIds = {...?widget.purchaseList?.itemIds};
  String? _categoryId;
  bool _saving = false;

  bool get _isEditing => widget.purchaseList != null;

  Future<void> _save() async {
    if (_selectedIds.isEmpty) {
      showMessage(context, 'Selecione ao menos um item.');
      return;
    }
    setState(() => _saving = true);
    final list = ShoppingPurchaseList(
      id: widget.purchaseList?.id ?? _listController.newId(),
      date: _date,
      itemIds: _selectedIds.toList(),
      boughtItemIds: (widget.purchaseList?.boughtItemIds ?? [])
          .where(_selectedIds.contains)
          .toList(),
    );
    try {
      await _listController.savePurchaseList(list);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, _isEditing ? 'Lista atualizada.' : 'Lista criada.');
    } catch (e) {
      debugPrint('Erro ao salvar lista: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, 'Não foi possível salvar a lista.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar lista' : 'Nova lista de compras')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ResponsiveBody(
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text('Salvar lista (${_selectedIds.length} itens)'),
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final data = snapshot.data;
          if (data == null) return const LoadingView();
          final (categories, items) = data;
          final categoryNames = {for (final c in categories) c.id: c.name};
          final visible = _categoryId == null
              ? items
              : items.where((i) => i.categoryId == _categoryId).toList();
          final allVisibleSelected =
              visible.isNotEmpty && visible.every((i) => _selectedIds.contains(i.id));

          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                DateField(
                  label: 'Data da lista',
                  value: _date,
                  onChanged: (d) => setState(() => _date = d),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: const Text('Todas'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(c.name),
                        selected: _categoryId == c.id,
                        onSelected: (s) => setState(() => _categoryId = s ? c.id : null),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Nenhum item cadastrado.',
                    message: 'Cadastre itens na aba Itens antes de montar uma lista.',
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: allVisibleSelected,
                          title: Text(
                            'Selecionar todos (${visible.length})',
                            style: context.text.titleMedium,
                          ),
                          onChanged: (v) => setState(() {
                            final ids = visible.map((i) => i.id);
                            v == true ? _selectedIds.addAll(ids) : _selectedIds.removeAll(ids);
                          }),
                        ),
                        for (final item in visible) ...[
                          const Divider(),
                          CheckboxListTile(
                            value: _selectedIds.contains(item.id),
                            title: Text(item.description),
                            subtitle: Text(categoryNames[item.categoryId] ?? 'Sem categoria'),
                            onChanged: (v) => setState(() {
                              v == true ? _selectedIds.add(item.id) : _selectedIds.remove(item.id);
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
