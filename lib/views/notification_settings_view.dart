import 'package:flutter/material.dart';

import '../controllers/notification_capture_controller.dart';
import '../models/notification_capture.dart';
import '../models/transaction.dart';
import '../services/notification_capture_service.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import '../widgets/transaction_form.dart';

/// Configuração do lançamento automático a partir de notificações de pagamento (Android).
class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView>
    with WidgetsBindingObserver {
  final _service = NotificationCaptureService();
  final _captureController = NotificationCaptureController();
  late final Stream<List<NotificationCapture>> _captures = _captureController.getCaptures();
  NotificationCaptureStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Atualiza ao voltar das configurações do Android (permissão concedida ou não).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final status = await _service.getStatus();
      if (mounted) setState(() => _status = status);
    } catch (e) {
      debugPrint('Erro ao obter status das notificações: $e');
    }
  }

  Future<void> _save({bool? enabled, bool? autoCreate, Set<String>? packages}) async {
    await _service.saveSettings(enabled: enabled, autoCreate: autoCreate, packages: packages);
    await _refresh();
  }

  Future<void> _togglePackage(String package, bool selected) {
    final packages = {..._status!.packages};
    selected ? packages.add(package) : packages.remove(package);
    return _save(packages: packages);
  }

  Future<void> _addCustomPackage() async {
    final package = await promptText(
      context,
      title: 'Monitorar outro app',
      label: 'Pacote do app (ex.: com.banco.app)',
      confirmLabel: 'Adicionar',
    );
    if (package == null || !package.contains('.')) return;
    await _togglePackage(package, true);
  }

  void _createFromCapture(NotificationCapture capture) {
    showTransactionForm(
      context,
      prefill: TransactionPrefill(
        amountCents: capture.amountCents,
        details: capture.merchant,
        date: capture.postedAt,
        type: capture.isRefund ? TransactionType.credit : TransactionType.debit,
      ),
      onSaved: (t) => _captureController.markCreatedManually(capture.id, t.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Lançamento automático')),
      body: status == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                ResponsiveBody(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPermissionCard(status),
                      const SizedBox(height: AppSpacing.md),
                      _buildOptionsCard(status),
                      const SizedBox(height: AppSpacing.md),
                      _buildAppsCard(status),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Notificações capturadas', style: context.text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      _buildCaptures(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionCard(NotificationCaptureStatus status) {
    final muted = context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'O CashTrack lê as notificações de pagamento dos apps escolhidos abaixo '
            '(como o Samsung Wallet) e cria o lançamento sozinho, mesmo com o app fechado.',
            style: muted,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusRow(
            ok: status.permissionGranted,
            okText: 'Acesso às notificações concedido',
            pendingText: 'Acesso às notificações pendente',
            actionLabel: 'Conceder',
            onAction: _service.openNotificationAccessSettings,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusRow(
            ok: status.ignoringBatteryOptimizations,
            okText: 'Sem restrição de bateria',
            pendingText: 'O Android pode pausar o serviço para economizar bateria',
            actionLabel: 'Liberar',
            onAction: _service.requestIgnoreBatteryOptimizations,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard(NotificationCaptureStatus status) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            value: status.enabled,
            onChanged: (v) => _save(enabled: v),
            title: const Text('Capturar notificações'),
            subtitle: const Text('Lê as notificações dos apps monitorados.'),
          ),
          const Divider(),
          SwitchListTile(
            value: status.autoCreate,
            onChanged: status.enabled ? (v) => _save(autoCreate: v) : null,
            title: const Text('Criar lançamentos automaticamente'),
            subtitle: const Text(
              'Desligado, as notificações ficam na lista abaixo para você lançar manualmente.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsCard(NotificationCaptureStatus status) {
    final custom = status.packages.where(
      (p) => !NotificationCaptureService.knownApps.any((a) => a.package == p),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apps monitorados', style: context.text.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Para cada cartão, preencha o "Identificador nas notificações" (ex.: final 1234) '
            'no cadastro da conta. Sem ele, o lançamento vai para o único cartão ativo ou '
            'para o meio de pagamento principal.',
            style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final app in NotificationCaptureService.knownApps)
                FilterChip(
                  label: Text(app.name),
                  selected: status.packages.contains(app.package),
                  onSelected: (v) => _togglePackage(app.package, v),
                ),
              for (final package in custom)
                InputChip(
                  label: Text(package),
                  selected: true,
                  onDeleted: () => _togglePackage(package, false),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Outro app'),
                onPressed: _addCustomPackage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptures() {
    return StreamBuilder<List<NotificationCapture>>(
      stream: _captures,
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorView(error: snapshot.error);
        final captures = snapshot.data;
        if (captures == null) return const LoadingView();
        if (captures.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'Nenhuma notificação capturada ainda.',
            message: 'Faça uma compra com o cartão e ela aparecerá aqui.',
          );
        }
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, c) in captures.indexed) ...[
                if (i > 0) const Divider(),
                _CaptureTile(
                  capture: c,
                  onCreate: c.hasTransaction || c.amountCents == null
                      ? null
                      : () => _createFromCapture(c),
                  onDelete: () => _captureController.delete(c.id),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.ok,
    required this.okText,
    required this.pendingText,
    required this.actionLabel,
    required this.onAction,
  });

  final bool ok;
  final String okText;
  final String pendingText;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.error_outline,
          color: ok ? context.finance.income : context.colors.error,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(ok ? okText : pendingText)),
        if (!ok) FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _CaptureTile extends StatelessWidget {
  const _CaptureTile({required this.capture, required this.onCreate, required this.onDelete});

  final NotificationCapture capture;
  final VoidCallback? onCreate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = capture;
    final muted = context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant);
    final raw = [c.title, c.text].whereType<String>().join(' — ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.merchant ?? NotificationCaptureService.appName(c.package),
                        style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (c.amountCents != null)
                      AmountText(
                        c.isRefund ? c.amountCents! : -c.amountCents!,
                        style: context.text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(c.postedAt)} · ${NotificationCaptureService.appName(c.package)}'
                  '${c.cardHint != null ? ' · final ${c.cardHint}' : ''}',
                  style: muted,
                ),
                const SizedBox(height: 4),
                Text(raw, style: muted, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagChip(c.statusLabel),
                    if (onCreate != null)
                      TextButton.icon(
                        onPressed: onCreate,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Lançar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Remover da lista',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
