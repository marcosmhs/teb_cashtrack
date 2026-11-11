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

## Dados por usuário

Todos os dados ficam em `users/{uid}/{coleção}` e as regras (`firestore.rules`) só permitem acesso ao dono.
A importação das coleções antigas (na raiz do Firestore, da versão anterior) já foi feita e foi
removida do app na versão 1.2.0; as coleções antigas podem ser apagadas pelo console do Firebase.

## App Android

O mesmo código gera o app Android (`android/`), que usa o mesmo Firebase da versão web.

Arquivos locais, fora do git (guarde cópia de segurança):

- `android/app/google-services.json`: configuração do app Android no Firebase
  (`firebase apps:sdkconfig ANDROID <app-id>`).
- `android/key.properties` e `android/cashtrack-release.jks`: chave de assinatura. **Sem ela não é
  possível atualizar o app instalado**; seria preciso desinstalar e instalar de novo.

```bash
flutter build apk --release          # gera build/app/outputs/flutter-apk/app-release.apk
flutter install                      # instala no celular conectado por USB
```

### Funcionamento sem internet (banco local + sincronização)

O app grava e lê primeiro no banco do aparelho e sincroniza com a nuvem sozinho quando há
conexão. Esse banco é o cache persistente do Firestore (SQLite no Android), ligado por padrão:

- **Leituras**: as telas mostram os dados salvos no aparelho, com ou sem internet.
- **Gravações**: aplicadas na hora no aparelho e enviadas quando a conexão voltar. Se o app for
  fechado antes, elas ficam guardadas e são enviadas na próxima vez que ele (ou o serviço de
  notificações) rodar com internet. Os controllers usam `writeLocal` (`lib/data/local_first.dart`), que
  **não espera** a confirmação do servidor; sem isso, salvar ficaria travado sem internet.
  Falhas de sincronização aparecem como aviso na parte de baixo da tela.
- **Contagens** usam `get()` em vez de `count()`, porque agregações só rodam no servidor.
- **Indicador**: na tela inicial, um ícone de nuvem aparece quando o app está sem conexão ou
  enviando alterações (`lib/widgets/sync_status_button.dart`). Sincronizado, ele some.
- O serviço de lançamento automático também grava no banco local quando está sem internet.

Precisam de internet: o primeiro login (e entrar de novo depois de sair), criar conta, trocar
e-mail/senha e excluir a conta. Se a mesma informação for alterada em dois aparelhos sem conexão, vale a última gravação que chegar ao servidor.

### Lançamento automático (notificações)

Um `NotificationListenerService` nativo (`android/app/src/main/kotlin/.../notifications/`) lê as
notificações dos apps escolhidos (Samsung Wallet por padrão), extrai valor, estabelecimento e final
do cartão (`NotificationParser.kt`) e grava o lançamento em `users/{uid}/transactions` com
`source: "notification"`. Toda notificação recebida também fica em
`users/{uid}/notification_captures`, visível na tela **Lançamento automático**.

A conta do lançamento é escolhida pelo campo **Identificador nas notificações** da conta (ex.: final
do cartão); sem correspondência, vai para o único cartão ativo ou para o meio de pagamento principal.

Testes do leitor de notificações (usar o JDK do Android Studio):

```bash
cd android && JAVA_HOME="C:/Program Files/Android/Android Studio/jbr" ./gradlew :app:testDebugUnitTest
```

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Veja também `BUILD_DEPLOY.md` e `DEPLOY_QUICK_START.md`.
