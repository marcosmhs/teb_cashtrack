import 'package:flutter/material.dart';
import '../controllers/shopping_category_controller.dart';
import '../controllers/shopping_item_controller.dart';
import '../models/shopping_category.dart';
import '../models/shopping_item.dart';
import 'shopping_category_list_view.dart';
import 'shopping_purchase_list_create_view.dart';
import 'shopping_purchase_list_view.dart';

class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key});

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  final ShoppingCategoryController _categoryController = ShoppingCategoryController();
  final ShoppingItemController _itemController = ShoppingItemController();
  final TextEditingController _descriptionController = TextEditingController();
  ShoppingCategory? _selectedCategory;
  Set<String> _selectedCategoryIds = {};

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showFilterDialog(List<ShoppingCategory> categories) async {
    final selected = Set<String>.from(_selectedCategoryIds);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar por categorias'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (categories.isEmpty)
                      const Text('Nenhuma categoria disponível.')
                    else
                      ...categories.map((category) {
                        return CheckboxListTile(
                          value: selected.contains(category.id),
                          onChanged: (isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                selected.add(category.id);
                              } else {
                                selected.remove(category.id);
                              }
                            });
                          },
                          title: Text(category.name),
                        );
                      }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(<String>{}),
                  child: const Text('Limpar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedCategoryIds = result);
    }
  }

  Future<void> _addItem() async {
    final description = _descriptionController.text.trim();
    if (_selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma categoria primeiro.')));
      return;
    }
    if (description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Digite a descrição do item.')));
      return;
    }

    final item = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: _selectedCategory!.id,
      description: description,
    );

    await _itemController.addItem(item);
    _descriptionController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item adicionado à lista de compras.')));
  }

  Future<void> _deleteItem(String id) async {
    await _itemController.deleteItem(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras Mensal'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonal(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShoppingCategoryListView())),
              child: const Text('Gerenciar categorias'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShoppingPurchaseListCreateView())),
              child: const Text('Criar nova lista de compras'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShoppingPurchaseListView())),
              child: const Text('Ver listas de compras'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<ShoppingCategory>>(
                stream: _categoryController.getCategories(),
                builder: (context, categorySnapshot) {
                  final categories = categorySnapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<ShoppingCategory>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: categories
                            .map(
                              (category) =>
                                  DropdownMenuItem(value: category, child: Text(category.name)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCategory = value),
                        hint: const Text('Selecione uma categoria'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () => _showFilterDialog(categories),
                              child: Text(
                                _selectedCategoryIds.isEmpty
                                    ? 'Filtrar por categorias'
                                    : 'Filtro: ${_selectedCategoryIds.length} categoria(s)',
                              ),
                            ),
                          ),
                          if (_selectedCategoryIds.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _selectedCategoryIds.clear()),
                              tooltip: 'Limpar filtro',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Descrição do item',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: categories.isEmpty ? null : _addItem,
                          child: const Text('Adicionar item'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: StreamBuilder<List<ShoppingItem>>(
                          stream: _itemController.getItems(),
                          builder: (context, itemSnapshot) {
                            var items = itemSnapshot.data ?? [];
                            if (_selectedCategory != null) {
                              items = items
                                  .where((item) => item.categoryId == _selectedCategory!.id)
                                  .toList();
                            }
                            if (_selectedCategoryIds.isNotEmpty) {
                              items = items
                                  .where((item) => _selectedCategoryIds.contains(item.categoryId))
                                  .toList();
                            }
                            if (items.isEmpty) {
                              return Center(
                                child: Text(
                                  categories.isEmpty
                                      ? 'Cadastre categorias para começar a montar a lista.'
                                      : _selectedCategory == null && _selectedCategoryIds.isEmpty
                                      ? 'Nenhum item adicionado ainda.'
                                      : 'Nenhum item encontrado para os filtros selecionados.',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }
                            final categoryMap = {
                              for (final category in categories) category.id: category.name,
                            };
                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 0),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final categoryName =
                                    categoryMap[item.categoryId] ?? 'Sem categoria';
                                return ListTile(
                                  title: Text(item.description),
                                  subtitle: Text(categoryName),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Remover item?'),
                                          content: Text('Excluir "${item.description}" da lista?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text('Excluir'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await _deleteItem(item.id);
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
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
