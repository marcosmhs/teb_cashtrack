import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/dialogs.dart';

/// Páginas públicas do app, servidas pelo Firebase Hosting a partir de `web/`.
/// Os mesmos endereços são informados no Google Play Console.
class AppLinks {
  const AppLinks._();

  static final privacyPolicy = Uri.parse('https://teb-cashtrack.web.app/privacidade.html');
  static final accountDeletion = Uri.parse('https://teb-cashtrack.web.app/excluir-conta.html');
}

/// Abre o endereço no navegador.
Future<void> openLink(BuildContext context, Uri url) async {
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) showMessage(context, 'Não foi possível abrir $url');
}
