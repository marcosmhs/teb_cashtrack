# 🎯 Referência Rápida - Comandos de Build e Deploy

## 🚀 Começar Agora

```powershell
# Opção 1: Script automático completo (Recomendado)
.\deploy.ps1

# Opção 2: Script rápido (somente build + deploy)
.\deploy-quick.ps1

# Opção 3: Comando único
flutter build web --release && firebase deploy --only hosting
```

---

## 📦 Comandos Web (Firebase Hosting)

| Comando | Descrição |
|---------|-----------|
| `flutter build web --release` | Compilar para web |
| `firebase deploy --only hosting` | Fazer deploy web |
| `firebase hosting:channel:open live` | Ver app em produção |
| `firebase deploy:list` | Histórico de deploys |

---

## 📱 Comandos Android

| Comando | Descrição |
|---------|-----------|
| `flutter build apk --release` | Gerar APK |
| `flutter build appbundle --release` | Gerar App Bundle (Google Play) |
| `flutter install` | Instalar em dispositivo conectado |

---

## 🍎 Comandos iOS

| Comando | Descrição |
|---------|-----------|
| `flutter build ios --release` | Compilar para iOS |
| `flutter build ipa --release` | Gerar IPA (App Store) |

---

## 🛠️ Manutenção

| Comando | Descrição |
|---------|-----------|
| `flutter clean` | Limpar build anterior |
| `flutter pub get` | Instalar dependências |
| `flutter analyze` | Verificar erros de código |
| `flutter doctor` | Diagnosticar problemas |

---

## 🔍 Debugging

| Comando | Descrição |
|---------|-----------|
| `flutter run` | Executar em debug mode |
| `flutter run --release` | Executar em release mode |
| `flutter devices` | Listar dispositivos conectados |
| `flutter logs` | Ver logs em tempo real |

---

## 📊 Status e Monitoração

| Comando | Descrição |
|---------|-----------|
| `firebase projects:list` | Listar projetos Firebase |
| `firebase use teb-cashtrack` | Selecionar projeto |
| `firebase hosting:channel:list` | Ver canais de deploy |
| `firebase deploy:list` | Ver histórico completo |

---

## ✨ Setup Inicial (Uma Única Vez)

```powershell
# 1. Instalar Firebase CLI
npm install -g firebase-tools

# 2. Fazer login
firebase login

# 3. Configurar projeto
firebase use teb-cashtrack

# 4. Pronto! Agora só rodar deploy.ps1
```

---

## 📝 Versão e Build Number

Para atualizar versão antes de deploy importante:

```yaml
# pubspec.yaml
version: 1.0.0+1
#        ^     ^
#     Version  BuildNumber
```

Depois recompile e faça deploy.

---

## 💾 Build Output

- **Web:** `build/web/`
- **Android APK:** `build/app/outputs/apk/release/app-release.apk`
- **Android AAB:** `build/app/outputs/bundle/release/app-release.aab`
- **iOS:** `build/ios/iphoneos/Runner.app`

---

## 🌐 URLs

- **App:** https://teb-cashtrack.web.app
- **Firebase Console:** https://console.firebase.google.com/project/teb-cashtrack
- **Alternate URL:** https://teb-cashtrack.firebaseapp.com

---

**Última atualização:** Junho 2026
**Projeto:** teb-cashtrack
**Stack:** Flutter + Firebase

