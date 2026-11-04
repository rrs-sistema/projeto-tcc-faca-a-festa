# 02 — Unificação financeira por contrato e repasses

Implementação e validação local em 26/10/2026. Sem deploy, commit, push, operação bancária, migração ou acesso a produção.

## Estado inicial e diagnóstico

AGENTS.md procurados na árvore do projeto e nos ancestrais: nenhum encontrado. Git inspecionado antes das edições. Havia trabalho em andamento de comissão, retenção, liberação de repasses, mediação e outras áreas; foi preservado e reutilizado. O Prompt 01 também permanece no checkout.

Confirmado: consultarResumoFinanceiroFornecedor usava bruto dos orçamentos e recebimentos privados agregados por evento; a lista repetia recebimentos em cada contrato do evento. listarAcompanhamentoFornecedor usava taxa fixa de 500 bps e modo descontada_fornecedor. A implementação local de divisaoContrato já conciliava valor liquidado por retenção e separadamente; portanto a simples apresentação da comissão como a vencer não provava cobrança duplicada.

## Arquitetura e identidade

visaoFinanceiraContratoService é uma projeção de leitura, sem coleção ou livro financeiro novo. Identidade: contrato_financeiro.id_contrato, com fallback para o ID do orçamento legado. Espelhos com essa identidade são contados uma vez; valores brutos conflitantes tornam a consulta indisponível para conferência. Repasses de todos os IDs de orçamento associados são reunidos. A listagem de intermediação também normaliza espelhos antes de agregar.

Fontes:

| Fato | Fonte existente |
| --- | --- |
| Contratação/bruto/estado | orcamento e contrato_financeiro |
| Comissão contratada, pagador, taxa, ajuste e liquidação | plataforma_comissao_obrigacoes / politica_aplicada |
| Retenção realizada | liquidado_por_retencao_repasse_centavos e plataforma_comissao_liquidacoes |
| Repasse autorizado/processando/confirmado | plataforma_repasses |
| Declaração própria | fornecedor/{uid}/contas_receber |
| Movimentos e custos privados | fornecedor/{uid}/movimentos_caixa e custos_internos |
| Declaração do cliente à plataforma | permanece nas fontes da plataforma; não entra como repasse do fornecedor |

A projeção pública do contrato é lida em transação de leitura. Resumo e acompanhamento usam essa mesma projeção e a mesma divisaoContrato já utilizada pela liberação/intermediação. A revisão financeira deriva dos updateTimes de contrato, obrigação e repasses. revisaoComissao é compartilhada com o extrato da obrigação. Geração, liquidação e ajustes de comissão incrementam repasse_revisao no orçamento, permitindo atualizar o resumo ao mudar os fatos. Não há recálculo de comissão pela taxa atual da plataforma nem taxa fixa de 5% no acompanhamento persistido.

## Valores, arredondamento e conciliação

Os novos cálculos contratuais e agregações são em centavos inteiros; conversão para reais ocorre na adaptação ao DTO existente. Legado em reais usa Math.round(reais * 100). Comissão segue a política registrada, incluindo ajustes: não é recalculada por conveniência da interface.

- Fornecedor como pagador: valor líquido destinado ao repasse = bruto menos comissão ainda reservada no contrato. Parte paga separadamente restaura essa parte do direito ao repasse, sem retirar o custo econômico total da comissão do resultado previsto.
- Organizador como pagador: comissão adicionada ao cliente não reduz o direito do fornecedor.
- Plataforma absorve: comissão não reduz o fornecedor nem aumenta automaticamente o preço do cliente; modo incluído no domínio TS/Dart.
- Outras deduções contratuais: o modelo atual inspecionado só possui a comissão. A interface informa que não há outras deduções registradas; estimativas privadas de taxas/tributos/custos não são inventadas como deduções do repasse.
- Pendente líquido = máximo de zero e direito previsto para repasse menos repasses confirmados. Autorizações/processamento não viram recebimento.
- Declaração própria e pagamento declarado pelo cliente não são confirmação bancária e não diminuem automaticamente esse saldo de repasse.

Retenção passa a ser proporcional cumulativa aos repasses confirmados. Meta = Math.round(comissão reservada × fração acumulada do direito já repassado); cada parcela registra apenas o incremento em relação ao já retido. O último repasse absorve o resíduo de arredondamento, e o valor é limitado ao saldo real da obrigação. Cada retenção mantém repasse, autor, origem, data e registro_manual/confirmacao_bancaria=false. Não há baixa duplicada por parcela. Pagamento separado e retenção compartilham o mesmo saldo e a mesma transação; uma liquidação acima do saldo após retenções é recusada. Idempotência de confirmação de repasse permanece preservada.

O teste de repasse operacional preexistente verificava uma única linha de retenção por comissão, mesmo com parcelas. Foi atualizado para a política proporcional: duas linhas nas duas parcelas, com soma igual à comissão única. A conferência de valor total e a proteção contra duplicidade foram mantidas e reforçadas.

## Recebimentos próprios e custos privados

Novos recebimentos próprios recebem id_contrato e id_orcamento validados contra o fornecedor/evento. A tela oferece seleção da contratação. Sem seleção, o backend só aceita quando existe uma única contratação elegível no evento; ambiguidade é rejeitada. Dados legados sem vínculo não são distribuídos entre contratos. O total declarado continua disponível separadamente, e os documentos/histórico anteriores permanecem intactos.

Declaração e espelho de movimento são gravados atomicamente com a mesma chave. Repetições concorrentes não criam dois fatos; reutilização da chave com outro evento/valor é rejeitada. A origem do novo movimento é recebimento_proprio_declarado, com autor e confirmacao_bancaria=false. O novo resumo conserva separado o repasse confirmado, sem transformar esses registros próprios em confirmação bancária.

Custos permanecem nas coleções privadas existentes e compõem custos/resultados privados. Não são transportados à visão do organizador, ao extrato de comissão nem à intermediação administrativa. A autorização da callable de resumo continua exigindo UID proprietário; organizador e administrador com outro UID são recusados. As regras privadas existentes foram testadas sem ampliação.

## Apresentação e disponibilidade

Resumo, lista e acompanhamento mostram bruto, comissão, líquido previsto, autorização, confirmação e pendência conforme as mesmas fontes. A lista mantém contratos cancelados como histórico, sem criar nova previsão líquida para eles; repasses confirmados anteriores continuam registrados. Cancelar/estornar não apaga contrato, retenção, repasse, autoria nem ajustes. Créditos de comissão após estorno são explícitos e não geram transferência ou devolução bancária fictícia.

Extrato/detalhe de comissão distinguem retenção realizada, pagamento separado e saldo previsto para retenção. O rótulo previsto para retenção substitui a leitura equivocada de uma segunda cobrança a vencer; a interface explica que pagamento separado reduz a retenção. O status persistido e os documentos originais são preservados.

O controller deixa de sobrescrever a projeção canônica com cálculo local bruto. Listeners privados solicitam atualização da projeção; geração da consulta e UID descartam resultados antigos. Falha da callable, política/obrigação ausente ou inconsistente e falha das consultas de acompanhamento não são convertidas em zero. Valores do resumo/lista são limpos e a tela mostra consulta indisponível. Respostas de versões antigas sem origem contratos_repasses também são recusadas para evitar voltar ao bruto silenciosamente.

Não foram inventadas datas, garantias ou responsáveis de pagamento. O acompanhamento consulta a política de liberação ativa existente. A retenção prevista não é apresentada como liquidação realizada.

## Validação executada

JDK 21 temporário da validação do Prompt 01, aplicado somente ao processo PowerShell:

```powershell
$env:JAVA_HOME=Join-Path $env:TEMP 'codex-chat-jdk/jdk-21.0.12.1+1'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
npm run test:financeiro:contratos
npm --prefix functions run check:financeiro
flutter test test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/financeiro/financeiro_fornecedor_test.dart test/features/financeiro/comissao_plataforma_test.dart test/features/financeiro/acompanhamento_partes_test.dart test/features/financeiro/comissoes_responsivas_test.dart
```

O script npm novo compila TypeScript e executa, no emulador, testVisaoContratoEmulator.js, financeiro_fornecedor.rules.test.js, comissao_plataforma.rules.test.js e testRepasseOperacionalEmulator.js.

Resultados finais:

- Integração real em Firestore Emulator, projeto demo-financeiro-contratos: aprovada, exit 0. Usa Admin SDK, callables .run e serviços reais compilados; não substitui persistência por mocks.
- Caso de aceite: bruto 315000, comissão 15750, líquido 299250 centavos. Repasse real confirmado de 100000 deixa 199250. Assertivas comparam resumo, lista, acompanhamento e intermediação. A revisão de resumo/acompanhamento e a revisão da comissão no extrato são conferidas.
- Modos adicionada ao cliente e absorvida pela plataforma: direito 315000, sem desconto indevido. Retenção parcial/integral, pagamento separado e misto: aprovados. Tentativa de pagar comissão já liquidada: recusada.
- Declaração do cliente não altera recebido. Declaração própria fica vinculada, separada e não é repetida em outro contrato do mesmo evento. Repetição concorrente da mesma declaração e rejeição de chave conflitante/contrato ambíguo: aprovadas.
- Espelho do mesmo contrato, orçamento legado em reais, cancelamento com histórico de repasse preservado, ajuste de estorno real com crédito e autor preservados, obrigação ausente e acessos indevidos ao resumo privado: aprovados.
- Regras: custos privados só do dono; organizador/admin não leem. Extrato de comissão limitado ao pagador autorizado. A suíte operacional adicional cobre autorização/finalização do evento, retenção, mediação, concorrência, idempotência, pagamento separado parcial/integral e regras de escrita.
- Flutter: **30 testes aprovados**, exit 0. Inclui nova apresentação em 360/1200 px, resumo/lista com 2992,50 e 1992,50, indisponibilidade sem zero, separação da comissão e regressões de fornecedor/acompanhamento/comissão e responsividade. Esses testes usam doubles nas bordas de UI, complementados pela integração real acima.
- dart analyze nos 12 arquivos Dart alterados deste escopo: **No issues found**, exit 0.
- dart format executado. git diff --check do escopo executado sem erros.
- Uma tentativa inicial de widget test ficou aguardando cancelamento de streams no relógio virtual; o teste passou a aguardar a operação pelo runAsync do framework. Um overflow real em 360 px foi corrigido com restrição de largura e métricas em grade; reexecução aprovada.

## Índices e compatibilidade

Sem novas coleções ou índices compostos. As consultas novas usam índices simples existentes em id_fornecedor, id_contrato, id_orcamento e contrato_financeiro.id_contrato. Nenhum índice foi publicado. O adaptador preserva orçamento legado sem contrato_financeiro, usando seu próprio ID, e corrige fallback de valor legado quando existe snapshot parcial sem valor. Sem comissão contratada verificável não se presume 5% nem comissão zero: a consulta fica explicitamente indisponível.

## Arquivos deste prompt

Backend: comandosFinanceiroFornecedor.ts; comandosComissaoPlataforma.ts; resumoFornecedorService.ts; visaoFinanceiraContratoService.ts (novo); acompanhamentoPersistenciaService.ts; acompanhamentoPartesService.ts; comissaoPlataformaService.ts; intermediacaoPersistenciaService.ts; intermediacaoFinanceiraService.ts; dashboardAdminService.ts.

Flutter: domain/entities/financeiro/intermediacao_financeira.dart; domain/services/intermediacao_financeira_service.dart, acompanhamento_partes_service.dart e resumo_financeiro_fornecedor_service.dart; controllers financeiro_fornecedor_controller.dart e comissao_plataforma_controller.dart; páginas financeiro_fornecedor_page.dart, acompanhamento_fornecedor_page.dart e comissao_plataforma_page.dart; widgets comissao_detalhe.dart e comissao_modal.dart.

Validação: functions/scripts/testVisaoContratoEmulator.js (novo); functions/scripts/testRepasseOperacionalEmulator.js (alteração pontual no teste preexistente); test/features/financeiro/financeiro_contratos_unificado_test.dart (novo); package.json (script adicionado); este documento.

## Limites do resultado

Sem execução bancária automática: confirmado é o estado operacional já existente com confirmação manual e evidências, não um novo comprovante de integração bancária. Não houve teste em produção ou aplicativo instalado. Totais líquidos ficam indisponíveis se houver contratação ativa com comissão inconsistente, em vez de mostrar total parcial como completo. A projeção lê todo o conjunto do fornecedor, sem truncar em 100 contratos; custo/tempo de leitura cresce com esse conjunto. Não há migração silenciosa de registros legados ambíguos nem transferência automática em estorno. Publicação das regras/Functions/aplicativo está fora da autorização recebida.

Conferência adicional final: npm --prefix functions run check:financeiro concluiu com exit 0 (tsc --noEmit e suítes financeiras de Functions). Após ajustar o indicador do acompanhamento para não dizer comissão descontada quando ela foi integralmente paga separadamente, o build TypeScript e testVisaoContratoEmulator.js foram reexecutados com sucesso. O teste verifica explicitamente esse indicador no caso de pagamento separado.
