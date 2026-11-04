# 08 — Vencimentos, projeção de caixa e resultado por evento

Implementação local em 26/10/2026 (America/Sao_Paulo), Windows/PowerShell. Não houve deploy, commit, push, operação financeira real, migração ou escrita em produção. Dados sintéticos em projetos demo do Firestore Emulator.

## Inspeção e decisões

Foram lidos Git e os serviços/controladores de contratos, resumo, recebimentos, custos, obrigações, liquidação, comissões e repasses. Não foram encontrados AGENTS.md aplicáveis no repositório/ancestrais. A árvore já continha alterações extensas, preservadas.

A base anterior distingue contas_receber (fatos de recebimento próprio) de repasses da plataforma. Não foram inseridas previsões nessa coleção: isso faria previsões virarem caixa. A nova leitura deriva o recebível do mesmo contrato canônico e do saldo líquido atual. Reutiliza contas_pagar para obrigações privadas, custos_internos para custos, movimentos_caixa para desembolsos e financeiro_auditoria para autoria/histórico. Configuração e previsões privadas ficam em financeiro_planejamento/principal, sem outro livro financeiro.

O resumo anterior partia da receita bruta e deduzia a comissão separadamente. Na normalização para receita econômica líquida, foi explicitada a base para não deduzir comissão novamente no realizado. O teste compara também a callable de resumo existente. O resumo incorpora os agregados de caixa/resultado da leitura de planejamento, inclusive componentes privados persistidos, preservando o contrato de resposta anterior.

O cadastro anterior de custo foi tornado transacional: custo, obrigação vinculada (quando informada) e auditoria no mesmo commit. Chave divergente é recusada. O controller antigo preserva chave/payload para retries e reabertura; a retomada não gera outro custo. O carregamento dessa pendência não bloqueia a recuperação de recebimentos existente.

## Fluxo entregue

A rota `/fornecedor/planejamento`, acessível no financeiro privado, oferece:

- Contas a receber derivadas do contrato; contas a pagar privadas; original, baixas parciais, saldo, origem, evento/contrato, vencimento e situação.
- Cadastro de despesa prevista ou incorrida, pagamento parcial, estorno referenciado, alteração de vencimento e ajuste de custo previsto/incorrido, com autoria, motivo, revisão/idempotência e histórico.
- Previsão de recebimento por contrato (plataforma ou externo), informada explicitamente pelo fornecedor. Ausência de data é “sem previsão”, nunca atraso. Repasse autorizado e confirmado são exibidos separadamente; contrato/proposta/pagamento declarado do cliente não é entrada.
- Projeção de variações datadas, valores sem data separados, saldo inicial com data base persistido e saldo informado projetado. Sem base aplicável, não apresenta saldo bancário fictício. Saldo inicial global não é atribuído a um evento filtrado.
- Resultado direto previsto/realizado por evento e consolidado, separado do caixa; bruto, deduções contratuais, custos previstos/incorridos, outras deduções privadas, recebido e pendente. Campos desconhecidos permanecem nulos e resultados conhecidos são identificados como parciais quando faltam componentes. Não há promessa de lucro líquido.
- Exportação CSV da mesma consulta filtrada e revisão, com origem, geração, grau/situação, identificadores, valores em centavos, componentes do resultado e liquidações. Não há uma segunda consulta com escopo maior para exportar.

Os formulários têm revisão humana e usam centavos inteiros explicitamente identificados. Há loading, vazio, erro com retry, envio pendente e proteção contra sessão antiga; largura de 360 pixels foi exercitada. Exportação usa o padrão existente Share/XFile para um arquivo CSV; não envia automaticamente para destinatários.

## Reconciliação e reconhecimento

A leitura do planejamento usa uma única transação de leitura, incluindo a visão contratual existente (agora reutilizável com Transaction externa), custos, recebimentos, movimentos, obrigações, comissão e configuração. Falha de consulta não é substituída por lista vazia ou zero. A revisão identifica as fontes lidas; o CSV é produzido a partir do mesmo objeto.

Recebimento e seu espelho em movimentos contam uma única vez. Repasse vem de plataforma_repasses, sem reaproveitar um lançamento privado como outro repasse. Recebimento externo permanece declaração do fornecedor, sem fabricar confirmação bancária. Liquidação manual de comissão separada mantém a origem de registro manual da plataforma e não é rotulada como confirmação bancária.

A receita econômica realizada segue o aceite de execução existente; pagamento parcial não realiza serviço. A comissão do fornecedor é incorporada uma vez à base econômica líquida. Pagamento separado reduz a retenção no direito a repasse, mas não elimina o custo econômico da comissão. Comissão paga pelo cliente/absorvida pela plataforma não reduz automaticamente o resultado do fornecedor. Retenção no repasse não cria outro desembolso de caixa, pois o repasse já é líquido.

Custo incorrido é separado de obrigação e pagamento. Consumo de estoque adquirido antes permanece custo sem novo desembolso. Compra de estoque pode gerar conta a pagar, sem virar automaticamente custo de evento. Um registro de consumo com desembolso contraditório ou espelho de recebimento inconsistente bloqueia o relatório para conferência; não é escondido por uma soma alternativa.

Pagamento de obrigação grava a liquidação, atualiza pago_liquido e cria um movimento de caixa e auditoria atomicamente. Não aumenta novamente valor_desembolso do custo original. Estorno referencia uma baixa, limita a reversão ao valor ainda reversível e mantém todos os registros. Ajuste de custo não movimenta caixa e exige revisão/motivo; custo gerado por consumo deve ser ajustado na origem de estoque.

Custos legados com valor_obrigacao mas sem conta vinculada aparecem identificados, sem criar dívida duplicada. Conta antiga marcada paga/parcial sem valor de baixa mantém baixado/saldo nulos; não é convertida em obrigação integralmente aberta ou em zero confirmado, e nova baixa é bloqueada até conferir a origem. Há comando explícito de vínculo, sem inventar pagamentos nem migrar dados automaticamente. Desembolso legado de custo é reconhecido uma vez; vínculo explícito com movimento duplicado é tratado como inconsistência a reconciliar.

## Filtros e datas

Evento restringe os fatos ao fornecedor e ao vínculo informado. Período inclusivo usa: vencimento nas contas, ocorrência do fato no caixa (America/Sao_Paulo) e data do evento nos resultados. Resultado de um evento agrega seus componentes de vida do contrato, não apenas custos lançados no mês. Situação filtra somente contas, como indicado na interface. Registros sem data continuam separados e não são considerados vencidos; movimentos sem data não são atribuídos arbitrariamente a um período.

Saldo inicial exige data base; projeção a partir dele considera movimentos posteriores à base. Base posterior ao início do período é identificada como fora da base aplicável. Num filtro de evento, o saldo inicial da empresa é “não aplicável”. Previsões sem data não entram artificialmente em um dia do calendário.

## Acesso, CSV e persistência

Somente o fornecedor da sessão consulta/comanda seu planejamento. Cliente, outro fornecedor e administrador não recebem acesso geral aos custos, contas, baixas ou configuração. Acesso ao contrato para vinculá-lo é revalidado. Metadados de evento não são lidos a partir de um custo privado arbitrariamente vinculado: é necessário contrato do fornecedor nesse evento.

Regras removem escrita direta sobre custos/contas a pagar e suas liquidações e excluem financeiro_planejamento das permissões genéricas sobrepostas. As escritas passam pelas callables; datas, autoria e auditoria vêm do backend. Dados privados não são colocados no evento ou contrato compartilhado.

CSV usa UTF-8/BOM, separador ponto e vírgula, aspas/escape de aspas e CRLF. A primeira linha registra geração/fuso; a segunda contém os nomes de coluna. Textos iniciados por sinais de fórmula, incluindo espaços/controles antes de =, +, - ou @, recebem apóstrofo. Valores numéricos negativos legítimos permanecem números. Tipos de linha distinguem contas, movimentos, resultados, consolidado e liquidações: não se somam seções diferentes como se fossem caixa.

## Arquivos principais

Backend: planejamentoFornecedorService.ts (novo); visaoFinanceiraContratoService.ts (leitura transacional compartilhada); comandosFinanceiroFornecedor.ts (custo atômico e integração do resumo); resumoFornecedorService.ts (base líquida explícita no realizado); functions/src/index.ts; firestore.rules.

Flutter: planejamento_financeiro_controller.dart e planejamento_financeiro_page.dart (novos); financeiro_fornecedor_controller.dart (retomada de custos); financeiro_fornecedor_page.dart (entrada e configuração persistida); app_routes.dart.

Testes: functions/scripts/testPlanejamentoFornecedorEmulator.js; test/features/planejamento/planejamento_financeiro_test.dart; comando test:planejamento:fornecedor em package.json; este documento.

## Verificações reais

JDK 21 local em `$env:TEMP/codex-chat-jdk/jdk-21.0.12.1+1`, JAVA_HOME/PATH somente do processo. Firebase CLI no projeto demo-planejamento-fornecedor.

1. `npm --prefix functions run build`: TypeScript estrito compilou.
2. `npm --prefix functions run check:financeiro`: passou, com domínio financeiro/estoque/comissão, conciliação e autorização. Log: `$env:TEMP/planejamento-financeiro-check.log`.
3. `flutter test test/features/planejamento test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/financeiro/recebimentos_caixa_idempotencia_test.dart --reporter expanded`: **29 testes passaram**, incluindo os widgets novos, filtros/exportação, sessão, erro/retry, largura de 360 pixels, retomada após timeout de custos e regressão de contratos/recebimentos. Log: `$env:TEMP/08-flutter-final.log`.
4. `dart analyze` dos controllers/páginas alterados, rotas e testes de planejamento: **No issues found**. Log: `$env:TEMP/08-analyze-final.log`.
5. Integração real no Firestore Emulator: **passou**. R$3.150,00 bruto, R$157,50 comissão e R$1.000,00 custo previsto produziram **R$1.992,50 de resultado direto previsto**, parcial sem componentes declarados. Repasse confirmado R$1.000,00 e desembolso R$400,00 produziram **R$600,00 de movimento líquido**, sem duplicidade.
6. Também passaram: quatro envios concorrentes da mesma baixa; payload divergente; estorno parcial e excesso recusado; vencida versus sem data; saldo inicial; filtro de evento/período/situação; comissão adicionada/absorvida/paga separadamente; ajustes de custo com revisão; consumo de estoque sem desembolso; recebimento externo com espelho; custo/obrigação atômicos; vínculo legado; paridade de linhas/valores do CSV com o relatório e escape de fórmulas.
7. A rodada final `npm run test:planejamento:fornecedor` passou com **código 0** após todas as alterações. Incluiu paridade do resumo existente com dedução privada persistida, contas legadas pagas sem valor de baixa (nulos, sem nova baixa automática), bloqueio de desembolso indevido em consumo, espelho órfão e caixa histórico de comissão após cancelamento. Log: `$env:TEMP/08-emulador-entrega-final.log`. `git diff --check` nos arquivos do escopo também passou.
8. Regras reais via SDK no emulador: leitura negada a cliente/outro fornecedor/admin; dono lê configuração; escrita direta de configuração, baixa, custo e liquidação negada. Foram executadas **14 asserções de regras** dentro da integração, além das verificações de autorização do backend. PERMISSION_DENIED nos logs são esperados nos testes negativos.

As primeiras rodadas identificaram fixtures sem base de comissão/fornecedor, formatação monetária duplicada e carregamento de custo pendente bloqueando a recuperação de recebimentos. Foram corrigidos os dados sintéticos e a implementação; não foram relaxadas autorizações nem transformados erros em zero. A retomada de custo é testada separadamente e não bloqueia a consulta normal.

## Compatibilidade e limites

Não foi necessário índice composto novo: as consultas novas usam igualdade por obrigação/contrato e subcoleções existentes. Não houve backfill ou migração de produção. Configuração privada é versionada e persistida; o formulário antigo de deduções direciona ao novo fluxo persistente.

O protocolo anterior de resumo é preservado; quando componentes não estão disponíveis, continua identificado como parcial e mantém seus campos numéricos legados de subtotal. O novo planejamento/CSV distingue explicitamente nulo de zero e é a visão detalhada de componentes, vencimentos e base de saldo. Não há cálculo de lucro líquido contábil, conciliação bancária automática, juros/multas automáticos ou previsão de repasse sem data registrada.

Os testes integram Firestore real emulado e implementações de serviços/callables; widgets usam doubles para timeout/sessão/exportação. Não foi executado teste manual no aplicativo Windows instalado nem compartilhamento por uma plataforma real, ciclo HTTPS com Auth hospedado, deploy ou produção. A exportação foi validada pelo conteúdo gerado e pelo acionamento do fluxo com o CSV da consulta.
