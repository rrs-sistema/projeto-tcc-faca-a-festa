# Auditoria da Calculadora Inteligente — 14/10/2026

**Conclusão:** há um motor determinístico de estimativa, integração parcial com o aplicativo e uma camada de IA interpretativa. Ainda não há um planejador capaz de avaliar autonomamente a composição da refeição, resolver consumos desconhecidos e produzir recomendações operacionais verificáveis. A ausência de resultados nas imagens tem uma causa operacional comprovada: as coleções do catálogo de cálculo estão vazias no projeto configurado.

## 1. Escopo e evidências

Revisados: tela e etapas, controller, entidades matemáticas, correspondência com cardápio, repositórios e datasources Firestore, orçamento e pagamentos, histórico, bootstrap da IA, Cloud Function, prompt, normalização da resposta, base editorial, regras de acesso e testes.

Consulta de leitura com Firebase Admin SDK ao projeto `faca-a-festa`, banco `(default)`, em 14/10/2026:

| Coleção | Documentos | Efeito |
| --- | ---: | --- |
| calculadora_itens_base | 0 | Catálogo administrativo sem itens |
| calculadora_evento_itens | 0 | Sem regras de consumo por tipo de evento |
| ia_sugestoes_base | 0 | Sem referências editoriais para a IA |

O projeto coincide com `.firebaserc` e `lib/firebase_options.dart`. A consulta não alterou documentos, não leu informações privadas da festa das imagens e não invocou geração paga. A conclusão se refere ao momento da consulta, não a um histórico de disponibilidade. Evidência resumida em `.dart_tool/auditoria_calculadora/firestore-contagens.json`.

Executado `npm run test:calculadora`: **25 testes Flutter passaram** (calculadora e cardápios), TypeScript `tsc --noEmit` passou e testes de planejamento/callable passaram. O teste da callable usa stubs e rede bloqueada: prova autorização e fallback, não a qualidade de uma resposta generativa real. Não reexecutadas as regras com emulador nesta auditoria. Não realizada validação visual integral em celular.

## 2. Inventário funcional

| Capacidade | Situação comprovada | Limite |
| --- | --- | --- |
| Pessoas do evento | Implementada | Carregamento inicial/atualização manual, sem assinatura de mudanças nos convidados |
| Todos / confirmados / manual | Implementada | Confirmados dependem do status individual; sem confirmação, total pode ser zero |
| Adultos, crianças e bebês | Implementada | Pesos fixos 1, 0,6 e 0,2; não há calibração por item |
| Público de cada item | Implementada | Filtra população; continua usando pesos fixos para consumos e descartáveis |
| Perfil econômico/padrão/premium | Implementada | Multiplicadores e margens fixos; descrição ainda menciona alteração de custo médio |
| Duração e margem | Implementada | Escala genérica; duração não altera descartáveis, mas perfil/margem/pesos alteram |
| Quantidade e custo por item | Implementada | Requer regra de consumo; custo requer preço, ausência vira zero e marca parcial |
| Recalcular automaticamente | Implementada | Executado em mudanças de pessoas, duração, margem, seleção, modo e regra manual |
| Catálogo por tipo e perfil | Implementada no código | As duas coleções estão vazias em produção |
| Cadastro administrativo do catálogo | Implementado | Existência da tela não significa catálogo abastecido/validado |
| Ler cardápio da festa | Implementada | Só o cardápio selecionado; não consolida todas as refeições |
| Associar item à regra | Implementada parcialmente | Nome/unidade/público, sem ID canônico, aliases ou tratamento de ambiguidade assistido |
| Comparar sugerido e final | Implementada | Diferença aparece principalmente no modal de aplicação |
| Aplicar ao cardápio | Implementada | Mantém quantidade final e confirmação; novos itens aguardam decisão do usuário |
| Histórico/aprovação/orçamento | Implementados | Não guarda todo o contexto que explica a simulação |
| Consultar valores já orçados | Implementada parcialmente | Consulta pais de orçamento, não toda a estrutura de pagamentos e serviços |
| IA remota interpretativa | Implementada e registrada | Só é chamada após resultados calculados; não resolve a ausência de regras |
| Sugestões editoriais | Serviço e seed existentes | Coleção vazia; gatilhos são enviados ao prompt, não avaliados por motor determinístico |
| Diagnóstico antes de cálculo | Ausente | IA e seu cartão desaparecem quando não existem resultados |
| Composição da refeição | Ausente no motor | Não distribui consumo entre pratos/acompanhamentos/bebidas alternativas |
| Plano de compras executável | Ausente | Sem estoque, rendimento, tamanho de embalagem e vínculo com compras |
| Otimização por limite financeiro | Ausente | Avalia projeção; não monta alternativas concretas com impacto recalculado |

## 3. Fluxo que explica as imagens

O controller consulta `calculadora_evento_itens` por `ativo`, `tipo_evento` e, inicialmente, `perfis_festa`. Quando não há resultado com perfil, consulta o mesmo tipo sem filtro de perfil. Esse fallback relaxa o perfil: não consulta automaticamente `calculadora_itens_base`, nem um catálogo genérico de outros eventos.

Como a coleção está vazia, o modo “Estimar do zero” não recebe regras. A seleção de itens fica indisponível e o motor não produz resultados. No modo “Revisar meu cardápio”, o app consegue ler Churrasco, Macarrão, Arroz e Refrigerante, mas também não dispõe de regras para associar a eles. Todos são classificados como pendentes.

`calcular()` encerra quando `itensParaCalculo` está vazio. `_executarAnaliseIA()` encerra quando não há estimativa, cálculo ou itens calculados. O prompt também determina que a IA não invente consumos de itens sem regra. Portanto, não se trata simplesmente de esquecer um botão “Calcular”: o fluxo não consegue sair da falta de conhecimento para uma orientação útil.

Os R$ 6.500 exibidos são a soma dos valores de orçamento retornados pelo datasource. Sem acesso ao evento específico, não foi reconciliada essa soma com documentos individuais, cancelamentos, contratos ou pagamentos. Ela não representa um cálculo de porções.

## 4. Motor matemático: o que faz e o que não faz

Para cada item selecionado, a quantidade resulta de:

`população equivalente do público × consumo cadastrado × multiplicador de perfil × fator de duração × (1 + margem)`.

Kg e litros são arredondados para cima em centésimos; demais unidades para inteiros. Custo = quantidade arredondada × preço unitário cadastrado. Isso evita cobrar uma quantidade diferente da exibida. Preço ausente não bloqueia a quantidade, mas gera custo zero e estimativa parcial.

A duração aplica fatores de 0,85 até 1,25; acima de seis horas utiliza 1,25. Não há diferenciação de curva entre água, refrigerante, carne, bolo e acompanhamentos. O perfil econômico usa 0,90 e margem de 5%; padrão 1,00 e 10%; premium 1,20 e 15%. Esses fatores se acumulam.

Reprodução direta usando uma regra hipotética de 0,1 kg, 100 adultos e duração de quatro horas: econômico 9,45 kg, padrão 11 kg, premium 13,8 kg. Trata-se de verificação da fórmula, não de uma recomendação alimentar. O perfil premium resulta em 38% acima da quantidade base nesse exemplo.

A classe não recebe os demais pratos da refeição no cálculo de um item. Adicionar macarrão não diminui a quantidade calculada de arroz, mesmo se ambos forem acompanhamentos concorrentes. Esse é um limite estrutural: preencher o catálogo fará números aparecerem, mas não fará o sistema compreender a refeição.

Para descartáveis, retirar o fator de duração foi útil, mas a quantidade ainda usa equivalência de crianças/bebês e multiplicador de perfil. Um item destinado a todos e configurado como uma unidade por pessoa pode produzir menos de uma unidade por criança. A contagem física de pessoas precisa de regra própria, separada de equivalência alimentar.

Não existem atributos de peso cru/cozido, perda, rendimento, capacidade da garrafa, tamanho do pacote, porções por receita ou cobertura de buffet contratado. As unidades são rótulos de cálculo, não uma modelagem completa de compra.

## 5. Achados priorizados

**A1 — Crítico para operação: catálogo de produção vazio.** O fluxo principal perde sua matéria-prima. Cadastro do catálogo e regras por evento deve ter responsável, revisão e verificação de disponibilidade. Executar apenas o seed editorial não cria regras matemáticas de consumo.

**A2 — Alto: diagnóstico condicionado a já haver cálculo.** O usuário precisa configurar o conhecimento que esperava receber. Deve existir diagnóstico de prontidão independente de resultado: pessoas, cardápio, itens conhecidos, pendências e próximas ações. Sugestões de premissas devem ser distinguíveis de regras aprovadas.

**A3 — Alto: composição da refeição não modelada.** Cada item é independente. É necessário representar função na refeição, alternativas e participações, sem reduzir automaticamente itens por simples contagem de pratos.

**A4 — Alto: associação frágil por nome.** Reproduzido em Dart: `normalizar('Arroz')` retorna `arroz`; `normalizar('Arroz 🍚')` retorna `arroz_`. Portanto, o emoji das imagens pode impedir correspondência mesmo após cadastrar a regra. Além disso, nomes equivalentes e unidades diferentes não são associados. Havendo regra para “todos” e outra para o público específico, ambas são candidatas e o método retorna null por ambiguidade, sem priorizar a específica. Precisa de IDs canônicos, normalização de separadores, aliases curados e seleção assistida para casos ambíguos.

**A5 — Alto: integração financeira incompleta.** O datasource procura `nome`/`item`, unidade e público no pai de orçamento. O modelo padrão do módulo financeiro guarda vínculo com serviço fornecido, categoria, anotações e status; não garante aqueles campos. Orçamentos criados pela calculadora possuem esses atributos, mas os demais podem não ser reconhecidos como cobertura do mesmo item. A projeção pode somar novamente algo já contratado.

A consulta não exclui explicitamente `status: cancelado`: filtra apenas `ativo` e `deletado`. Não diferencia pendente, negociação, fechado e pago. O aplicativo possui pagamentos em `orcamento/{id}/orcamento_gasto`; esse caminho não entra no contexto da calculadora. “Já orçado” não pode ser apresentado como “já pago”. O crédito financeiro por item usa `max(custo sugerido - valor existente, 0)`, que é uma aproximação monetária, não prova de quantidade comprada ou escopo coberto.

O limite disponível inicia null e é informado na calculadora; o módulo financeiro usa também o custo estimado do evento como limite. Falta uma fonte explícita comum ou uma explicação de diferenças entre os dois limites.

**A6 — Alto: indicadores sem metodologia comprovada.** Economia, risco e conforto são devolvidos pela IA; normalização limita a faixa a 0–100. O fallback usa constantes como risco 30 e conforto 60/80. Não há fórmula calibrada, dados históricos ou validação que sustentem interpretação como probabilidades. Esses números não demonstram risco real de falta. Preferível indicar estado e evidências até haver metodologia.

**A7 — Médio/alto: histórico não reproduz todo o planejamento.** Guarda quantidades, preços, população, perfil, duração, margem e análise, o que é útil. Não guarda de forma completa o modo de revisão, ID/contexto do cardápio, pendências sem regra, versão/fonte das regras matemáticas e snapshot financeiro. Ao reabrir, o editor força modo estimar do zero e reconstrói só os itens calculados. Uma simulação parcial pode perder a lista de itens que ficaram de fora. A rastreabilidade do prompt existe; a rastreabilidade completa do cálculo ainda não.

**A8 — Médio: ausência de configuração ainda oferece repetição ineficaz.** A UI usa `erroItensBase.isNotEmpty` para mostrar “Tentar novamente”. `_marcarBaseIndisponivel` preenche esse campo também quando não existe configuração. A mudança anterior do layout foi insuficiente: ausência de catálogo continua aparecendo como algo solucionável por retry. Deve usar o estado de origem, não apenas uma string de erro.

**A9 — Médio: uma regra inválida pode bloquear a lista inteira.** Conversão lança exceção para consumo inválido, preço inválido ou unidade não suportada. O map/toList está sob um catch comum que limpa os itens remotos. Não há processamento parcial com rejeição identificada por item.

**A10 — Médio: inferência de tipo limitada.** Há classificação por palavras-chave, mas ela não resolve função na refeição. A regra manual usa tipo outro por padrão; atribuir uma categoria não introduz inteligência semântica no cálculo. Correspondência também exige mesma unidade: não há conversão entre bebida em litros e garrafas de capacidade conhecida.

**A11 — Médio: UX ainda privilegia configuração sobre decisão.** Modo, edição manual, finanças e cardápio vêm antes do resultado. A fórmula existe em texto, mas o tile a corta em uma linha. Comparações ficam no modal de aplicação; pendências não são um painel prioritário; próximos passos da IA são texto sem comandos estruturados. O cardápio tem dois papéis, fonte de revisão e destino de aplicação, que precisam ficar claros.

**A12 — Médio: robustez da IA ainda parcial.** Há autenticação, verificação de acesso, segredo no backend, proteção contra respostas antigas e fallback com identificação de fonte. O app tem timeout de 60s; a Function de 120s e o fetch do provedor não tem timeout explícito. Não há mecanismo de deduplicação/cache por contexto no caminho revisado. Debounce de 500ms reduz chamadas, mas não evita novas chamadas para cada mudança estabilizada. O schema existe, porém a chamada pede json_object e a resposta passa por normalização permissiva, sem validação estrita integral desse schema. Valores financeiros são preservados a partir do payload, não recalculados com dados autoritativos do Firestore no backend.

A rastreabilidade chama referências enviadas de “utilizadas”, mas registra todas as referências recuperadas; não prova quais sustentaram cada recomendação. A base editorial pode recorrer a sugestões de outros contextos quando não encontra compatíveis. Esses pontos importam para qualidade e auditabilidade, embora não expliquem a tela vazia atual.

## 6. Integração com o restante do aplicativo

Existe conexão com evento, convidados, cardápio, orçamento, histórico e infraestrutura editorial/IA. Essa conexão é funcional, mas não representa cobertura completa do aplicativo. No caminho auditado, não há leitura operacional de tarefas, estoque, compras, escopo de fornecedores, disponibilidade/cotação, receitas, restrições alimentares ou distribuição de consumo entre refeições. Também não há criação automática de ações/tarefas a partir das próximas ações da IA.

Pontos positivos a preservar: final e confirmado do cardápio não são sobrescritos; novos itens começam sem quantidade final; o modal permite seleção; existem transações e bloqueios de duplicidade; a conversão em orçamento exige aprovação e preserva custos existentes, registrando proposta separada; simulações têm controle de acesso; resultados antigos da IA são descartados. Esses mecanismos evitam alterações silenciosas em decisões do organizador.

## 7. Sequência recomendada de evolução e critérios de conclusão

1. **Disponibilidade e diagnóstico:** catálogo governado, normalização/identidade, diagnóstico independente do cálculo e estados distintos de erro/configuração ausente. Concluído quando abrir uma festa com cardápio produz relatório de cobertura e ação útil mesmo sem regra; um item inválido não remove os válidos; emojis não quebram identidade.
2. **Confiabilidade matemática:** separar população física de equivalência alimentar, contextualizar refeições, modelar unidades/rendimentos e registrar fontes/versões. Concluído quando testes de pratos concorrentes, descartáveis e embalagens têm premissas explícitas e resultados justificáveis.
3. **Confiabilidade financeira:** usar vínculos de domínio com serviços/itens, excluir cancelados, separar cotado/contratado/pago, unificar limite e marcar cobertura parcial. Concluído quando um buffet contratado não é cobrado de novo e o contexto se reconcilia com o financeiro do evento.
4. **Inteligência assistiva:** propor premissas com confirmação, apresentar diagnóstico e alternativas com impactos recalculados; IA explica e ajuda a classificar, motor aplica regras verificáveis. Concluído quando o usuário recebe decisão útil em vez de preencher consumo de todos os itens sozinho.
5. **Reprodutibilidade e experiência:** guardar contexto completo, exibir resumo de resultado/comparação no início e vincular ações a edição concreta. Concluído quando uma simulação parcial reabre com as mesmas pendências e cada quantidade/custo explica sua origem.

## 8. Lacunas de testes e limites da auditoria

Os testes existentes protegem aritmética, consumo por público, ausência de preços inventados, revisão parcial, deduplicação financeira em cenário sintético, atualização de regra manual, respostas antigas da IA, payload e restauração de regras do histórico. Há testes de widgets do diálogo, incluindo teclado e texto ampliado, e testes de cardápio. Isso é relevante, mas não comprova qualidade do planejamento alimentar.

Faltam verificações do catálogo em ambiente real, correspondência com nomes decorados, concorrência entre regras geral/específica, registros de orçamento no formato padrão, cancelados, pagamentos, múltiplos cardápios/refeições, contagem física de descartáveis, contexto parcial no histórico, regra inválida entre válidas, qualidade de respostas generativas e jornada completa em aparelho.

Não foram preenchidas coleções, alteradas regras de negócio, publicadas versões nem realizadas contratações. Os achados de domínio são avaliações do código atual; impacto exato nos R$ 6.500 depende de reconciliação com a festa específica.

## 9. Fontes do repositório

- `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart`: consulta, flags, orçamento, convidados e cálculo.
- `lib/domain/entities/estimativa_financeira.dart`, `perfil_festa.dart`, `convidados_equivalentes.dart`: fórmulas e coeficientes.
- `lib/domain/services/revisao_cardapio_service.dart`: identidade e correspondência.
- `lib/data/datasources/remote/calculadora_itens_base_remote_datasource.dart`: filtros e fallback.
- `lib/data/datasources/remote/calculadora_festa_remote_datasource.dart`: compromissos, histórico, aplicação e conversão.
- `lib/data/models/orcamento/orcamento_model.dart`, `lib/data/datasources/remote/orcamento_gasto_remote_datasource.dart`: estrutura financeira real.
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_historico.dart`: recuperação de simulação.
- `lib/presentation/modules/calculadora/controllers/calculadora_festa_analise_ia.dart`: pré-condições e concorrência.
- `lib/app/bootstrap/calculadora_bootstrap.dart`: registro do serviço remoto e timeout.
- `functions/src/functions/calculadora/analisarCalculadoraFestaIA.ts`: autorização, geração e fallback.
- `functions/src/ia/calculadora/prompt.ts`, `schema.ts`: propósito e contrato.
- `functions/src/services/calculadora/sugestoesBaseIAService.ts`, `rastreabilidadeCalculadoraIAService.ts`, `financeiroCalculadoraService.ts`: contexto, normalização e projeção.
- `functions/src/seeds/calculadora/seedIaSugestoesBase.ts`: seed editorial existente.
- `firestore.rules`: controles de acesso das simulações.
- `test/features/calculadora`, `test/features/cardapios`, `functions/scripts/testCalculadoraPlanejamento.js`: cobertura executada.
