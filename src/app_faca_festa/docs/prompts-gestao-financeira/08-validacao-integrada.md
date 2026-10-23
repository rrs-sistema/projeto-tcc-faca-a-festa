# Prompt 08 — Validação integrada e preparação da ativação

## Contexto e execução independente

Atue como desenvolvedor sênior Flutter/Firebase e analista financeiro de eventos. Implemente a atividade deste prompt no Faça a Festa com comportamento integrado e verificável. Este arquivo contém todo o contexto necessário: não exige histórico de outro chat, leitura de outro prompt ou etapa anterior executada pelo usuário.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Ambiente Windows/PowerShell. Stack observada: Flutter/Dart, GetX, Firebase Auth, Firestore e Cloud Functions TypeScript em `functions/`.

Antes de editar, leia os AGENTS.md aplicáveis, examine o Git e confirme os comportamentos atuais. Preserve alterações preexistentes. Os caminhos citados são pistas que precisam ser confirmadas. Reutilize entidades, autorização, serviços e interface adequados, sem criar um financeiro paralelo. Se faltar uma dependência necessária ao objetivo, implemente somente a menor base real e reutilizável para entregá-lo. Não exija a execução de outro prompt nem entregue telas desconectadas, mocks de produção ou apenas documentação.

## Contrato financeiro e técnico obrigatório

- Estimativa, cotação, contratação, custo realizado, obrigação e pagamento são fatos distintos. Planejamento aprovado não significa compra, contratação ou pagamento. Cotação não aceita não é dívida ou receita garantida.
- Separe evento, empresa fornecedora e plataforma. Volume contratado não é receita da plataforma. Custos e margens internos são privados do fornecedor. Seu acesso não inclui orçamento global do cliente.
- Gerente significa responsável autorizado pelo evento. Descubra o modelo de autorização; se necessário, estabeleça vínculo explícito por evento. Rótulo de interface não concede permissão. Administrador não recebe automaticamente acesso a custos privados.
- Valores monetários novos usam centavos inteiros em BRL, limites e arredondamento explícitos. Adapte campos legados em double com compatibilidade e sem migração silenciosa em produção.
- Cada fato tem identidade, origem, titular/perspectiva, evento e vínculos pertinentes. Não duplique valores entre orçamento legado, contrato, compra e estoque. Propostas alternativas para uma necessidade não são somadas como compromisso.
- Pagamento e recebimento têm perspectivas definidas. Uma liquidação compartilhada pode alimentar duas visões, mas não duas movimentações na mesma visão. Diferencie registro manual declarado de confirmação externa. Não copie automaticamente registros privados do cliente como recebimento comprovado do fornecedor.
- Preserve descontos, adiantamentos, multas, estornos, reembolsos e créditos explicitamente. Não esconda pagamentos excedentes com clamp. Retificações preservam histórico, autor, data, motivo e origem.
- Ausente, zero confirmado, consulta incompleta, erro, cache e sincronização pendente não são equivalentes. Informação incompleta não sustenta afirmação de economia, lucro ou quitação.
- Valide cálculos e comandos críticos no backend. Functions com Admin SDK verificam autorização própria. Use idempotência, transações e controle de concorrência onde necessário. Troca de sessão/evento deve cancelar listeners e invalidar callbacks antigos.
- Proteja leituras, subcoleções, comandos, anexos, agregados, logs e exportações. Interface em português, responsiva para celular/web/desktop e fonte ampliada, com origem, filtros e atualização dos números. Reutilize padrões visuais existentes.
- Não faça deploy, alterações em produção, migração destrutiva, commit ou push. Não execute cobrança real nem envie mensagens externas. Testes autenticados usam dados sintéticos e projeto demo/emuladores, recusando produção.

## Validação e entrega

Implemente as camadas pertinentes: domínio, persistência, backend/permissões e interface. Confira os scripts atuais antes de usá-los. Existem referências a `flutter test`, `npm --prefix functions run build`, `npm --prefix functions run check:calculadora`, `npm run test:rules` e `npm run test:rules:calculadora`; selecione os adequados e adicione testes específicos necessários. O lint das Functions pode apenas informar que foi ignorado; isso não comprova análise estática.

Execute formatação, análise estática e testes pertinentes, inclusive regras e Functions separadamente, acesso negado, repetição e concorrência quando aplicáveis. Não corrija problemas alheios ao escopo. Falta de aparelho/credencial não impede trabalho independente: entregue roteiro reproduzível e explicite o que não foi executado. Mocks não comprovam integração Firebase.

Registre evidência no caminho indicado ao final: diagnóstico, regras, arquitetura, arquivos, formato persistido, compatibilidade, índices, testes/resultados reais, limitações e ativação posterior sem publicação. Ao concluir, explique comportamento entregue, pendências e alterações preexistentes relevantes.

## Objetivo

Audite os fluxos financeiros disponíveis de ponta a ponta e corrija defeitos comprovados de integração, segurança e conciliação. Este prompt funciona sozinho: descubra capacidades existentes. Módulo inteiramente ausente é lacuna, sem reconstruir todo o sistema nesta atividade. Esta regra delimita a fundação mínima mencionada no contrato comum.

## Investigue

Módulos de evento, orçamento, fornecedor, estoque, comissão e administração existentes, serviços, Functions, `firestore.rules`, `storage.rules`, scripts e `integration_test/`. Evidências antigas não comprovam o estado atual.

## Requisitos

1. Matriz requisito → origem persistida → comando → leitura → permissão → teste → resultado. Classifique disponível/validado, disponível/com defeito e ausente; diferencie bloqueio de ativação de teste não executado por dependência externa.
2. Fixtures determinísticas no emulador com dois organizadores, dois fornecedores, gerente limitado e administrador; contratos, parcelas, custos e cancelamentos conforme capacidades disponíveis.
3. Concilie evento, recebimento do fornecedor quando compartilhado/conciliado e comissão. Declaração unilateral não precisa coincidir com caixa confirmado: explique diferenças, sem copiar dados privados.
4. Teste datas de evento, competência gerencial, vencimento e liquidação; moeda, arredondamento, ausência, cache, consulta parcial, filtros e apresentação no fuso America/Sao_Paulo.
5. Teste autorização de leitura/comandos, Functions com Admin SDK, subcoleções, anexos, agregados e exportações presentes. Inclua anônimo, evento alheio, outra empresa e tentativa de elevar papel pelo cliente.
6. Teste idempotência, concorrência, retentativa de rede, entrega duplicada/fora de ordem e retomada. Reconstrução de agregados no teste concilia com a origem.
7. Verifique visualmente celular e desktop/web conforme recursos disponíveis, indicando as superfícies efetivamente testadas. Não afirme validação mobile sem evidência.
8. Corrija defeitos de integração com testes de reprodução, sem adicionar pagamento externo, relatórios fiscais ou módulos ausentes de grande porte.
9. Entregue roteiro de ativação posterior: decisões comerciais, configurações, regras/índices, compatibilidade, migração dry-run em emulador quando necessária, observabilidade, desativação de novas escritas e tratamento dos fatos já gravados. Não publique.

## Cenários mínimos conforme capacidades existentes

- Contrato R$ 10.000, pago R$ 3.000, saldo R$ 7.000.
- Limite R$ 30.000, contratos R$ 18.000 e restantes R$ 8.000: previsão R$ 26.000.
- Comissão sintética 5% de R$ 10.000: R$ 500 uma vez, versão preservada.
- Estoque concorrente sem excesso/duplicação; cancelamento parcial com histórico e saldo correto.
- Taxa futura preserva contratos anteriores; preço ausente não vira economia.
- Logout/troca de evento sem dados antigos e acessos cruzados negados no backend.

Conclusão separa validado, corrigido, não executado e ausente. Só declare o escopo completo com evidência atual para todos os requisitos correspondentes.

Evidência: `docs/evidencias_validacao/financeiro/08-validacao-integrada.md`.
