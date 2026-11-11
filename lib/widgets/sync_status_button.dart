import 'package:flutter/material.dart';

import '../services/sync_status.dart';
import '../theme.dart';
import 'dialogs.dart';

/// Ícone da barra superior que aparece quando os dados do aparelho ainda não
/// estão sincronizados com a nuvem (sem conexão ou enviando alterações).
/// Tocar exibe a explicação do estado.
class SyncStatusButton extends StatefulWidget {
  const SyncStatusButton({super.key});

  @override
  State<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends State<SyncStatusButton> {
  late final Stream<SyncState> _state = SyncStatusService().watch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncState>(
      stream: _state,
      builder: (context, snapshot) {
        final state = snapshot.data;
        // Sincronizado é o normal: some para não ocupar espaço na barra.
        if (state == null || state == SyncState.synced) return const SizedBox.shrink();
        final (icon, color) = switch (state) {
          SyncState.synced => (Icons.cloud_done_outlined, context.colors.onSurfaceVariant),
          SyncState.syncing => (Icons.cloud_upload_outlined, context.colors.primary),
          SyncState.offline => (Icons.cloud_off_outlined, context.colors.onSurfaceVariant),
          SyncState.offlinePending => (Icons.cloud_off_outlined, context.colors.error),
        };
        return IconButton(
          icon: Icon(icon, color: color),
          tooltip: state.description,
          onPressed: () => showMessage(context, state.description),
        );
      },
    );
  }
}
