// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../controllers/tag_controller.dart';
import '../models/tag.dart';

class TagListView extends StatefulWidget {
  final bool forSelection;
  const TagListView({super.key, this.forSelection = false});

  @override
  State<TagListView> createState() => _TagListViewState();
}

class _TagListViewState extends State<TagListView> {
  final TagController _tagController = TagController();

  Future<void> _showAddEditDialog({Tag? tag}) async {
    final controller = TextEditingController(text: tag?.name ?? '');
    final isEdit = tag != null;
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Editar tag' : 'Nova tag'),
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
                await _tagController.updateTag(Tag(id: tag.id, name: name));
              } else {
                final id = DateTime.now().millisecondsSinceEpoch.toString();
                await _tagController.addTag(Tag(id: id, name: name));
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
        title: Text(widget.forSelection ? 'Selecione uma tag' : 'Tags'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Tag>>(
        stream: _tagController.getTags(),
        builder: (context, snapshot) {
          final tags = snapshot.data ?? [];
          if (tags.isEmpty) {
            return Center(
              child: Text(
                widget.forSelection ? 'Nenhuma tag disponível.' : 'Nenhuma tag cadastrada.',
              ),
            );
          }
          return ListView.separated(
            itemCount: tags.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final tag = tags[i];
              return ListTile(
                title: Text(tag.name),
                onTap: () {
                  if (widget.forSelection) {
                    Navigator.of(context).pop(tag);
                  } else {
                    _showAddEditDialog(tag: tag);
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
                              title: const Text('Excluir tag?'),
                              content: Text(
                                'Excluir "${tag.name}"? Esta ação não pode ser desfeita.',
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
                          if (ok == true) await _tagController.deleteTag(tag.id);
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
