# Chat e notificações

O chat grava a mensagem no Firestore. O trigger `notificarMensagemChat` deriva o destinatário dos participantes da cotação e envia FCM para os documentos privados em `usuarios/{uid}/dispositivos_push`. Organizador e fornecedor registram seus dispositivos após validar a sessão/MFA. A renovação substitui o token anterior; o logout remove o registro da sessão. Tokens rejeitados definitivamente pelo FCM são removidos pelo backend.

Mensagens de sistema, mensagens já lidas, remetentes externos, contas desativadas e a preferência `preferencias_notificacao.chat: false` não geram envio. O envio é feito pelo backend; falhas de push não impedem a gravação da mensagem. FCM e eventos Firestore não garantem entrega exatamente uma vez; o identificador da mensagem é usado como tag de notificação para substituir repetições visíveis onde a plataforma suporta.

Com o aplicativo aberto, um aviso oferece “Abrir conversa”. O toque em notificações móveis e no navegador abre a conversa após validar a sessão. Na web o clique preserva os IDs em parâmetros, sem incluir o texto da mensagem, e o Firestore verifica novamente a autorização antes de abrir. O worker de push é preservado ao recarregar a página. A tela oferece um sino para solicitar novamente a permissão, confirmação de leitura, limite de 2.000 caracteres e bloqueio de envios simultâneos, preservando o próximo rascunho.

## Publicação pendente

Estas alterações locais não publicam serviços nem comprovam recebimento em um dispositivo real.

1. Publicar as regras Firestore e a função `notificarMensagemChat`, revisando também as demais alterações locais nas regras antes do deploy.
2. No Firebase Console, obter a chave pública dos certificados Web Push do projeto. Gerar o build web com `flutter build web --release --dart-define=FCM_WEB_VAPID_KEY=CHAVE_PUBLICA` e publicar o conteúdo de `build/web`, incluindo `firebase-messaging-sw.js`. O script `build_production.py` atual não injeta essa definição: usar o comando acima para este build ou adaptar o processo de release para passá-la.
3. Publicar a versão móvel atualizada. Android requer permissão de notificações; iOS também depende da configuração APNs do projeto e das capacidades do aplicativo.
4. Entrar como organizador e fornecedor em dois dispositivos/navegadores e permitir notificações. Enviar mensagens nas duas direções com o destinatário em primeiro plano, em segundo plano e com o app fechado. Tocar no push e conferir a conversa. Repetir com a preferência desligada, depois sair da conta e verificar que o dispositivo deixa de receber mensagens dela.

FCM é usado em Android/iOS e em navegadores compatíveis com Web Push, em HTTPS ou localhost. O aplicativo Windows nativo continua sem push em segundo plano; ele precisaria de uma integração própria de notificações. Os testes locais não validam entrega FCM, APNs, permissões do sistema nem interação real com notificações.

## Validação local

```powershell
npm --prefix functions run build
firebase emulators:exec --project demo-chat-push --only firestore "node functions/scripts/testChatPushEmulator.js"
flutter test test/features/cotacoes/chat_mensagens_page_test.dart
```

O emulador precisa de Java 21 ou superior. O teste usa exclusivamente um projeto `demo-` e um transportador FCM simulado: verifica destinatários, múltiplos dispositivos, preferências, mensagem lida/sistema, tokens inválidos e isolamento dos registros. Os testes de widget verificam o bloqueio de reenvio, a preservação de rascunhos e a confirmação de leitura em tempo real.

Referências: [recebimento no Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive), [configuração Web Push](https://firebase.google.com/docs/cloud-messaging/flutter/client#web).
