# Prompt 07 — Previsão financeira e cotação conforme orçamento

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

Implemente simulação do evento conforme limite do cliente e apoio à cotação viável. Cálculos são determinísticos/explicáveis; IA interpreta e explica, sem inventar preços ou executar fatos financeiros por inferência.

## Investigue

Módulos calculadora, orçamento, catálogo e recomendação, resposta de cotação por IA, serviços de compras/financeiro, entidades de estimativa e `functions/src/services/calculadora/financeiroCalculadoraService.ts`.

## Requisitos

1. Considere público, data, local, duração, necessidades, unidades, contratos e limite confirmado. Diferencie cobertura completa, parcial e descoberta.
2. Priorize propostas vigentes e catálogo compatível. Histórico exige data, região, amostra e validade. Fonte incompatível/insuficiente não produz preço inventado; preserve fonte e versão.
3. Cenários econômico/intermediário/completo só quando houver alternativas reais adequadas. Mostre previsão, folga/excesso, itens sem preço e alterações de quantidade/escopo. Simular não muda contratos ou limite confirmado.
4. Calcule somente parte descoberta e uma alternativa por cobertura no cenário. Não some concorrentes ou alimentação já coberta. Valide unidades e inclusões/exclusões de pacotes.
5. Precificação do fornecedor usa custos privados e despesas informadas. Se margem desejada e taxas incidirem sobre a mesma base de venda, preço = custos monetários / (1 − margem − taxas percentuais aplicáveis). Rejeite denominador não positivo. Distinga markup e margem; não aplique a fórmula a bases tributárias incompatíveis. Estoque existente tem custo de uso/consumo, não apenas compra futura.
6. Fornecedor recebe somente faixa/teto do seu serviço explicitamente compartilhado, sem acesso ao limite global, contratos alheios ou custos de concorrentes.
7. Sem histórico confiável, previsão comercial usa hipóteses manuais identificadas. Com histórico, defina coortes, negócio, probabilidade e alternativas mutuamente exclusivas. Valor ponderado não é receita garantida. Previsão de caixa usa obrigações/vencimentos reais separadamente.
8. Mostre premissas, horizonte, completude e atualização. Mudanças de preço/limite/contrato pedem revisão do cenário sem reescrever versões aprovadas. IA não confirma negócios nem envia mensagens.

## Critérios de aceite

- Limite R$ 20.000 e comprometido R$ 15.000: R$ 5.000 livres antes de despesas/reserva, sem exposição ao fornecedor não autorizado.
- Cotações alternativas não são somadas na previsão.
- Custos R$ 700, margem sobre venda 20% e taxa na mesma base 10%: preço R$ 1.000, com premissas explícitas.
- Preço ausente/histórico incompatível deixa projeção parcial.
- Simulação/IA não gera contrato, compra, reserva, pagamento ou comissão.

Evidência: `docs/evidencias_validacao/financeiro/07-previsoes-e-cotacoes.md`.
