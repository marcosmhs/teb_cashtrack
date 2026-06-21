import 'package:flutter/material.dart';
import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../controllers/shopping_purchase_list_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_purchase_list.dart';

class ShoppingPurchaseListCreateView extends StatefulWidget {
  const ShoppingPurchaseListCreateView({super.key, this.purchaseList});

  final ShoppingPurchaseList? purchaseList;

  @override
  State<ShoppingPurchaseListCreateView> createState() => _ShoppingPurchaseListCreateViewState();
}

class _ShoppingPurchaseListCreateViewState extends State<ShoppingPurchaseListCreateView> {
  final ShoppingCategoryController _categoryController = ShoppingCategoryController();
  final ShoppingItemController _itemController = ShoppingItemController();
  final ShoppingPurchaseListController _purchaseListController = ShoppingPurchaseListController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  final Set<String> _selectedItemIds = {};
  final Set<String> _boughtItemIds = {};

  @override
  void initState() {
    super.initState();
    final purchaseList = widget.purchaseList;
    if (purchaseList != null) {
      _selectedDate = purchaseList.date;
      _selectedCategoryId = null;
      _selectedItemIds.addAll(purchaseList.itemIds);
      _boughtItemIds.addAll(purchaseList.boughtItemIds);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveList() async {
    if (_selectedItemIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione ao menos um item.')));
      return;
    }

    final purchaseList = ShoppingPurchaseList(
      id: widget.purchaseList?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      itemIds: _selectedItemIds.toList(),
      boughtItemIds: _boughtItemIds.where((id) => _selectedItemIds.contains(id)).toList(),
    );

    if (widget.purchaseList != null) {
      await _purchaseListController.updatePurchaseList(purchaseList);
    } else {
      await _purchaseListController.addPurchaseList(purchaseList);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.purchaseList != null ? 'Lista de compras atualizada.' : 'Lista de compras criada.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.purchaseList != null ? 'Editar lista de compras' : 'Nova lista de compras',
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data da lista',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('${_selectedDate.toLocal()}'.split(' ')[0]),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ShoppingCategory>>(
              stream: _categoryController.getCategories(),
              builder: (context, filterSnapshot) {
                final categories = filterSnapshot.data ?? [];
                return DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por categoria',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas as categorias')),
                    ...categories.map(
                      (category) =>
                          DropdownMenuItem(value: category.id, child: Text(category.name)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecione itens cadastrados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<ShoppingCategory>>(
                stream: _categoryController.getCategories(),
                builder: (context, categorySnapshot) {
                  final categories = categorySnapshot.data ?? [];
                  final categoryMap = {
                    for (final category in categories) category.id: category.name,
                  };
                  return StreamBuilder<List<ShoppingItem>>(
                    stream: _itemController.getItems(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhum item cadastrado. Cadastre itens antes de criar uma lista.',
                          ),
                        );
                      }
                      final filteredItems = _selectedCategoryId == null
                          ? items
                          : items.where((item) => item.categoryId == _selectedCategoryId).toList();
                      if (filteredItems.isEmpty) {
                        return Center(
                          child: Text(
                            _selectedCategoryId == null
                                ? 'Nenhum item encontrado.'
                                : 'Nenhum item encontrado para essa categoria.',
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final selected = _selectedItemIds.contains(item.id);
                          return CheckboxListTile(
                            value: selected,
                            title: Text(item.description),
                            subtitle: Text(categoryMap[item.categoryId] ?? 'Sem categoria'),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItemIds.add(item.id);
                                } else {
                                  _selectedItemIds.remove(item.id);
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _saveList, child: const Text('Salvar lista')),
          ],
        ),
      ),
    );
  }
}
