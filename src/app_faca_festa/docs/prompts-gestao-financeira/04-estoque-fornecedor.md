# Prompt 04 — Estoque, reservas e custos por evento

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

Entregue estoque empresarial do fornecedor integrado à disponibilidade e ao custo de execução dos eventos. Estoque alimentar da calculadora é uma base a investigar, sem presumir equivalência com estoque empresarial.

## Investigue

Entidade disponibilidade_cardapio, serviços de operação/lista de compras/ficha técnica, `functions/src/services/calculadora/executarPlanoService.ts`, agenda, reservas, catálogo e autorização. Não transfira lotes privados do organizador para uma empresa sem vínculo explícito.

## Requisitos

1. Diferencie consumíveis próprios, reutilizáveis e locados de terceiros. Cadastre unidade, proprietário, quantidade, custo, localização e lote/validade/conservação quando aplicáveis.
2. Histórico de entradas, reservas, liberações, consumo, retirada, devolução, perda, manutenção e ajustes. Transições não descontam duas vezes a mesma quantidade.
3. Reutilizáveis têm reservas por intervalo, incluindo montagem/transporte/desmontagem quando configurados. Defina limites de intervalo. Reserva atômica impede concorrência acima da disponibilidade.
4. Para consumíveis fungíveis, proponha custo médio móvel gerencial; preserve método coerente já existente e documente. Seleção física por validade não altera silenciosamente a valorização.
5. Reserva não realiza consumo/pagamento. Compra abastece estoque e pode gerar obrigação, sem ser custo integral imediato de um evento. Consumo atribui custo; devolução e perda têm tratamento explícito.
6. Reutilizáveis usam custo de uso configurado com método e origem, sem afirmar depreciação fiscal. Terceiros têm custo de locação, retirada/devolução e prazo vinculados ao evento.
7. Alertas de falta, compra/locação necessária, validade, manutenção, conflito e devolução. Custo ausente sinaliza financeiro incompleto, preservando disponibilidade física conhecida.
8. Integre custo privado pela origem única do movimento. Se o módulo de custos não existir, crie somente o registro mínimo necessário.

## Critérios de aceite

- Saldo 100, reserva 60: reserva concorrente de 50 não é aceita no mesmo contexto de disponibilidade.
- Retirada de reserva não desconta novamente a disponibilidade comprometida.
- Dez cadeiras podem atender intervalos não sobrepostos, respeitando logística; não atendem simultaneamente acima da capacidade.
- Consumo de 20 unidades com custo aplicável R$ 5 atribui R$ 100 ao evento sem novo desembolso.
- Repetir consumo/devolução não duplica movimento; cancelamento libera apenas reservas ainda não consumidas/retiradas.
- Outra empresa não acessa estoque; item vencido/em manutenção não é oferecido como disponível.

Evidência: `docs/evidencias_validacao/financeiro/04-estoque-fornecedor.md`.
