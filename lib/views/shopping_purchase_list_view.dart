import 'package:flutter/material.dart';
import 'package:teb_cashtrack/views/shopping_purchase_list_create_view.dart';
import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../controllers/shopping_purchase_list_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_purchase_list.dart';

class ShoppingPurchaseListView extends StatefulWidget {
  const ShoppingPurchaseListView({super.key});

  @override
  State<ShoppingPurchaseListView> createState() => _ShoppingPurchaseListViewState();
}

class _ShoppingPurchaseListViewState extends State<ShoppingPurchaseListView> {
  final ShoppingPurchaseListController _purchaseListController = ShoppingPurchaseListController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas de compras'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: StreamBuilder<List<ShoppingPurchaseList>>(
          stream: _purchaseListController.getPurchaseLists(),
          builder: (context, snapshot) {
            final lists = snapshot.data ?? [];
            if (lists.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma lista de compras cadastrada ainda.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              itemCount: lists.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final list = lists[index];
                final boughtCount = list.boughtItemIds.length;
                final totalCount = list.itemIds.length;
                final dateLabel = '${list.date.toLocal()}'.split(' ')[0];
                return ListTile(
                  title: Text('Lista de $dateLabel'),
                  subtitle: Text('$boughtCount de $totalCount itens comprados'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        boughtCount == totalCount ? Icons.check_circle : Icons.shopping_cart,
                        color: boughtCount == totalCount
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ShoppingPurchaseListCreateView(purchaseList: list),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShoppingPurchaseListDetailView(purchaseList: list),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ShoppingPurchaseListDetailView extends StatefulWidget {
  final ShoppingPurchaseList purchaseList;

  const ShoppingPurchaseListDetailView({super.key, required this.purchaseList});

  @override
  State<ShoppingPurchaseListDetailView> createState() => _ShoppingPurchaseListDetailViewState();
}

class _ShoppingPurchaseListDetailViewState extends State<ShoppingPurchaseListDetailView> {
  final ShoppingItemController _itemController = ShoppingItemController();
  final ShoppingCategoryController _categoryController = ShoppingCategoryController();
  final ShoppingPurchaseListController _purchaseListController = ShoppingPurchaseListController();
  late ShoppingPurchaseList _purchaseList;
  final Set<String> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    _purchaseList = widget.purchaseList;
  }

  Future<void> _toggleBought(String itemId, bool bought) async {
    setState(() {
      if (bought) {
        _purchaseList.boughtItemIds.add(itemId);
      } else {
        _purchaseList.boughtItemIds.remove(itemId);
      }
    });
    await _purchaseListController.updatePurchaseList(_purchaseList);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_purchaseList.date.toLocal()}'.split(' ')[0];
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de $dateLabel'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Itens da lista',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              '${_purchaseList.boughtItemIds.length} de ${_purchaseList.itemIds.length} comprados',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            Text('Filtrar por categoria', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            StreamBuilder<List<ShoppingCategory>>(
              stream: _categoryController.getCategories(),
              builder: (context, categorySnapshot) {
                final categories = categorySnapshot.data ?? [];
                if (categories.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Wrap(
                  spacing: 8,
                  children: [
                    ...categories.map((category) {
                      final isSelected = _selectedCategoryIds.contains(category.id);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(category.name),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
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
                    builder: (context, itemSnapshot) {
                      final items = itemSnapshot.data ?? [];
                      var purchaseItems = _purchaseList.itemIds
                          .map(
                            (id) => items.firstWhere(
                              (item) => item.id == id,
                              orElse: () => ShoppingItem(
                                id: id,
                                categoryId: '',
                                description: 'Item removido ou não encontrado',
                              ),
                            ),
                          )
                          .toList();

                      if (_selectedCategoryIds.isNotEmpty) {
                        purchaseItems = purchaseItems
                            .where((item) => _selectedCategoryIds.contains(item.categoryId))
                            .toList();
                      }

                      purchaseItems.sort(
                        (a, b) =>
                            a.description.toLowerCase().compareTo(b.description.toLowerCase()),
                      );
                      if (purchaseItems.isEmpty) {
                        return const Center(
                          child: Text('Nenhum item encontrado nesta lista de compras.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: purchaseItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final item = purchaseItems[index];
                          final bought = _purchaseList.boughtItemIds.contains(item.id);
                          return CheckboxListTile(
                            value: bought,
                            title: Text(item.description),
                            subtitle: Text(categoryMap[item.categoryId] ?? 'Sem categoria'),
                            onChanged: (value) {
                              if (value != null) {
                                _toggleBought(item.id, value);
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
