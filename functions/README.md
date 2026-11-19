# Cloud Functions — integração com a Pluggy

Importa contas e transações do banco pelo [Meu Pluggy](https://meu.pluggy.ai) (Open Finance)
para o Firestore do CashTrack. As credenciais são do Meu Pluggy do dono do app, então a
integração atende **uma conta** do CashTrack (`PLUGGY_OWNER_UID`); para os demais usuários a
opção nem aparece no app.

| Função | Quando roda | O que faz |
|---|---|---|
| `pluggySyncScheduled` | 7h, 13h e 19h (horário de Brasília) | Sincroniza tudo |
| `pluggySyncNow` | Botão **Sincronizar agora** no app | O mesmo, sob demanda (só o dono) |

Região: `southamerica-east1`. O Meu Pluggy atualiza os dados do banco uma vez por dia.

## O que a sincronização grava

- `users/{uid}/pluggy_accounts/{id}`: contas do banco (nome, tipo, final, saldo). O app grava
  `cashtrackAccountId`, a conta do app que recebe os lançamentos.
- `users/{uid}/transactions/pluggy_{id}`: só das contas vinculadas e só com o modo **Banco
  (Pluggy)** escolhido em Lançamento automático (`settings/import`). Primeira vez: 90 dias;
  depois, desde a última sincronização menos 10 dias. Só transações confirmadas (`POSTED`).
  Ao atualizar, mantém a descrição e a tag que o usuário alterou; a tag de um lançamento novo é
  sugerida pelo último lançamento com a mesma descrição.
- `users/{uid}/pluggy_ignored/{id}`: lançamentos que o usuário excluiu no app; não voltam.
- `users/{uid}/settings/pluggy`: última sincronização e último erro (mostrados no app).

## Configurar (uma vez)

1. **Pluggy** (o acesso ao Meu Pluggy só pode ser autorizado durante o teste de 15 dias):
   1. Em [dashboard.pluggy.ai](https://dashboard.pluggy.ai), crie uma aplicação de
      desenvolvimento e anote o **Client ID** e o **Client Secret**.
   2. Inclua o conector **MeuPluggy** na lista de conectores.
   3. Na aplicação Demo, conecte o MeuPluggy (uma vez por banco) e copie o **Item ID** de cada
      conexão (menu de três pontos).
2. **Firebase**: ative o plano **Blaze** (Cloud Functions e Cloud Scheduler exigem; o uso deste
   projeto fica dentro da cota gratuita na prática).
3. **Segredos** (pedem o valor no terminal; não ficam no código):

   ```bash
   firebase functions:secrets:set PLUGGY_CLIENT_ID
   firebase functions:secrets:set PLUGGY_CLIENT_SECRET
   firebase functions:secrets:set PLUGGY_ITEM_IDS
   firebase functions:secrets:set PLUGGY_OWNER_UID
   ```

   `PLUGGY_ITEM_IDS` aceita vários IDs separados por vírgula. `PLUGGY_OWNER_UID` é o UID da sua
   conta no Firebase Console → Authentication.
4. **Deploy**: `firebase deploy --only functions` (o `firebase.json` local já aponta para esta
   pasta e compila antes do envio).
5. No app: **Dados do usuário → Lançamento automático → Banco (Pluggy)**, vincule as contas e
   toque em **Sincronizar agora**. O item só aparece depois da primeira sincronização (a
   agendada, ou rode a função `pluggySyncNow` pelo console).

## Desenvolvimento

```bash
npm install
npm test        # compila e roda os testes de mapping.test.ts
```

`test/pluggy_test.dart` (no app) confere que os nomes de coleções e campos usados aqui batem
com os do app.

Se a integração for aberta a outros usuários, cada um precisaria das próprias credenciais e a
política de privacidade (`web/privacidade.html`) e o formulário de Segurança dos dados do Play
precisariam citar a Pluggy.
