# Consultas e consumo no Google Cloud — 04/11/2026

Foi feita uma varredura de `lib/**/*.dart` e `functions/src/**/*.ts`, revisão dos caminhos de maior risco e uma rodada de otimizações locais. O objetivo foi reduzir leituras e execução repetidas sem truncar saldos, históricos ou verificações de autorização. Não houve deploy nem alteração de dados, regras, índices ou infraestrutura no projeto hospedado.

## Consumo observado

Projeto `faca-a-festa`. Janela de **28/10/2026 às 08:16:35 até 04/11/2026 às 08:16:35, São Paulo**, consultada pela API do Cloud Monitoring:

| Métrica | Total disponível na janela |
| --- | ---: |
| Leituras de documentos Firestore | 6.473 |
| Gravações de documentos Firestore | 36 |
| Exclusões de documentos Firestore | Sem pontos retornados |
| Requisições Cloud Run | 66 |
| Tempo faturável de instâncias Cloud Run | 168,02 segundos de instância |

O volume dessas operações está baixo no período consultado. Isso não demonstra que a fatura esteja zerada: métricas operacionais não são um extrato financeiro, não representam necessariamente todos os itens faturáveis e podem chegar com atraso. Ausência de pontos também não comprova custo zero. Cloud Run inclui requisições OPTIONS; 66 requisições não significam 66 ações de negócio.

O painel consolidado teve 19 requisições e 44,5 segundos de instância; o resumo financeiro teve 14 requisições e 32,2 segundos. O expurgo diário de auditoria teve 7 execuções e 39,6 segundos. Esses dados ajudam a priorizar, mas não atribuem todas as leituras do Firestore a cada tela.

[Métricas sanitizadas por serviço e intervalo](evidencias_validacao/consultas-cloud-2026-11-04/metricas-7-dias.json).

## O que foi corrigido

| Caminho | Alteração local | Efeito verificável |
| --- | --- | --- |
| Visão operacional da captura | Carrega suas fontes diretas, sem executar o painel consolidado que calcula agenda, financeiro e fila detalhada não exibidos nessa visão | Teste confirma nenhuma chamada à callable consolidada nesse modo; os indicadores e a primeira resposta continuam disponíveis |
| Abertura da home | Removida segunda atualização no post-frame do componente pai | A inicialização pertence ao componente que apresenta os indicadores |
| Controller do painel | Inicialização reutilizável e compartilhamento de carregamentos simultâneos por geração de sessão | Evita duplicar timers, escutas e buscas; sessão nova continua independente |
| Retorno de uma tela de alteração | Pode invalidar a leitura em andamento antes de atualizar | Uma resposta anterior não substitui a consulta pedida após a alteração |
| Resumo financeiro no app | Consultas idênticas em andamento compartilham uma requisição por datasource; chave inclui fornecedor, evento e deduções | Quatro chamadas simultâneas idênticas executam uma chamada de transporte |
| Após registro financeiro | Invalidação do compartilhamento na conclusão do comando | Uma nova leitura não reutiliza o snapshot iniciado antes do lançamento; comandos continuam separados e idempotentes |
| Timeout financeiro | Controller e datasource usam o mesmo prazo de 30 s | Evita que o controller desista antes do prazo de transporte; é uma proteção de disponibilidade, não a redução de custo |
| Resumo + planejamento no backend | Compartilham fatos e projeções da mesma transação de leitura | Contratos, comissão, repasses, custos, recebimentos e movimentos consultados uma vez por resumo no teste instrumentado |
| Repasses do planejamento | Reutiliza documentos já lidos pela projeção contratual | Elimina uma segunda consulta por alias nessa etapa |
| Projeção contratual | Comissão e repasses independentes são buscados em paralelo por contrato | Menos esperas sequenciais, mantendo as verificações de vínculo e valor |
| Catálogo ativo e estoque no painel | Duas agregações `count()` | Não baixam os documentos inteiros para contar; catálogo conserva o critério `ativo == true` |
| Painel administrativo | Três agregações `count()` para subcategorias, temas e territórios | Não baixa essas coleções; os demais indicadores preservam as regras de documentos legados |

O compartilhamento dura somente enquanto a consulta está pendente. Não foi criado cache persistente de valores financeiros. Falhas liberam uma nova tentativa; resultados não são compartilhados entre filtros ou fornecedores diferentes. O modo consolidado continua disponível para o componente que apresenta a fila detalhada; ele não foi removido do backend.

Arquivos principais: `lib/data/services/consultas_em_andamento.dart`, `financeiro_fornecedor_remote_datasource.dart`, `painel_operacional_controller.dart`, `visao_operacional_fornecedor.dart`, `painel_fontes_disponiveis.dart`, `admin_dashboard_remote_datasource.dart`, `comandosFinanceiroFornecedor.ts`, `planejamentoFornecedorService.ts` e `visaoFinanceiraContratoService.ts`.

## Cobertura da varredura

Foram varridos **977 arquivos de código**, com ocorrências candidatas em **122 arquivos**: 58 no aplicativo e 64 no backend. Foram localizados 52 pontos de declaração de `snapshots()`. Isso não significa 52 listeners simultâneos em uma sessão. O inventário inclui ocorrências de `get`, agregações, limites, cursores e callables, com arquivo, linha e trecho.

O levantamento é textual e orienta a revisão: `Map.get` também aparece entre os candidatos TypeScript; uma ocorrência não equivale a uma requisição nem a uma leitura faturada. Não foi feita uma auditoria semântica individual de cada chamada. O diagnóstico aprofundado priorizou os caminhos abaixo.

[Inventário navegável em JSON](evidencias_validacao/consultas-cloud-2026-11-04/inventario-consultas.json).

## Riscos que ainda precisam de alteração estrutural

Não foram aplicados limites arbitrários às consultas abaixo: isso poderia omitir pendências, alterar médias ou apresentar saldos incompletos como totais. Eles permanecem explicitamente pendentes.

| Prioridade | Área / arquivo | Achado e próxima alteração necessária |
| --- | --- | --- |
| Alta | Mensagens — `fornecedor_remote_datasource.dart`, métodos `observarMensagensNaoLidas` e `carregarEstatisticas` | Um listener por conversa e leitura de todas as mensagens para contar não lidas. Criar resumo persistido por participante/conversa, atualizado com envio e leitura; normalizar os registros legados antes de filtrar somente mensagens não lidas. Campos ausentes hoje também podem representar não lidas |
| Alta | Home — `painel_fontes_disponiveis.dart` | A leitura direta ainda percorre conversas, mensagens e propostas. Ela pode repetir parte do que o contador global já acompanha. Substituir históricos por resumo de pendência, não lidas e primeira resposta por conversa, conservando a definição da coorte de 720 horas |
| Alta | Pedidos — `solicitacoes_remote_datasource.dart` | Cada snapshot da lista relê pais, serviços e eventualmente orçamento de todos os itens. Implementar projeção de lista por fornecedor e paginação por cursor, carregando detalhes ao abrir o pedido |
| Alta | Organizador — `cotacao_remote_datasource.dart` | Snapshot de todas as cotações e consultas filhas para total/status por item. Persistir resumo confiável e paginar; manter detalhes separados da lista |
| Alta | Avaliações — `avaliacao_servico_remote_datasource.dart` | Snapshot dispara leitura de várias fontes legadas e comprovação/resposta por avaliação. Paginar avaliações, migrar histórico e evitar reler todos os registros imutáveis a cada emissão; preservar a comprovação de integridade |
| Alta | Painel consolidado — `painelOperacionalService.ts` | Para a fila detalhada, ainda percorre históricos e combina agenda, planejamento e reputação, com consultas adicionais de repasse por contrato. Foi retirado da home de cartões; a próxima etapa é uma projeção própria de pendências e métricas |
| Média | Financeiro privado | Os listeners de custos, caixa, recebimentos e orçamentos continuam lendo coleções completas e notificando o resumo. O compartilhamento reduz sobreposições, mas eventos posteriores ainda podem provocar nova consulta. Avaliar revisão agregada por fornecedor/evento e carregamento de detalhes sob demanda |
| Média | Agenda — `agendaFornecedorService.ts` | Consulta contratos, recursos, reservas e histórico completo, além de evento e calculadora por contrato. Paginar histórico e reutilizar evento/calculadora quando repetidos na mesma leitura |
| Média | Admin — `admin_dashboard_remote_datasource.dart` | Seis coleções ainda são lidas para regras de ativo/pendente e compatibilidade de nomes. Normalizar campos e criar agregados de indicadores antes de trocar tudo por filtros/agregações |
| Média | Admin financeiro — `consultarDashboardFinanceiroAdmin.ts`, `consultarCentralContratacoes.ts` | Há limites em partes das consultas, mas filtros podem acontecer após a leitura e há enriquecimento por entidade. Levar filtros compatíveis para o servidor e definir paginação consistente, sem vender subtotal truncado como total |
| Média | Busca/mapa — `fornecedor_localizacao_remote_datasource.dart` | Há snapshots globais de fornecedores, médias e vínculos; montagem de serviços acrescenta leituras por categoria/serviço. Consultar por região/categoria e reutilizar uma projeção resumida dos resultados |
| Média | Recomendações — `fornecedorRecomendacaoService.ts` | Há leitura global de vínculos e candidatos; parte do histórico já tem limite de 300. Criar filtros/indexação de candidatos antes do ranking e cache com invalidação definida |
| Média | Ranking — `ranking_remote_datasource.dart` | Baixa os vínculos da subcategoria e ordena localmente. Após normalizar a projeção verificada, consultar ranking ordenado e paginado no servidor |
| Média | Gastos — `orcamento_gasto_remote_datasource.dart` | Ao adicionar gasto, relê gastos de todos os orçamentos do evento. Agregar totais transacionalmente por orçamento/evento; não trocar a conferência financeira por leitura limitada |
| Média | Catálogos/referências — `catalogo_servico_remote_datasource.dart`, `uf_cidade_remote_datasource.dart`, `tema_festa_remote_datasource.dart` | Leituras de dados pouco mutáveis podem se repetir em formulários. Avaliar cache de referência com prazo, invalidação após edição e separação dos dados por sessão quando houver autorização privada |
| Média | Inspirações/comunidade | Existem snapshots de coleções completas. Introduzir paginação e filtros de publicação, encerrando listeners fora da tela quando não forem necessários |
| Menor | Eventos/convidados/tarefas | Há consultas por usuário/evento e algumas buscas de um único documento com `limit(1)`. Preservar essas delimitações; paginar históricos grandes conforme o uso real |
| Monitorar | Estatísticas públicas — `obterEstatisticasPublicas.ts` | Já usa contagem de eventos e cache de cinco minutos por instância, mas ainda lê reputação dos fornecedores ao renovar. Em escala, usar agregado persistido e evitar renovação simultânea do cache |
| Monitorar | Auditoria e expurgo | Triggers acrescentam gravações e podem buscar vínculos. O expurgo diário já limita o lote a 400. Preservar rastreabilidade e retenção; medir amplificação antes de mudar a política |

Os timers encontrados também foram conferidos. O timer de um minuto do painel **só marca os dados como desatualizados**; não faz polling no Firestore. Outros timers identificados cuidam de animação, contagem de tempo, MFA ou atualização do aplicativo, e não devem ser classificados automaticamente como consultas ao banco.

O catálogo de serviços por fornecedor já reúne identificadores em lotes de até 30 para algumas buscas. A calculadora contextual já possui uma proteção de 501 documentos para detectar excesso em vez de truncar silenciosamente. A auditoria já usa limites e cursores em parte dos caminhos. Essas proteções foram preservadas.

## Como o consumo pode virar cobrança

Firestore cobra documentos, entradas de índice em consultas aplicáveis, armazenamento e tráfego. A franquia publicada inclui 50 mil leituras diárias em um banco elegível por projeto. Uma consulta que devolve muitos documentos continua tendo muitas leituras; `count()` reduz o transporte e é cobrado conforme entradas de índice. Listeners podem gerar novas leituras em atualizações e reconexões. Referência: [cobrança oficial do Firestore](https://firebase.google.com/docs/firestore/pricing).

Cloud Run depende de execução, memória, CPU, requisições e configuração de cobrança. Não se deve converter segundos de instância diretamente em reais sem esses dados. Referência: [preços do Cloud Run](https://cloud.google.com/run/pricing).

Também é necessário acompanhar armazenamento de imagens/artefatos, builds, logs e serviços externos. Foram encontrados repositórios `gcf-artifacts` em São Paulo e `us-central1`, mas seu tamanho/custo não foi medido. Nenhuma imagem foi apagada. Function em São Paulo e Firestore em `nam5` continuam distantes; nenhuma região ou instância mínima foi alterada.

Para controlar gastos, o próximo controle operacional é um orçamento com alertas no Billing e análise por serviço/SKU. Um orçamento do tipo somente alertas comunica o consumo; sua criação não equivale a desligar recursos. O valor do orçamento não foi definido nesta tarefa. Referência: [orçamentos e alertas oficiais](https://docs.cloud.google.com/billing/docs/how-to/budgets).

## Validação

- **54 testes Flutter aprovados**, incluindo concorrência, sessão, filtros, invalidação após gravação, contagens com registros legados, painel, primeira resposta, comissão, repasse e caixa. [Saída](evidencias_validacao/consultas-cloud-2026-11-04/testes-flutter.txt).
- **Build TypeScript aprovado** (`npm --prefix functions run build`).
- **Quatro suítes no Firestore Emulator aprovadas**: economia de consultas, contratos financeiros, planejamento e painel. A suíte instrumentada confirmou uma leitura de cada consulta de contratos/comissão/repasses/custos/recebimentos/movimentos por resumo, preservando R$ 3.150,00 contratados, R$ 2.992,50 líquidos e R$ 1.992,50 pendentes após repasse de R$ 1.000,00.
- A suíte de planejamento tinha uma comparação de vencimento dependente do dia real: uma conta com vencimento em 31/10 passou a estar vencida em novembro. O teste agora injeta a data da fixture (26/10/2026). A lógica de vencimento da aplicação não foi alterada.
- Análise estática dos arquivos alterados e novos testes sem problemas. [Saída](evidencias_validacao/consultas-cloud-2026-11-04/analise-estatica.txt).

Os testes usam dados sintéticos e projetos `demo-*`. A CLI exigiu Java 21 ou superior; foi utilizado o JRE 25 já instalado apenas no ambiente dos comandos de teste. Nenhuma instalação ou configuração global foi modificada.

As reduções acima foram verificadas no código e nos testes. Ainda não há comparação de consumo antes/depois no ambiente hospedado, porque as mudanças não foram publicadas. A economia em produção deve ser medida após a publicação do aplicativo e das Functions afetadas. A revisão geral não encerra os itens estruturais da matriz.
