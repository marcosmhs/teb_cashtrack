# Guia de Build e Deploy - TEB CashTrack

## Pré-requisitos

```bash
# Verificar instalação do Flutter
flutter doctor

# Instalar dependências
flutter pub get
```

---

## 🌐 WEB (Firebase Hosting)

### Build Web

```bash
# Build para web (modo release)
flutter build web --release

# Build para web com target específico
flutter build web --release --no-tree-shake-icons
```

### Deploy no Firebase Hosting

```bash
# Fazer login no Firebase (primeira vez)
firebase login

# Deploy do build web
firebase deploy --only hosting

# Deploy com caminho específico
firebase deploy --only hosting:teb-cashtrack
```

### Build + Deploy em um comando

```bash
# Build web e deploy no Firebase
flutter build web --release && firebase deploy --only hosting
```

---

## 📱 ANDROID

### Build APK

```bash
# Build APK em modo release
flutter build apk --release

# APK split por arquitetura
flutter build apk --release --split-per-abi
```

### Build App Bundle (para Google Play Store)

```bash
# Gerar App Bundle
flutter build appbundle --release

# App Bundle com versão específica
flutter build appbundle --release --build-number=2
```

### Deploy no Google Play Store

```bash
# Usar Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/apk/release/app-release.apk \
  --app 1:179128878024:android:XXXXX \
  --release-notes "Versão de teste"
```

---

## 🍎 iOS

**Nota:** Requer Mac com Xcode instalado

```bash
# Build iOS
flutter build ios --release

# Build iOS e gerar arquivo IPA
flutter build ipa --release
```

---

## 📋 Checklist antes de Deploy

```bash
# 1. Verificar e corrigir erros
flutter analyze

# 2. Rodar testes
flutter test

# 3. Incrementar versão (se necessário)
# Editar pubspec.yaml: version: 1.0.0+1

# 4. Limpar build anterior
flutter clean

# 5. Obter dependências
flutter pub get

# 6. Build e test
flutter build web --release

# 7. Deploy
firebase deploy --only hosting
```

---

## 🚀 Scripts de Automação

### Windows (PowerShell)

Crie um arquivo `deploy.ps1`:

```powershell
# Limpar
Write-Host "Limpando build anterior..." -ForegroundColor Green
flutter clean
flutter pub get

# Build Web
Write-Host "Compilando para web..." -ForegroundColor Green
flutter build web --release

# Deploy
Write-Host "Fazendo deploy no Firebase..." -ForegroundColor Green
firebase deploy --only hosting

Write-Host "Deploy concluído!" -ForegroundColor Green
```

Executar:
```bash
.\deploy.ps1
```

### Linux/Mac (Bash)

Crie um arquivo `deploy.sh`:

```bash
#!/bin/bash

# Cores
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Limpando build anterior...${NC}"
flutter clean
flutter pub get

echo -e "${GREEN}Compilando para web...${NC}"
flutter build web --release

echo -e "${GREEN}Fazendo deploy no Firebase...${NC}"
firebase deploy --only hosting

echo -e "${GREEN}Deploy concluído!${NC}"
```

Executar:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📊 Verificar Status do Deploy

```bash
# Ver histórico de deploys
firebase deploy:list

# Ver logs do hosting
firebase hosting:channel:list

# Ver versão atual em produção
firebase hosting:disable
```

---

## 🔍 Troubleshooting

### Problema: "firebase not found"
```bash
npm install -g firebase-tools
firebase login
```

### Problema: Build falha
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build web --release
```

### Problema: Permissões Firebase
```bash
firebase projects:list
firebase use teb-cashtrack
firebase deploy --only hosting
```

---

## 📝 Versão Atual

- **App Version:** 1.0.0
- **Build Number:** 1
- **Firebase Project:** teb-cashtrack
- **Hosting Target:** build/web

