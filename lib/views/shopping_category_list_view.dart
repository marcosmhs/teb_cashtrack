// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../controllers/shopping_category_controller.dart';
import '../models/shopping_category.dart';

class ShoppingCategoryListView extends StatefulWidget {
  final bool forSelection;
  const ShoppingCategoryListView({super.key, this.forSelection = false});

  @override
  State<ShoppingCategoryListView> createState() => _ShoppingCategoryListViewState();
}

class _ShoppingCategoryListViewState extends State<ShoppingCategoryListView> {
  final ShoppingCategoryController _categoryController = ShoppingCategoryController();

  Future<void> _showAddEditDialog({ShoppingCategory? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final isEdit = category != null;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar categoria' : 'Nova categoria'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (isEdit) {
                await _categoryController.updateCategory(
                  ShoppingCategory(id: category.id, name: name),
                );
              } else {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                await _categoryController.addCategory(ShoppingCategory(id: id, name: name));
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (res == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forSelection ? 'Selecione uma categoria' : 'Categorias de compras'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ShoppingCategory>>(
        stream: _categoryController.getCategories(),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                widget.forSelection
                    ? 'Nenhuma categoria disponível.'
                    : 'Nenhuma categoria cadastrada ainda.',
              ),
            );
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                onTap: () {
                  if (widget.forSelection) {
                    Navigator.of(context).pop(category);
                  } else {
                    _showAddEditDialog(category: category);
                  }
                },
                trailing: widget.forSelection
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Excluir categoria?'),
                              content: Text(
                                'Excluir "${category.name}"? Esta ação não pode ser desfeita.',
                              ),
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
                            await _categoryController.deleteCategory(category.id);
                          }
                        },
                      ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.forSelection
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddEditDialog(),
              child: const Icon(Icons.add),
            ),
    );
  }
}
