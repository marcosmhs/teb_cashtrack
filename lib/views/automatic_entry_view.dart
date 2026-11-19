import 'package:flutter/material.dart';

import '../controllers/import_settings_controller.dart';
import '../controllers/pluggy_controller.dart';
import '../models/import_settings.dart';
import '../models/pluggy.dart';
import '../services/notification_capture_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'notification_settings_view.dart';
import 'pluggy_view.dart';

/// Escolha de como os lançamentos chegam sozinhos: manual, notificações ou Pluggy.
class AutomaticEntryView extends StatefulWidget {
  const AutomaticEntryView({super.key});

  @override
  State<AutomaticEntryView> createState() => _AutomaticEntryViewState();
}

class _AutomaticEntryViewState extends State<AutomaticEntryView> {
  final _settings = ImportSettingsController();
  late final Stream<ImportMode> _mode = _settings.watchMode();
  late final Stream<PluggyStatus?> _pluggy = PluggyController().watchStatus();

  void _open(Widget view) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => view));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento automático')),
      body: StreamBuilder<ImportMode>(
        stream: _mode,
        builder: (context, modeSnapshot) {
          final mode = modeSnapshot.data;
          if (mode == null) return const LoadingView();
          return StreamBuilder<PluggyStatus?>(
            stream: _pluggy,
            builder: (context, pluggySnapshot) {
              final pluggyAvailable = pluggySnapshot.data != null;
              final options = [
                ImportMode.manual,
                if (NotificationCaptureService.isSupported || mode == ImportMode.notifications)
                  ImportMode.notifications,
                if (pluggyAvailable || mode == ImportMode.pluggy) ImportMode.pluggy,
              ];
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  ResponsiveBody(
                    maxWidth: 640,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Escolha uma forma de os lançamentos chegarem sem digitar. '
                          'Vale para todos os seus aparelhos.',
                          style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final (i, option) in options.indexed) ...[
                                if (i > 0) const Divider(),
                                RadioListTile<ImportMode>(
                                  value: option,
                                  groupValue: mode,
                                  onChanged: (m) {
                                    if (m != null) _settings.setMode(m);
                                  },
                                  title: Text(option.label),
                                  subtitle: Text(option.description),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (mode == ImportMode.notifications &&
                            NotificationCaptureService.isSupported)
                          FilledButton.tonalIcon(
                            onPressed: () => _open(const NotificationSettingsView()),
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: const Text('Configurar notificações'),
                          ),
                        if (mode == ImportMode.pluggy || pluggyAvailable)
                          FilledButton.tonalIcon(
                            onPressed: () => _open(const PluggyView()),
                            icon: const Icon(Icons.account_balance_outlined),
                            label: const Text('Contas do banco (Pluggy)'),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
