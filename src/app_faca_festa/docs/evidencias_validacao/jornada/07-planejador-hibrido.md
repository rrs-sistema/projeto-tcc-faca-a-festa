# Entrega 07 — Planejador híbrido por serviço

Data local: 19/10/2026. Ambiente Windows, Flutter/Dart, Auth, Firestore e Functions locais. Escopo desta entrega; não representa homologação da jornada inteira.

## Diagnóstico e decisão de negócio

A base já tinha propostas determinísticas, catálogo contextual versionado, memória privada, comparação de consumo, agenda por ocorrência e simulação de perguntas. A tela de proposta ainda aplicava regras localmente; não havia um comando único que confirmasse objetivo, declarações e regras com conferência transacional das fontes. Perguntas de serviço e formato podiam ficar fora das prioridades quando ainda não existiam quantidades para comparar; a opção vazia também podia contar como resposta.

O planejador é por serviço e não possui uma tabela que escolhe menu pelo tipo infantil, casamento, congresso ou retiro. Esses eventos usam a mesma seleção por serviço, formato, obtenção, público, horário/duração e infraestrutura. Sem cobertura, permanece uma pendência com acesso ao editor manual.

Precedência: quantidade final confirmada (inclusive zero); decisão/receita revisada; receita privada recuperada e confirmada; consumo privado compatível oferecido para adoção; referência contextual aprovada; candidato por ID a conferir; pendência. Uma alternativa não substitui receita revisada. Preferência privada não comprova consumo. Histórico aprovado não é atualizado por este comando.

## Implementação vertical

- `lib/domain/entities/contexto_servico_planejador.dart`: contrato por serviço, origem/distribuição do público, agenda, itens/receitas, grupos e destinos, objetivo/infraestrutura, verba e compromissos, versões consultadas e assinatura para reaproveitar respostas.
- `lib/domain/services/planejador_hibrido_service.dart`: recuperação, precedência, proposta principal, alternativa quantitativa compatível, explicações, pendências e cálculo de impacto usando o motor existente. O cálculo recebe as mesmas reservas e o mesmo público nas alternativas; não cria economia ou confiança percentual.
- `prioridade_perguntas_service.dart`, `proposta_refeicao_service.dart`, `proposta_catalogo_service.dart`: decisões que desbloqueiam proposta são prioritárias, resposta vazia é inválida e a simulação refaz a obtenção/origem/infraestrutura. Características como tamanho/papel/rendimento dependem da referência ou receita explícita; não são inferidas pelo nome do evento.
- `referencia_contextual.dart` e `functions/src/services/calculadora/catalogoContextualService.ts`: requisito editorial opcional de infraestrutura, dentro do catálogo versionado já existente. O editor administrativo permite configurá-lo. Sem campo, comportamento anterior preservado.
- `consumo_observado_service.dart` e controller: medições novas registram dimensões adicionais do serviço quando disponíveis. Recuperação exige composição, público proporcional, serviço, receita, unidade, período válido de medição e critérios já existentes de falta/atipicidade. O backend recalcula a mediana, verifica evidências privadas, grupos/destinos, composição e agenda. Preço antigo é descartado. Registros antigos continuam legíveis; ausência das dimensões exigidas não autoriza adoção automática pelo novo comando.
- `lib/domain/repositories/planejador_hibrido_repository.dart`, repositório/datasource existentes e `agenda_servico_remote.dart`: transporte autenticado de candidatos e confirmação; reaproveita o adaptador HTTP/callable e a aquisição real das fontes.
- `functions/src/services/calculadora/entradaAssistenteService.ts`: aquisição comum exportada, com tarefas opcionais para a revisão completa, preservando o comportamento anterior quando não solicitadas.
- `functions/src/services/calculadora/planejadorHibridoService.ts`: autorização do organizador, limites, catálogo imutável, validação dos IDs, unidades/públicos/contexto, receitas privadas, evidência observada e comando transacional idempotente.
- `functions/src/functions/calculadora/planejarServicoCalculadora.ts` e `functions/src/index.ts`: `sugerirCandidatosCalculadora` e `confirmarPlanejadorCalculadora`. A IA recebe apenas candidatos existentes e devolve IDs/perguntas. Saída inválida ou indisponibilidade retorna `parser_local_limitado`, identificado, restrito a nomes exatos já cadastrados. Não há escrita de proposta a partir dessa consulta.
- `calculadora_festa_planejador.dart`, controller, `calculadora_planejador_dialog.dart`, tela/layout da calculadora: botão **Planejar este serviço**, uma pergunta prioritária por vez, revisão progressiva das outras respostas, briefing opcional, candidatos a conferir, origens, premissas e faixa da fonte, custo pendente, alternativa quando há diferença e editor manual. Confirmar aguarda o comando remoto. Cancelar não grava. Contexto/sessão diferentes invalidam a revisão e impedem aplicar callbacks no destino atual.
- `operacao_calculadora_service.dart`, `executarPlanoService.ts` e `firestore.rules`: leitores e whitelist atualizados; alterações comuns preservam a configuração do planejador. O cliente não consegue inserir/alterar decisões nem forjar recibos por escrita direta.
- `pubspec.yaml`/lock: dependência direta de `crypto`, já presente transitivamente, para assinatura do contexto.

## Persistência e compatibilidade

Não há migração obrigatória nem regravação de eventos existentes. Campos opcionais:

```text
calculadora_operacao/{evento}
  planejador.{cardapio}:
    versao: 1
    objetivo: manter_receitas | comparar_quantidades | avaliar_custo
    infraestrutura: {cozinha?, refrigeracao?, aquecimento?, equipe_preparo?}
    respostas: mapa de respostas explícitas
    assinatura_material: SHA-256 do contexto relevante
  execucao.regras: regras confirmadas (campo já existente)
  revisao: incrementada uma vez por confirmação

calculadora_operacao/{evento}/planejador_confirmacoes/{pedido}
  assinatura: hash do comando
  id_usuario: organizador
```

O comando compara a revisão e o snapshot completo de evento, operação, menus/itens, convidados, orçamentos/gastos e tarefas. Fontes alteradas exigem nova revisão. Mesmo pedido e mesmo conteúdo retornam a operação sem reaplicar; mesmo pedido com outro conteúdo é recusado. Valores, versões, estado pronto/cru/seco, obtenção, rendimento e infraestrutura de referências novas são revalidados no servidor. Receitas revisadas já persistidas precisam permanecer iguais.

A confirmação não altera quantidades finais do cardápio, presença, lotes, compras, pagamentos ou contratação. Apenas o planejamento privado é confirmado; os comandos de execução existentes continuam separados. A assinatura para reutilização não usa custos/compromissos como se fossem escolhas alimentares; esses documentos participam da conferência remota de aplicação. As respostas são novamente verificadas contra as opções/contexto vigentes.

## Validação executada

- Reprodução/correção: perguntas de desbloqueio sem quantidade, placeholder vazio, simulação da origem e preservação de receita com catálogo novo. Testes em `test/features/calculadora/planejador_hibrido_test.dart`.
- Testes do domínio: infraestrutura ausente/negada/confirmada; referência válida com preço ausente; alternativa com diferença e objetivo; receita preservada; respostas invalidadas por mudança de público; restrição sem composição pendente; manual fora da cobertura; adoção observada explícita sem preço herdado; quantidade final confirmada inclusive zero; esquema persistido inválido.
- `npm --prefix functions run check:calculadora`: TypeScript e testes existentes, acrescidos de `functions/scripts/testPlanejadorHibrido.js` para rejeitar números/IDs inventados, duplicatas, objetivo/infraestrutura inválidos, limites temporais, mediana adulterada, falta e evidência insuficiente.
- Regras reais no emulador: `test/firestore/calculadora.rules.test.js`, incluindo bloqueio de escrita direta do planejador/recibos, leitura isolada e preservação em alterações comuns. Resultado: **passou**.
- Primeira execução Windows real: `integration_test/planejador_hibrido_emulator_test.dart`, Auth SDK, Firestore SDK e transporte autenticado para as duas callables de produção. Resultado: **passou**. Exercitou fallback local, cancelamento sem escrita, layout estreito com fonte ampliada/teclado simulado, porção adulterada recusada, confirmação, repetição idempotente, fonte antiga recusada, retomada após recriar controller, receita confirmada protegida e outro organizador negado. Quantidade final do item permaneceu inalterada.
- Suíte geral final: **644 testes passaram**, incluindo os **12 testes novos** do domínio do planejador. O primeiro passe havia registrado 642; a rodada final inclui adoção observada e quantidade confirmada, inclusive zero.
- Reexecução final Windows SDK/HTTP/callables: **passou**. O harness também executou os serviços de produção com Firestore real emulado, sem substituto de banco: saídas fabricadas de IA fora do contrato acionaram o fallback, mediana adulterada foi recusada, público incompatível foi recusado e a adoção com três medições verificáveis foi aceita. A injeção do extrator nesses dois cenários testa apenas o contrato de saída, sem chamada externa ao modelo.
- Backend final: **TypeScript e ambos os scripts de validação passaram**. Regras: **passaram**. A análise Dart final permaneceu **sem apontamentos**.
- Análise estática dos arquivos Dart desta entrega: **sem problemas encontrados**. Fontes Dart formatadas; os dois módulos TypeScript novos formatados com o printer da versão TypeScript do próprio projeto.

Logs locais de execução, ignorados pelo Git: `.dart_tool/planejador-unit.log`, `planejador-suite.log`, `planejador-rules.log` e `planejador-sdk.log`.

## Reprodução local sem publicação

```powershell
flutter test
npm --prefix functions run check:calculadora

$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"

node functions/scripts/prepararPlanejadorEmulador.js
firebase emulators:exec --project demo-planejador-hibrido --config firebase.planejador-test.json --only 'firestore,auth,functions' "node functions/scripts/testPlanejadorDesktop.js"
```

O preparador escreve somente em `.dart_tool/planejador-functions`, carrega as duas callables reais e usa um valor fictício local para o segredo. O ramo de emulador não acessa o provedor de IA. Harness e adaptador recusam endpoints externos/projetos fora de `demo-*`. Fixtures são sintéticas, com `example.test`, sem credencial ou dado pessoal real.

## Limites externos e ativação posterior

Não houve deploy, migração destrutiva, commit ou push. O repositório já tinha alterações de outras entregas; foram preservadas.

Não foi chamado modelo externo com credencial real. A extração generativa de produção está implementada, mas sua qualidade real não está homologada por estes testes. O fallback identificado, os validadores e a integração determinística foram executados localmente. Testes de saída de IA fabricada são provas do limite de validação, não chamadas ao modelo.

O Firebase CLI utilizou Node **24** instalado no host, embora o projeto declare Node **22**. Não se afirma homologação do runtime 22. A execução nativa foi Windows; não houve aparelho Android/iOS físico. As verificações de largura, fonte e teclado são simulações de layout em Flutter.

Referências precisam estar publicadas/aprovadas e cobrir o serviço desejado. Não foram inventados valores editoriais para infantil, casamento, congresso ou retiro. Registros privados com contexto incompleto, composição não verificável ou evidência incompatível permanecem para revisão manual. Uma restrição alimentar não é declarada atendida sem composição/preparo conferidos.

Clientes anteriores podem considerar incompatível uma referência que use o novo campo opcional de infraestrutura. Distribuir o leitor atualizado antes de publicar referências com esse requisito.

Para ativação posterior, revisar a entrega, disponibilizar as duas novas Functions junto das regras/leitores compatíveis e configurar o segredo existente `OPENAI_API_KEY` no ambiente autorizado. Revisar também a política/modelo de extração configurado antes de homologar chamadas externas. Somente então distribuir o aplicativo atualizado. Este trabalho deixa os artefatos preparados; não publica nem ativa serviços remotos.
