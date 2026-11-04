# Comparação do aplicativo atual com a documentação

Data do levantamento: 29/10/2026. Referência de comparação: documentação consolidada da edição 2, acervo acadêmico original e documentação arquitetural de setembro de 2026. O estado examinado inclui alterações locais preexistentes, inclusive arquivos ainda não versionados. A análise não fez deploy, migração, commit ou alteração das regras de negócio.

## Conclusão

A mudança é significativa. O produto atual reúne organização de eventos, planejamento de alimentação e operação comercial e financeira de fornecedores. A edição 2 descreve esses temas de forma geral, mas não documenta adequadamente a profundidade do planejador, privacidade, identidade, estoque e processos operacionais. A descrição antiga de CRUD de eventos e calculadora com recomendações de IA é insuficiente para explicar o sistema atual.

A descrição arquitetural também precisa ser tratada como aplicação parcial de princípios: contratos e camadas coexistem com dependências entre apresentação e dados e utilização de GetX em gateways. A revisão anterior do capítulo 8 já explicitou parte dessas diferenças; este levantamento estende a comparação a todos os 21 diretórios funcionais de apresentação.

## Método e limites

O levantamento percorreu a estrutura de lib, os imports e exports, as rotas nomeadas, a composição da aplicação, os exports de backend, as regras de acesso e os testes. Foram lidos componentes de identidade, evento, convidados, cardápio, planejamento, execução, fornecedor, agenda, financeiro, reputação, privacidade, comunidade, ranking, temas e inspirações. Os fluxos centrais foram relacionados a controllers, contratos, datasources e serviços de backend. O inventário reproduzível está em inventario.json, gerado por ../inventariar_aplicativo.py.

O método oferece cobertura de todos os módulos na comparação funcional e aprofundamento em fluxos críticos. Não representa leitura semântica de cada linha gerada, certificação de segurança, teste manual de cada tela, avaliação jurídica ou confirmação atual do ambiente publicado. A existência de rota, função ou teste não comprova, isoladamente, uma jornada autenticada em produção.

Foram executadas novas verificações automatizadas do cliente e do backend. Seus resultados e limites constam ao final deste relatório. As capturas já existentes mantêm a identificação de widgets com dados sintéticos.

## Dimensão do estado atual

| Indicador estático | Resultado | Interpretação |
| --- | ---: | --- |
| Arquivos Dart em lib | 854 | Inclui gerados e os dois arquivos diretamente na raiz |
| app | 44 | Composição, rotas, inicialização e temas da aplicação |
| core | 36 | Infraestrutura e recursos transversais |
| data | 207 | Infraestrutura, modelos e implementações |
| domain | 234 | Entidades, contratos, casos de uso e serviços |
| presentation | 331 | Módulos, controllers, telas e widgets |
| Diretórios funcionais de UI | 21 | Não equivale a 21 telas ou a 21 produtos independentes |
| Declarações de nome encontradas em app_routes.dart | 43 | Inclui rota de fallback; não cobre navegação criada diretamente por widgets |
| Identificadores exportados por functions/src/index.ts | 139 | Inclui callables, triggers e outros exports; não equivale a 139 funções publicadas |
| Arquivos de teste Dart em test | 173 | Não equivale à quantidade de casos executados |
| Arquivos em integration_test | 16 | Não incluídos automaticamente na execução flutter test da pasta test |
| Nomes literais encontrados em chamadas collection | 95 | Mistura raiz e subcoleções; não é contagem de coleções do banco |

O inventário arquitetural de setembro documentava 152 arquivos de domínio, 176 de dados, 233 de apresentação, 40 de app e 23 de core. O levantamento atual encontrou 234, 207, 331, 44 e 36, respectivamente. São comparações com números de um documento histórico, não uma medição de diffs entre duas releases congeladas. A inclusão de arquivos gerados e as condições do levantamento anterior devem ser consideradas.

## Cobertura dos módulos e divergências

Os caminhos abaixo são relativos à raiz do aplicativo. “Resumido” indica capacidade mencionada na edição 2 sem detalhamento suficiente. “Ausente” refere-se ao tratamento específico necessário, não à inexistência de qualquer menção ao tema.

| Módulo e arquivos | Aplicativo atual e evidência principal | Situação na edição 2 | Atualização necessária |
| --- | --- | --- | --- |
| admin — 17 | Administração de eventos, territórios, orçamentos, dashboard e auditoria; presentation/modules/admin e rotas | Resumido | Relacionar manutenção cadastral, operação financeira e moderação às permissões |
| app — 8 | Sessão, papéis, convite e troca de evento; app_controller e serviços associados | Resumido | Explicar transições de identidade e invalidação de contexto |
| auditoria — 5 | Consultas, detalhe e filtros; functions/auditoria e regras | Parcial | Incluir retenção configurada e distinguir leitura de escrita administrativa |
| auth — 20 | Senha, Google, redefinição, TOTP e MFA por e-mail; LoginController e Functions de auth | Insuficiente | Documentar fluxos e condições sem prometer todos os métodos em toda plataforma |
| avaliacao — 4 | Avaliação verificada, resposta, denúncia, moderação e histórico; services/avaliacoes | Resumido | Separar avaliação, reputação e decisão administrativa |
| calculadora — 52 | Público, configuração, cardápio, catálogo contextual, agenda, proposta, execução, consumo observado, memória e IA; controller com 12 arquivos part | Muito resumido | Descrever planejador híbrido, confirmação e invalidação de propostas |
| catalogo — 18 | Categorias, subcategorias, serviço/produto e fotos; controllers e bootstraps | Parcial | Distinguir catálogo comum e oferta particular do fornecedor |
| checklist — 4 | Tarefas, responsáveis, status e escutas; TarefaController | Parcial | Relacionar tarefas manuais às geradas no planejamento |
| comunidade — 1 | Posts e comentários por contrato de repositório; ComunidadeController | Sem requisito específico | Acrescentar função complementar, autoria e necessidade de validação de acesso |
| convidado — 32 | Grupos, lista, estatísticas, mesas, convites e cardápios; ConvidadosPage e CardapioController | Parcial | Detalhar abas e separar organização de mesa de uma entidade própria no banco |
| cotacao — 4 | Solicitação, proposta, jornada comercial e execução; JornadaAtendimentoController e serviço backend | Resumido | Documentar estados independentes, transições e autoria |
| eventos — 16 | Cadastro especializado, rascunho, vínculo com estimativa e retomada; EventoCadastroController e arquivos part | Parcial | Incluir persistência do cadastro e proteção contra contexto trocado |
| financeiro — 25 | Contratos, custos, caixa, contas, estoque, comissão, previsões, intermediação e mediação | Muito resumido | Diferenciar finanças da empresa, finanças do evento e intermediação da plataforma |
| fornecedor — 48 | Oferta, território, aprovação, painel, indicadores e agenda; FornecedorHomeScreen e painel operacional | Parcial | Explicar o ciclo operacional e a dependência das fontes autorizadas |
| gifts — 3 | Leitura local, sincronização, reserva e contribuições; GiftRepositoryImpl e bootstrap offline | Melhor coberto | Manter limites por operação e plataforma; não generalizar para o produto |
| inspiracao — 15 | Gestão de mídia, referências, favoritos e planejamento associado; controllers e arquivos part | Parcial | Explicar relação com tarefas/orçamento e persistência das referências |
| legal — 11 | Central de dados, política, preferências, protocolos e atendimento administrativo; Functions lgpd | Ausente como módulo funcional | Incluir fluxos sem afirmar conformidade integral ou remoção exaustiva |
| orcamento — 10 | Orçamento e gastos com conferência, além de integração comercial/financeira | Parcial | Distinguir custo estimado, realizado, cobertura e liquidação |
| ranking — 1 | Consulta de ranking por subcategoria; RankingController e datasource | Ausente como requisito específico | Documentar como consulta complementar, sem alegar qualidade estatística |
| tema — 4 | Tema do produto/papel/evento, capa e manutenção de temas; EventThemeController | Resumido | Separar personalização visual de regra de negócio |
| usuario — 10 | Perfil, endereço, CEP, UF/cidade e foto; UsuarioController e bootstraps | Parcial | Incluir integração CEP via backend e escolha de endereço principal |

Todos os caminhos de módulo da tabela ficam em lib/presentation/modules. As quantidades não medem esforço, qualidade ou completude funcional.

## Mudanças de maior impacto documental

### Planejamento deixou de ser uma calculadora isolada

CalculadoraFestaController coordena público, configuração, agenda, catálogo, planejador, operação, personalização, entrada, execução, proposta, análise e histórico. PlanejadorHibridoService retorna proposta principal, alternativa, perguntas, origens e pendências. A aplicação é separada da geração e passa por contratos de repositório e validações de contexto.

Há diferença entre público previsto, lista cadastrada, confirmados, não recusados e escolha manual. A lista tem estado de completude, e a refeição pode ter público próprio. Ocorrências incluem contexto temporal e identidade. O catálogo contextual possui revisão e versão; receitas privadas e consumo observado têm origens diferentes. Quantidade final confirmada não deve ser substituída silenciosamente por sugestão.

Aplicar uma proposta exige revisão e conferência do contexto. A execução integra regras, cardápio, tarefas e necessidades de compra conforme a proposta. Consumo observado e revisão pós-evento são registrados para decisões futuras, sem que isso comprove aprendizado automático ou uma eficácia de IA medida.

Evidências: lib/presentation/modules/calculadora/controllers/calculadora_festa_*.dart; lib/domain/services/planejador_hibrido_service.dart; publico_planejamento_service.dart; plano_execucao_service.dart; lib/data/repositories_impl/calculadora_festa_repository_impl.dart; functions/src/functions/calculadora.

### Operação do fornecedor ganhou processos próprios

O produto representa jornada comercial e execução, agenda com capacidade e recursos, caixa, obrigações e reputação. A agenda distingue horário pendente de compromisso confirmado e relaciona reservas de estoque. Planejamento financeiro inclui comandos de obrigações; não deve ser tratado como simples lista de valores recebidos. A reputação inclui resposta, denúncia, histórico e decisão de moderação.

Evidências: functions/src/services/agenda/agendaFornecedorService.ts; services/cotacao/jornadaAtendimentoService.ts; services/financeiro/planejamentoFornecedorService.ts; services/fornecedores/painelOperacionalService.ts; services/avaliacoes/gestaoReputacaoService.ts.

### Identidade e privacidade têm fluxos próprios

LoginController implementa senha e Google; o backend exporta comandos de TOTP, MFA por e-mail e redefinição por código. O módulo legal permite solicitar tratamento de dados e consultar protocolo, exportar dossiê e ajustar preferências. A execução administrativa é diferente da criação da solicitação. Nada disso deve ser apresentado apenas como uma recomendação futura de proteção de dados.

A implementação de exportação usa limites de consulta; as rotinas de exclusão e anonimização também usam lotes limitados. A documentação precisa informar esses limites e exigir verificação de completude antes de afirmar exportação ou remoção integral. A rotina agendada de auditoria tem corte de 365 dias e processa até 400 registros por execução diária; isso não comprova que todo registro vencido seja removido exatamente no aniversário de 365 dias.

Evidências: lib/presentation/modules/auth/controllers/login_controller.dart; lib/presentation/modules/legal; functions/src/functions/lgpd/exportarDossieTitular.ts; atenderSolicitacaoLgpd.ts; expurgarAuditoriaAntiga.ts.

### Persistência local vai além de presentes sem equivaler a offline integral

Além do banco de presentes, existem rascunhos de cadastro e calculadora e persistência de comandos pendentes por usuário. RecebimentoPendenteLocalStore preserva operação e chave e evita substituição indevida por outra pendência. Isso apoia retomada e idempotência, mas não torna uma operação financeira válida sem confirmação do backend. Drift Web usa SQLite/Wasm e recursos específicos do navegador.

Evidências: lib/data/local; lib/core/database/database_web.dart; lib/app/bootstrap/gift_offline_bootstrap.dart.

## Achados que impedem afirmações amplas na banca

| ID | Achado e evidência | Impacto na documentação | Tratamento recomendado |
| --- | --- | --- | --- |
| AD01 | firestore.rules permite leitura de evento e de subcoleções genéricas para signedIn() | “Todo dado do evento é visível apenas ao dono” não corresponde à regra local | Classificar campos compartilháveis e privados e revisar política desejada; não inferir autorização apenas da tela |
| AD02 | Exportação e exclusão LGPD usam limites e consultas sem varredura exaustiva demonstrada | Não afirmar portabilidade ou apagamento total garantidos | Testar volumes acima dos limites e revisar paginação, remanescentes e tratamento de falhas |
| AD03 | Auditoria tem expurgo diário de até 400 registros vencidos | Retenção configurada não equivale a prazo máximo de remoção comprovado | Medir fila, taxa de entrada e conclusão dos lotes |
| AD04 | Imports entre presentation/data, GetX em gateways e NumericInput com Flutter usado por domain | Clean Architecture integral não é demonstrada | Documentar exceções e priorizar contratos e utilitários puros |
| AD05 | Scripts de lint do backend apenas imprimem Skipping lint | Sucesso de lint não representa análise efetiva | Utilizar TypeScript e verificações que realmente executam; corrigir o script em trabalho específico |
| AD06 | Runtime declarado Node 22, execução local dependente do Node instalado | Resultados podem ser sensíveis ao ambiente | Registrar versões e repetir no ambiente de referência para homologação |

AD01 é constatação da política estática local, não demonstração de exploração em produção. AD02 e AD03 indicam limites do algoritmo e necessidade de completude, não uma certificação ou parecer jurídico. Não foram executadas operações de exclusão, cobrança ou repasse real.

## Atualizações aplicadas ao relatório

A edição seguinte amplia escopo, requisitos, dados e descrição funcional; incorpora identidade, privacidade, planejamento e operação; diferencia as persistências locais; registra inventário atual e resultados das novas verificações. O acervo de proposta original permanece como histórico. O índice arquitetural de setembro continua identificado como histórico e não deve ser usado para contagens atuais.

O produto deve ser apresentado como plataforma de planejamento e acompanhamento operacional de eventos, com calculadora e IA como parte da jornada. Não se recomenda caracterizá-lo apenas como cadastro de festas ou gerador de estimativas.

## Resultados executados em 29 de outubro de 2026

Ambiente: Windows, Flutter 3.27.2, Dart 3.6.1 e Node 24.12.0. O backend declara Node 22. Logs preservados em logs/ nesta pasta. Não foram usados --update-goldens, deploy ou dados reais para aprovar resultados.

| Comando | Resultado | Interpretação |
| --- | --- | --- |
| flutter test --no-pub --reporter expanded | 996 passaram e 11 falharam; saída 1 | A suíte atual não está integralmente aprovada |
| Mesmo comando apenas nos cinco arquivos com falha | 41 passaram e 11 falharam; saída 1 | As falhas foram reproduzidas; contagens não devem ser somadas à suíte global |
| dart analyze lib test | 1 warning, 4 infos e 0 errors; saída 2 | Sem erro de compilação apontado pelo analisador, mas não é análise limpa |
| npm --prefix functions run build | saída 0 | Compilação TypeScript aprovada |
| npm --prefix functions run check:calculadora | saída 0 | Scripts de calculadora e planejador aprovados |
| npm --prefix functions run check:financeiro | saída 0 | Scripts de domínio financeiro aprovados |

### Falhas reproduzidas

| Arquivo em test/features | Casos | Sintoma observado |
| --- | ---: | --- |
| calculadora/calculadora_decisoes_test.dart | 1 | Esperava ausência de sobreposição financeira; recebeu true |
| calculadora/calculadora_operacao_layout_test.dart | 1 | Controle esperado não encontrado no fluxo de estoque |
| calculadora/calculadora_jornada_base_test.dart | 1 | Elemento de rolagem ou alvo esperado não encontrado |
| calculadora/ergonomia_jornada_test.dart | 1 | Interação de preço/fechamento em paisagem sem o elemento esperado |
| operacao/layout_operacional_test.dart | 7 | Filtro com chave esperada não encontrado e seis divergências de imagem de referência |

Seis falhas são comparações visuais. As diferenças devem ser revisadas para decidir entre regressão e referência desatualizada. Não foram consideradas automaticamente defeito de negócio nem tiveram a referência substituída para “passar”. As outras cinco envolvem decisão financeira ou interação/expectativa de widgets e precisam de diagnóstico específico. A causa raiz de todas as falhas não foi estabelecida neste trabalho documental.

O warning é import não utilizado em homologacao_receitas12_test.dart. Os quatro infos são import desnecessário, chaves de bloco e duas exposições de tipo privado em API de teste. O script de lint do backend é apenas um placeholder e não foi apresentado como validação.

### Limites das verificações

Não foram executados os 16 testes de integration_test em dispositivo, os cenários de emuladores Firestore desta rodada nem uma sessão autenticada completa em produção. Os comandos de backend executados verificam compilação e regras de domínio. Evidências antigas de emulador e publicação foram mantidas como históricas, com suas datas. Não houve correção de código nesta análise.

## Prioridades para homologação e defesa

1. Investigar as 11 falhas reproduzidas, corrigindo código ou expectativa conforme decisão fundamentada, e repetir os recortes afetados.
2. Confirmar a política de leitura de eventos/subcoleções com os responsáveis pelo produto e ajustar os testes de autorização ao comportamento aprovado.
3. Validar exportação, anonimização e exclusão com volume acima dos limites e falhas intermediárias, antes de alegar completude.
4. Homologar uma jornada por perfil na compilação e backend escolhidos, incluindo autenticação, planejamento, contratação, operação e atendimento de dados.
5. Congelar a versão demonstrada, registrar o commit ou snapshot e revisar as capturas e referências correspondentes.

A documentação foi atualizada para descrever o aplicativo encontrado e seus limites atuais. Homologação completa e correção das pendências técnicas são trabalhos distintos da consolidação documental.
