import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

/// Superfície branca com borda sutil e sombra difusa (ver DESIGN.md).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: context.finance.cardBorder),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Limita a largura do conteúdo em telas grandes e centraliza.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // Altura igual à do filho: sem isso, em áreas com altura livre (ex.: barra
      // inferior do Scaffold) o Align ocupa toda a tela e esconde o corpo.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: context.colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, textAlign: TextAlign.center, style: context.text.titleMedium),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: CircularProgressIndicator()),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    debugPrint('Erro ao carregar dados: $error');
    return const EmptyState(
      icon: Icons.cloud_off,
      title: 'Não foi possível carregar os dados.',
      message: 'Verifique sua conexão e tente novamente.',
    );
  }
}

/// Valor monetário colorido conforme o sinal.
class AmountText extends StatelessWidget {
  const AmountText(this.cents, {super.key, this.signed = false, this.style, this.colored = true});

  final int cents;
  final bool signed;
  final bool colored;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.text.titleMedium;
    return Text(
      signed ? formatSignedCents(cents) : formatCents(cents),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base?.copyWith(
        color: colored ? context.finance.forSign(cents) : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.labelSmall?.copyWith(color: context.colors.onSecondaryContainer),
      ),
    );
  }
}

/// Campo que abre o seletor de data. Com [onCleared], exibe botão para limpar.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
    this.emptyText = 'Selecionar',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onCleared;
  final String emptyText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          suffixIcon: value != null && onCleared != null
              ? IconButton(icon: const Icon(Icons.close), tooltip: 'Limpar', onPressed: onCleared)
              : null,
        ),
        child: Text(value != null ? formatDate(value!) : emptyText, maxLines: 1),
      ),
    );
  }
}

/// Título de seção com ação opcional à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleMedium)),
        ?trailing,
      ],
    );
  }
}
