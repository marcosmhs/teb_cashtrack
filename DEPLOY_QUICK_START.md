# 🚀 Comandos de Build e Deploy - TEB CashTrack

## ⚡ Comando Rápido (Build + Deploy)

```powershell
# Windows PowerShell - Compile e faz deploy em um comando
flutter build web --release && firebase deploy --only hosting
```

---

## 📋 Passos Individuais

### 1️⃣ Preparar (Primeira vez ou após mudanças significativas)

```powershell
# Limpar e atualizar
flutter clean
flutter pub get
```

### 2️⃣ Compilar para Web

```powershell
# Build em modo release
flutter build web --release

# Tempo estimado: 2-5 minutos
# Resultado: build/web/
```

### 3️⃣ Fazer Deploy

```powershell
# Deploy no Firebase Hosting
firebase deploy --only hosting

# Tempo estimado: 1-2 minutos
# URL de acesso: https://teb-cashtrack.web.app
```

---

## 🤖 Scripts Automáticos

### Opção 1: Script Completo (Recomendado)

```powershell
# Execute no terminal PowerShell (como administrador):
.\deploy.ps1

# Inclui: limpeza, build, análise, deploy
```

### Opção 2: Script Rápido

```powershell
# Para quando já está tudo pronto
.\deploy-quick.ps1
```

---

## 🔐 Primeiro Setup

```powershell
# 1. Verificar Flutter
flutter doctor

# 2. Instalar Firebase CLI globalmente (se não tiver)
npm install -g firebase-tools

# 3. Fazer login no Firebase
firebase login

# 4. Verificar projeto
firebase projects:list
firebase use teb-cashtrack

# 5. Pronto para fazer deploy!
```

---

## 📊 Monitorar Deploy

```powershell
# Ver histórico de deploys
firebase deploy:list

# Ver versão atual em produção
firebase hosting:channel:list

# Ver logs em tempo real
firebase hosting:channel:open live
```

---

## ✅ Checklist Pré-Deploy

- [ ] Código compilado sem erros: `flutter analyze`
- [ ] Versão atualizada em `pubspec.yaml`
- [ ] Testes passando (se houver)
- [ ] `pubspec.lock` atualizado
- [ ] Nenhuma secret/token no código
- [ ] Build local testado em navegador

---

## 🚨 Troubleshooting

### "firebase is not recognized"
```powershell
npm install -g firebase-tools
firebase login
```

### "Flutter not found"
```powershell
# Adicionar Flutter ao PATH ou usar caminho completo
flutter pub get
```

### Build falha ou fica lento
```powershell
flutter clean
flutter pub get
flutter build web --release
```

### Deploy retorna erro de permissão
```powershell
firebase login --reauth
firebase use teb-cashtrack
firebase deploy --only hosting
```

---

## 📞 URLs Úteis

- **App em Produção:** https://teb-cashtrack.web.app
- **Firebase Console:** https://console.firebase.google.com/project/teb-cashtrack
- **Documentação Flutter:** https://flutter.dev/docs
- **Firebase CLI Docs:** https://firebase.google.com/docs/cli

---

## 💡 Dicas Rápidas

1. **Faster builds:** Use `flutter build web --release --no-tree-shake-icons`
2. **Testar antes:** Abra `build/web/index.html` localmente
3. **Monitorar:** Visite https://console.firebase.google.com para ver tráfego
4. **Rollback:** Pode reverter versões no Firebase Console
5. **Versioning:** Atualize `pubspec.yaml` antes de cada release importante

