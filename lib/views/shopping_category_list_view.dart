import 'package:flutter/material.dart';

import '../controllers/shopping_category_controller.dart';
import '../models/shopping_category.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class ShoppingCategoryListView extends StatefulWidget {
  const ShoppingCategoryListView({super.key});

  @override
  State<ShoppingCategoryListView> createState() => _ShoppingCategoryListViewState();
}

class _ShoppingCategoryListViewState extends State<ShoppingCategoryListView> {
  final _controller = ShoppingCategoryController();
  late final Stream<List<ShoppingCategory>> _categories = _controller.getCategories();

  Future<void> _edit([ShoppingCategory? category]) async {
    final name = await promptText(
      context,
      title: category == null ? 'Nova categoria' : 'Editar categoria',
      label: 'Nome',
      initialValue: category?.name ?? '',
    );
    if (name == null) return;
    try {
      await _controller.saveCategory(
        ShoppingCategory(id: category?.id ?? _controller.newId(), name: name),
      );
    } catch (e) {
      debugPrint('Erro ao salvar categoria: $e');
      if (mounted) showMessage(context, 'Não foi possível salvar a categoria.');
    }
  }

  Future<void> _delete(ShoppingCategory category) async {
    // Impede excluir categorias em uso, para não deixar itens órfãos.
    final count = await _controller.countItems(category.id);
    if (!mounted) return;
    if (count > 0) {
      showMessage(
        context,
        '"${category.name}" possui $count item(ns). Mova ou exclua os itens antes de excluir a categoria.',
      );
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Excluir categoria?',
      message: 'Excluir "${category.name}"?',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (confirmed) await _controller.deleteCategory(category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias de compras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Nova categoria'),
      ),
      body: StreamBuilder<List<ShoppingCategory>>(
        stream: _categories,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final categories = snapshot.data;
          if (categories == null) return const LoadingView();
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria cadastrada.',
              message: 'Ex.: Hortifruti, Limpeza, Padaria.',
            );
          }
          return ResponsiveBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (final (i, category) in categories.indexed) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          title: Text(category.name),
                          onTap: () => _edit(category),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: context.colors.error),
                            tooltip: 'Excluir ${category.name}',
                            onPressed: () => _delete(category),
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
      ),
    );
  }
}
