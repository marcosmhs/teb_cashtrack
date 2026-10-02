# CashTrack

Controle pessoal de contas correntes, cartões de crédito, lançamentos e lista de compras.
Flutter (web) + Firebase Auth + Cloud Firestore.

## Estrutura

```
lib/
  controllers/   acesso ao Firestore (um por coleção) e autenticação
  data/          caminho das coleções do usuário (users/{uid}/...)
  models/        modelos e enums (TransactionType, AccountType)
  services/      regras de negócio puras (saldos, faturas) e migração
  utils/         formatação pt_BR (moeda, datas) e leitura de dados do Firestore
  widgets/       componentes compartilhados (cards, formulário de lançamento, diálogos)
  views/         telas
test/            testes de unidade (formatação, saldos/faturas, modelos)
```

Convenções:

- Valores monetários são `int` em **centavos**; datas são `Timestamp` no Firestore.
- Cores vêm do tema (`context.colors`, `context.finance`); não use `Color(0xFF...)` nas telas.
- Os modelos leem o formato antigo (reais em `double`, datas em string ISO) para manter compatibilidade.

## Dados por usuário e migração

Todos os dados ficam em `users/{uid}/{coleção}` e as regras (`firestore.rules`) só permitem acesso ao dono.

Para quem usava a versão anterior (coleções na raiz do Firestore):

1. Publique as regras: `firebase deploy --only firestore:rules`.
2. Entre no app e use **Dados do usuário → Importar dados antigos**.
3. Confira os dados e remova o bloco "TEMPORÁRIO" de `firestore.rules`, publicando de novo.
   As coleções antigas podem então ser apagadas pelo console do Firebase.

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Veja também `BUILD_DEPLOY.md` e `DEPLOY_QUICK_START.md`.
