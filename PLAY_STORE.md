# Publicação no Google Play

Roteiro para publicar o app Android (`br.com.thatexoticbug.teb_cashtrack`) e respostas prontas
para os formulários do Play Console.

## 1. Antes de enviar

- [ ] Preencher o e-mail de contato em `web/privacidade.html` (procure `CONTATO`).
- [ ] Publicar a versão web, que também serve as páginas públicas exigidas pelo Play:
      `flutter build web --release && firebase deploy --only hosting`
  - Política de privacidade: https://teb-cashtrack.web.app/privacidade.html
  - Exclusão de conta: https://teb-cashtrack.web.app/excluir-conta.html
- [ ] Remover o bloco "TEMPORÁRIO" de `firestore.rules` e publicar as regras
      (`firebase deploy --only firestore:rules`). Com cadastro aberto ao público, qualquer
      usuário logado poderia ler as coleções antigas da raiz.
- [ ] Aumentar a versão em `pubspec.yaml` (`version: x.y.z+N`). O número depois do `+`
      (versionCode) precisa ser maior a cada envio.
- [ ] `flutter analyze` e `flutter test` sem erros.

## 2. Gerar o pacote

```bash
flutter build appbundle --release
```

Arquivo: `build/app/outputs/bundle/release/app-release.aab`.

O AAB é assinado com `android/cashtrack-release.jks` (configurado em `android/key.properties`).
No Play Console ative o **Play App Signing**: essa chave passa a ser a *chave de upload* e o
Google guarda a chave final do app. Guarde cópias do `.jks` e do `key.properties`; sem eles não é
possível enviar atualizações (dá para pedir a troca da chave de upload ao suporte, mas demora).

## 3. Conta de desenvolvedor

- Criar em https://play.google.com/console (taxa única de US$ 25, com verificação de identidade).
- **Contas pessoais criadas depois de 13/11/2023** só liberam a produção depois de um
  **teste fechado com pelo menos 12 testadores ativos por 14 dias seguidos**. Planeje isso:
  crie a faixa de *Teste fechado*, adicione os e-mails dos testadores (lista do Google Groups ou
  de e-mails) e só depois peça acesso à produção.

## 4. Conteúdo do app (Play Console → Política → Conteúdo do app)

| Formulário | Resposta |
|---|---|
| Política de privacidade | https://teb-cashtrack.web.app/privacidade.html |
| Acesso ao app | Requer login. Crie uma conta de teste (e-mail/senha) só para a revisão do Google, com algumas contas e lançamentos de exemplo, e informe os dados ali. |
| Anúncios | Não contém anúncios. |
| Classificação de conteúdo | Questionário IARC, categoria "Utilitário/Produtividade"; sem violência, sem conteúdo sexual, sem apostas, sem interação entre usuários. |
| Público-alvo | 18 anos ou mais. |
| Apps de notícias | Não. |
| Recursos financeiros | O app não oferece empréstimos, pagamentos, investimentos nem cripto: é só um registro pessoal de gastos. Escolha a opção que indica que o app não oferece esses serviços financeiros. |
| Saúde, governo, VPN | Não se aplica. |
| Exclusão de dados | Os usuários podem pedir a exclusão da conta: sim. URL: https://teb-cashtrack.web.app/excluir-conta.html. Também é possível apagar dados sem excluir a conta (cada registro no app). |

### Segurança dos dados (Data safety)

- O app coleta ou compartilha dados? **Sim, coleta. Não compartilha** (o Firebase é provedor
  de serviço, o que não conta como compartilhamento).
- Os dados são criptografados em trânsito? **Sim.**
- O usuário pode pedir a exclusão dos dados? **Sim.**

| Tipo de dado | Coletado | Obrigatório? | Finalidade |
|---|---|---|---|
| Informações pessoais → Endereço de e-mail | Sim | Obrigatório | Funcionalidade do app, gerenciamento da conta |
| Informações financeiras → Histórico de compras | Sim | Opcional (lançamento automático) | Funcionalidade do app |
| Informações financeiras → Outras informações financeiras | Sim | Obrigatório (contas, saldos, lançamentos) | Funcionalidade do app |

Nada é processado de forma efêmera e nada é usado para publicidade, análise ou personalização.

## 5. Permissões sensíveis

- **Acesso a notificações** (`BIND_NOTIFICATION_LISTENER_SERVICE`): não é uma permissão
  declarada no Console, mas o Google exige um **aviso em destaque** antes do pedido. O app mostra
  esse aviso (tela *Lançamento automático* → *Conceder*) e só abre os ajustes do Android depois de
  o usuário tocar em *Concordo*. Na descrição da loja, deixe claro que o recurso é opcional e
  para que serve.
- **Bateria**: o app **não** usa `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (restrita pelo Play).
  O botão *Ajustes* abre a tela do app no Android, onde o usuário escolhe Bateria → Sem restrições.

## 6. Ficha da loja

- Nome: CashTrack (até 30 caracteres).
- Descrição curta (até 80): "Controle de contas, cartões e gastos, com lançamento automático."
- Ícone 512×512 (`web/icons/Icon-512.png`) e imagem de destaque 1024×500.
- Pelo menos 2 capturas de tela do celular (tire de uma conta de exemplo, sem dados reais).
- Categoria: Finanças. E-mail de contato obrigatório.

## 7. Requisitos técnicos já atendidos

- `targetSdk 36` (exigido para apps novos e atualizações desde 31/08/2026) e `compileSdk 36`
  em `android/app/build.gradle.kts`.
- Formato AAB assinado, `minSdk 23`.
- Exclusão de conta pelo app e pela web (*Dados do usuário → Excluir minha conta*), que apaga
  `users/{uid}/...` e o login do Firebase Auth.
- Link para a política de privacidade no login e em *Dados do usuário*.
