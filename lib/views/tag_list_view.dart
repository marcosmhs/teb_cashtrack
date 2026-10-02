import 'package:flutter/material.dart';

import '../controllers/tag_controller.dart';
import '../models/tag.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class TagListView extends StatefulWidget {
  const TagListView({super.key});

  @override
  State<TagListView> createState() => _TagListViewState();
}

class _TagListViewState extends State<TagListView> {
  final _tagController = TagController();
  late final Stream<List<Tag>> _tags = _tagController.getTags();

  Future<void> _edit([Tag? tag]) async {
    final name = await promptText(
      context,
      title: tag == null ? 'Nova tag' : 'Editar tag',
      label: 'Nome',
      initialValue: tag?.name ?? '',
    );
    if (name == null) return;
    try {
      await _tagController.saveTag(Tag(id: tag?.id ?? _tagController.newId(), name: name));
    } catch (e) {
      debugPrint('Erro ao salvar tag: $e');
      if (mounted) showMessage(context, 'Não foi possível salvar a tag.');
    }
  }

  Future<void> _delete(Tag tag) async {
    final confirmed = await confirmAction(
      context,
      title: 'Excluir tag?',
      message: 'A tag "${tag.name}" será removida dos lançamentos que a utilizam.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await _tagController.deleteTag(tag.id);
      if (mounted) showMessage(context, 'Tag excluída.');
    } catch (e) {
      debugPrint('Erro ao excluir tag: $e');
      if (mounted) showMessage(context, 'Não foi possível excluir a tag.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Nova tag'),
      ),
      body: StreamBuilder<List<Tag>>(
        stream: _tags,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error);
          final tags = snapshot.data;
          if (tags == null) return const LoadingView();
          if (tags.isEmpty) {
            return const EmptyState(
              icon: Icons.label_outline,
              title: 'Nenhuma tag cadastrada.',
              message: 'Tags ajudam a agrupar lançamentos, como "Mercado" ou "Transporte".',
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
                      for (final (i, tag) in tags.indexed) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(tag.name),
                          onTap: () => _edit(tag),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline, color: context.colors.error),
                            tooltip: 'Excluir ${tag.name}',
                            onPressed: () => _delete(tag),
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
