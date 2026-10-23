import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Estado do lançamento automático por notificações (somente Android).
class NotificationCaptureStatus {
  const NotificationCaptureStatus({
    required this.permissionGranted,
    required this.ignoringBatteryOptimizations,
    required this.enabled,
    required this.autoCreate,
    required this.packages,
  });

  final bool permissionGranted;
  final bool ignoringBatteryOptimizations;
  final bool enabled;
  final bool autoCreate;
  final Set<String> packages;

  factory NotificationCaptureStatus.fromMap(Map<Object?, Object?> map) {
    return NotificationCaptureStatus(
      permissionGranted: map['permissionGranted'] as bool? ?? false,
      ignoringBatteryOptimizations: map['ignoringBatteryOptimizations'] as bool? ?? false,
      enabled: map['enabled'] as bool? ?? true,
      autoCreate: map['autoCreate'] as bool? ?? true,
      packages: {...(map['packages'] as List<Object?>? ?? []).whereType<String>()},
    );
  }
}

/// App que pode ser monitorado, com o nome exibido na tela.
typedef MonitoredApp = ({String package, String name});

/// Ponte com o serviço nativo de notificações (`MainActivity.kt`).
class NotificationCaptureService {
  static const _channel = MethodChannel('br.com.thatexoticbug.cashtrack/notifications');

  static const samsungWallet = 'com.samsung.android.spay';

  /// Apps sugeridos na tela de configuração. Outros podem ser adicionados pelo pacote.
  static const knownApps = <MonitoredApp>[
    (package: samsungWallet, name: 'Samsung Wallet'),
    (package: 'com.nu.production', name: 'Nubank'),
    (package: 'com.itau', name: 'Itaú'),
    (package: 'br.com.intermedium', name: 'Inter'),
    (package: 'com.c6bank.app', name: 'C6 Bank'),
    (package: 'br.com.bb.android', name: 'Banco do Brasil'),
    (package: 'com.bradesco', name: 'Bradesco'),
    (package: 'com.santander.app', name: 'Santander'),
    (package: 'br.com.gabba.Caixa', name: 'Caixa'),
    (package: 'com.mercadopago.wallet', name: 'Mercado Pago'),
    (package: 'com.picpay', name: 'PicPay'),
  ];

  static String appName(String package) {
    for (final app in knownApps) {
      if (app.package == package) return app.name;
    }
    return package;
  }

  /// O recurso existe apenas no app Android (não na versão web).
  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<NotificationCaptureStatus> getStatus() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('getStatus');
    return NotificationCaptureStatus.fromMap(map ?? const {});
  }

  Future<void> saveSettings({bool? enabled, bool? autoCreate, Set<String>? packages}) {
    return _channel.invokeMethod('saveSettings', {
      'enabled': ?enabled,
      'autoCreate': ?autoCreate,
      if (packages != null) 'packages': packages.toList(),
    });
  }

  Future<void> openNotificationAccessSettings() =>
      _channel.invokeMethod('openNotificationAccessSettings');

  Future<void> requestIgnoreBatteryOptimizations() =>
      _channel.invokeMethod('requestIgnoreBatteryOptimizations');
}
