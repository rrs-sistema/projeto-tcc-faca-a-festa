# 01 — Privacidade e integridade dos atendimentos

Validação local concluída em 26/10/2026. Este registro substitui a evidência parcial anterior.

## Escopo, instruções e preservação

Git conferido antes das edições e novamente na retomada. Nenhum AGENTS.md encontrado na árvore do projeto nem nos ancestrais consultados até a raiz. O checkout já continha alterações de financeiro, repasse, comissão e outras áreas, inclusive em firestore.rules. Foram preservadas: o diff de regras também contém proteções financeiras anteriores, que não são autoria deste prompt. Não houve deploy, commit, push, migração, mensagens externas nem uso de dados reais.

## Mapeamento confirmado

- Caminho canônico: cotacao/{cotacaoId}/fornecedores/{fornecedorId}/mensagens/{mensagemId}.
- FirebaseCotacaoRemoteDatasource: observarConversasFornecedor consulta collectionGroup fornecedores por id_fornecedor e monta resumos lendo mensagens; observarMensagens usa enviado_em; marcarMensagensComoLidas consulta autores diferentes da sessão e atualiza somente lido; enviarMensagem grava os cinco campos previstos. buscarConversaFornecedor faz leitura pontual. Os listeners de cotação, participação e serviços também passam pela proteção de sessão.
- ChatMensagensPage e FornecedorMensagensPage consomem esses streams via GerenciarCotacoes. A tela de chat marca leitura ao abrir. A comunicação usa texto; não há upload, URL de anexo ou metadados de arquivo no modelo CotacaoMensagemModel/interface de envio.
- FornecedorRemoteDatasource: observarMensagensNaoLidas mantém um listener por participação; carregarEstatisticas usava collectionGroup mensagens com lida/id_fornecedor, incompatível com os documentos reais. Agora ambos consultam somente caminhos de participação e contam lido, excluindo autor próprio e sistema.
- Backend: criarCotacao, responderCotacao, cancelarCotacao e fecharCotacao usam mensagensSistemaCotacao (Admin SDK). Os handlers validam usuário/papel e vínculo antes da operação. O helper de sistema é interno, sem endpoint de gravação arbitrária de mensagens.
- Não há atribuição explícita de suporte a uma conversa no modelo inspecionado. Ser administrador por si só não permite ler, enviar, marcar leitura ou apagar mensagens. As concessões administrativas de metadados da cotação não se propagam para o chat.
- Busca em lib e functions/src não encontrou outros consumidores/escritores de mensagens de chat além dos relacionados acima. Storage não é usado pelo chat; nenhuma nova concessão de arquivos foi criada. O envio rejeita campos de anexos/metadados desconhecidos.

## Regras e comportamento

Removida a leitura autenticada recursiva de mensagens. A regra genérica de subcoleções exclui mensagens explicitamente em read/update/delete: uma concessão permissiva coincidente não pode anular as restrições específicas.

Leitura e envio exigem solicitante da cotação ou UID do fornecedor da conversa, com documento de participação existente. Mesmo evento, outro fornecedor, outro cliente, conhecimento do ID, sessão anônima ou papel administrativo sem participação não bastam. collectionGroup fornecedores passa a exigir filtro id_fornecedor igual à sessão; a listagem específica do organizador continua pela regra do caminho.

Envio exige autor igual ao UID autenticado, nome string até 200 caracteres, texto string de 1 a 2000 caracteres, lido=false, enviado_em igual ao instante do servidor e somente os cinco campos permitidos. sistema e anexos não podem ser fabricados pelo cliente.

Update de mensagem permite somente lido=true por participante diferente do autor. Não altera texto, autor, nome, data original ou campos de sistema. Delete é negado inclusive para participantes/admin. O teste compara o documento completo antes/depois da leitura. Mensagens de sistema permanecem legíveis aos participantes e somente backend autorizado pode criá-las.

Estados de pai/participação e identidade agora são exclusivos das callables: update/delete diretos desses documentos são negados. Os fluxos existentes de resposta, contratação e cancelamento já usam callables. Isso impede adulterar o status para reabrir uma conversa encerrada ou remover o vínculo de autorização pelo SDK cliente.

Após contratação (pai concluida, fornecedor ganhouCotacao) a conversa operacional continua aberta. Pai cancelada ou participação cancelada/recusado/perdeuCotacao bloqueiam novos envios; o histórico continua legível aos participantes. Nenhuma reabertura foi introduzida.

## Sessão, cache e consultas

streamDaSessao cancela a assinatura de dados e a assinatura de autenticação quando muda o UID ou a tela cancela a escuta; em troca de sessão publica coleção vazia/contador zero, encerra o stream e descarta conclusões antigas de asyncMap. A nova sessão precisa abrir nova consulta. O helper cobre streams de conversas, mensagens, participações, serviços e indicadores relacionados. O contador agregado cancela também os listeners filhos.

Streams publicam somente snapshots confirmados pelo servidor, usando includeMetadataChanges e filtrando isFromCache. Leituras auxiliares de cotação usam Source.server. Isso evita reutilizar mensagens persistidas no cache de outra sessão enquanto o servidor ainda avalia a autorização. Sem conexão, a interface não oferece histórico offline potencialmente pertencente a outra conta.

Envio e marcação verificam UID atual. Marcação divide atualizações em lotes de 400, verificando sessão antes de cada commit. Estatísticas descartam resultado se a sessão mudar durante a consulta. Participações retornadas pelo collectionGroup são limitadas ao caminho cotacao antes de consultar mensagens.

Não há collectionGroup mensagens no aplicativo após a mudança. A suíte testa explicitamente sua negação, inclusive query com filtro de autor. Não foram adicionados índices: enviado_em e id_usuario usam índices simples; collectionGroup fornecedores/id_fornecedor já possui fieldOverride existente em firestore.indexes.json. O contador deixou de combinar desigualdade e lido, evitando um novo índice composto. Consultas por conversa leem o histórico para calcular o contador; custo cresce com o histórico, sem ampliar permissões.

## Testes e comandos efetivamente executados

A primeira tentativa anterior falhou por Java inferior a 21. Resolvido nesta retomada com JDK 21 do Eclipse Adoptium em pasta temporária, sem alterar configuração global. Variáveis usadas somente no processo PowerShell:

```powershell
$env:JAVA_HOME=Join-Path $env:TEMP 'codex-chat-jdk/jdk-21.0.12.1+1'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
npm --prefix functions run build
firebase emulators:exec --project demo-chat-privado --only firestore "node test/firestore/atendimentos.rules.test.js"
flutter test test/data/services/stream_da_sessao_test.dart test/features/cotacoes test/features/cotacao
dart analyze lib/data/services/stream_da_sessao.dart lib/data/datasources/remote/cotacao_remote_datasource.dart lib/data/datasources/remote/fornecedor_remote_datasource.dart test/data/services/stream_da_sessao_test.dart test/features/cotacoes/cotacao_repository_test.dart
```

Resultados finais:

- Build TypeScript (tsc): exit 0.
- Emulador Firestore, projeto demo-chat-privado: **116 verificações aprovadas**, exit 0. Dados sintéticos, clientes ca/cb, fornecedores fa/fb, usuário sem vínculo, administrador e contexto não autenticado. Inclui leitura direta/listagem/collectionGroup, envio legítimo bidirecional, falsificação, campos extras, limites de tamanho/data, edição/exclusão, marcação com preservação integral e estados contratados/cancelados/recusados/perdedores. A conversa B também é acessível por suas partes e negada às partes A. Erros PERMISSION_DENIED no log correspondem às negativas esperadas.
- A mesma execução importa e chama a função compilada gravarMensagemSistema usando Admin SDK conectado ao emulador, e verifica leitura autorizada/negada pelos SDKs cliente. Não é somente mock de regras ou de backend.
- Flutter: **14 testes aprovados**, exit 0. Inclui cancelamento de dados/autenticação, limpeza na troca de sessão e descarte de emissão antiga, repositório, cancelamento e isolamento por evento/sessão.
- O primeiro teste ampliado encontrou fake antigo retornando String em confirmarFornecedorEscolhido, enquanto a API atual retorna Map. O fake e sua expectativa foram atualizados para o contrato existente; reexecução aprovada.
- dart analyze final: **No issues found**, exit 0.
- dart format executado nos Dart alterados; git diff --check dos arquivos de código deste escopo sem erros. A verificação global anterior apontou linha em branco em arquivo preexistente de calculadora, fora deste trabalho.

## Arquivos deste escopo

- firestore.rules (preservando alterações financeiras anteriores)
- lib/data/datasources/remote/cotacao_remote_datasource.dart
- lib/data/datasources/remote/fornecedor_remote_datasource.dart
- lib/data/services/stream_da_sessao.dart
- test/data/services/stream_da_sessao_test.dart
- test/features/cotacoes/cotacao_repository_test.dart (compatibilidade do fake)
- test/firestore/atendimentos.rules.test.js
- docs/evidencias_validacao/operacao-fornecedor/01-seguranca-atendimentos.md

## Limites da validação

Validação automatizada local em SDKs reais contra emulador e testes Flutter; não houve ensaio manual com aplicativo instalado nem execução de operações em produção. Não foram alteradas as Functions de cotação, apenas compiladas e inspecionadas, com execução real do helper de mensagens no emulador. Não existe acesso de suporte específico a implementar sem um modelo de atribuição; o padrão aplicado é negar esse acesso. Publicação das regras/aplicativo está deliberadamente fora do escopo autorizado.
