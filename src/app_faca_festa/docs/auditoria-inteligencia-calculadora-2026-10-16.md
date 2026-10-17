# Auditoria da inteligência da Calculadora Inteligente

Data: 16/10/2026. Escopo: código local atual, testes e contratos entre Flutter e backend. Esta auditoria não altera o motor, não publica versões e não consulta dados reais de produção.

## Conclusão executiva

A calculadora evoluiu para um planejador assistido: calcula por regras explícitas, revisa o cardápio selecionado, distingue disponibilidade física de compromisso financeiro, gera uma lista de compras, simula alternativas e consulta consumo anterior. A IA generativa interpreta esses resultados; ela não determina as quantidades.

Não considero a inteligência concluída. Foram reproduzidas seis lacunas, cinco delas com impacto direto em compras, porções, cobertura ou decisão financeira. Há ainda percentuais de risco/conforto sem calibração estatística no histórico. Os recursos combinados estão amplamente presentes, mas algumas integrações não acompanham a evolução do motor operacional.

O próximo trabalho deve corrigir coerência e confiabilidade antes de ampliar funcionalidades ou prometer recomendações de consumo validadas.

## Método e evidências

- Leitura dos serviços de cálculo, composição, revisão de cardápio, compras, conciliação financeira, referências, consumo observado, cenários e medição de uso.
- Leitura do controller, sincronização, histórico, apresentação, datasource, bootstrap da IA, prompt e function realmente exportada no backend.
- Cruzamento com `calculadora-conclusao-planejamento.md` e `calculadora-fluxo-operacional-compras.md`. As conclusões desses documentos foram conferidas contra o código, não assumidas como prova.
- **95 testes existentes de calculadora e cardápio aprovados** nesta auditoria.
- **Seis cenários adicionais reproduziram as lacunas descritas abaixo.** Suas asserções confirmam o comportamento problemático atual; não representam correções nem aprovação desse comportamento.
- `npm run check:calculadora`: TypeScript sem emissão e verificações de planejamento, autorização e fallback aprovados.
- Análise estática das entidades, serviços, módulo da calculadora e serviço remoto de IA sem problemas.
- Execução isolada do financeiro TypeScript com payload efetivamente produzido pelo controller confirmou a divergência entre resumo e IA.

Artefatos locais de reprodução:

- `.dart_tool/auditoria-inteligencia-20261016_test.dart`
- `.dart_tool/auditoria-inteligencia-reproducao.log`
- `.dart_tool/auditoria-inteligencia-contexto-ia.json`
- `.dart_tool/auditoria-inteligencia-contrato-backend.log`
- `.dart_tool/auditoria-inteligencia-suite.log`
- `.dart_tool/auditoria-inteligencia-backend.log`
- `.dart_tool/auditoria-inteligencia-analysis.log`

Não foram feitas chamadas à IA externa, publicação, navegação integral em aparelho físico, inventário do catálogo Firestore publicado ou validação com festas reais. Os testes do backend utilizam substitutos de serviços externos. Não executei novamente o emulador de regras Firestore nesta auditoria.

## Em que ponto estamos

| Camada | Implementado e verificado no código | Limitação atual |
| --- | --- | --- |
| Cálculo | Público equivalente, porção, perfil, serviços, duração opcional, composição, rendimento, reserva e arredondamento | Coeficientes são premissas; há erros nas interações de embalagem e grupos |
| Cardápio | Revisão por item, correspondência conservadora, proposta de unidade e aplicação explícita | Atua no cardápio selecionado; não modela automaticamente o plano completo de todas as refeições |
| Compra | Comprado, estoque reservado, falta comprar, embalagem, serviços e cópia da lista | Arredondamento antecipado pode gerar excesso; cobertura não tem escopo de refeição |
| Financeiro | Compras restantes conhecidas, pendências, conciliação, pagamentos e saldo condicionado | A IA ainda usa outra projeção e critérios de completude |
| Composição da refeição | Papéis declarados, ausência de principal, alternativas e alertas de público/bebida | Alertas não constituem validação de suficiência; grupo incompatível ainda é dividido |
| Referências | Fontes contextuais, estado cru/seco/pronto, faixa e receita própria | Catálogo contextual local pequeno; não é uma base universal de porções |
| Histórico de consumo | Disponibilizado, sobra, desperdício, falta, contexto, mediana e exclusão da festa atual | Sem validação preditiva; contexto não registra as quantidades dos demais alimentos |
| IA | Análise remota, origem da resposta, fallback e proteção contra resposta antiga | Não substitui o motor; recebe financeiro inconsistente e ainda produz índices não calibrados |
| Experiência | Próxima ação prioritária, ferramentas adicionais, detalhes da fórmula, estados vazios e avaliação voluntária | Usabilidade e valor comercial ainda não medidos com usuários reais |

## Como o número é calculado

A base é, em termos simplificados:

`público equivalente × porção × serviços × participação × perfil × duração opcional ÷ rendimento × reserva`

Depois são aplicados os arredondamentos da unidade e da embalagem. Descartáveis e regras contextuais têm exceções explícitas a certos multiplicadores. A escala por duração não é automaticamente aplicada a toda refeição.

Essa fórmula é explicável, o que é positivo. Entretanto, a capacidade de executar uma fórmula corretamente não comprova que a porção de origem é adequada ao prato e à refeição reais. Crianças com peso 0,6, bebês com peso 0,2, perfis e reservas são hipóteses de planejamento, não resultados de uma calibração demonstrada.

## Pendências concretas

P1 significa corrigir antes de considerar a inteligência operacional consolidada. P2 significa resolver antes de apresentar aprendizado ou confiança como diferencial validado.

### 1. P1 — Embalagem é arredondada antes de descontar disponibilidade

**Reprodução:** necessidade de 1 kg, embalagem de 2 kg e 1 kg já comprado. O motor transforma a necessidade em 2 kg. A lista desconta o 1 kg comprado e arredonda novamente a diferença para uma embalagem de 2 kg. Recomenda comprar **2 kg adicionais**, embora a necessidade já esteja atendida.

**Causa:** `ItemEstimativaFinanceira.calcularQuantidadeArredondada` aplica embalagem; `ListaComprasCalculadoraService.analisar` usa `resultado.quantidade` como ponto de partida para o saldo e aplica embalagem novamente.

Evidências: `lib/domain/entities/estimativa_financeira.dart:203`, `lib/domain/services/lista_compras_calculadora_service.dart:175`.

**Correção necessária:** separar necessidade de preparo/consumo, quantidade disponível e compra comercial. Descontar o disponível da necessidade correta antes de arredondar a compra. Preservar corretamente a conversão por rendimento e estado.

**Aceite:** 1 kg necessário + 1 kg disponível → zero a comprar, mesmo com embalagem de 2 kg; 1 kg necessário + zero disponível → comprar uma embalagem de 2 kg. Testar o caminho completo motor → lista → financeiro, além dos serviços isolados.

### 2. P1 — Grupos com papéis incompatíveis continuam reduzindo porções

**Reprodução:** arroz como acompanhamento e carne como principal, ambos com divisão ativada, mesmo grupo e mesmo público. O fator de composição calculado é **0,5 para cada item**. O diagnóstico avisa que o grupo mistura papéis, mas a redução já aconteceu.

**Causa:** a composição agrupa por nome de grupo e público, sem exigir papel compatível. O alerta está em outro serviço e não impede a divisão.

Evidências: `lib/domain/services/composicao_refeicao_service.dart:16`, `lib/domain/services/analise_refeicao_service.dart`.

**Correção necessária:** validar grupo antes de calcular. Grupo incompatível deve exigir revisão, ou não dividir, até que o organizador o corrija. Evitar apenas acrescentar outro aviso mantendo o número reduzido.

**Aceite:** um principal e um acompanhamento não recebem redução por serem indevidamente colocados no mesmo grupo. Alternativas válidas de mesmo papel e público continuam funcionando.

### 3. P1 — Resumo financeiro e IA usam projeções diferentes

**Reprodução com o controller real:** 10 kg de necessidade, preço de R$ 10/kg, 2 kg comprados por R$ 20 e 8 kg de estoque reservado. Limite de R$ 50. A conferência financeira declara a despesa realizada.

- Resumo: zero a comprar, R$ 20 orçados, **R$ 30 de saldo**.
- Contexto enviado à IA: **R$ 100 de custo projetado e saldo de −R$ 50**.
- O financeiro TypeScript recebe esse payload e confirma custo 100, diferença 50 e `incompleto: false`.

**Causa:** `contextoPlanejamento` ainda calcula `gastos + novos` a partir do custo total dos itens, apesar de já enviar `compras_restantes`. O backend escolhe `custo_projetado`, não o resumo conciliado.

Evidências: `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart:351`, `functions/src/services/calculadora/financeiroCalculadoraService.ts:7`.

**Correção necessária:** ter um único contrato financeiro autoritativo, compartilhado por tela, cenários, histórico e IA. Não corrigir o texto do prompt para esconder uma divergência numérica.

**Aceite:** o mesmo cenário apresenta saldo de R$ 30 na tela e no contrato da IA. Estoque, compras realizadas e cobertura não geram novo custo artificial.

### 4. P1 — Pendências operacionais não tornam a análise da IA incompleta

**Reprodução:** item com regra e preço, mas sem disponibilidade informada. O resumo acusa uma quantidade pendente e `completo: false`. O contexto enviado à IA continua com `estimativa_incompleta: false`.

**Causa:** `estimativaIncompleta` verifica regras, unidade e preço; a composição da flag não incorpora todos os critérios de `ResumoCompras.completo`. O backend também não interpreta as pendências dentro de `compras_restantes`.

Evidências: `lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart:271` e `:392`, `functions/src/services/calculadora/financeiroCalculadoraService.ts:8`.

**Correção necessária:** separar os estados de quantidade calculável, compra definida, financeiro completo e recomendação revisada. A IA deve receber esses estados e não declarar orçamento resolvido enquanto existir a pendência relevante.

**Aceite:** disponibilidade ausente, sobreposição, compra sem registro financeiro ou consulta incompleta bloqueiam a conclusão financeira tanto no Flutter quanto no backend.

### 5. P1 — Cobertura de serviço não distingue almoço de jantar

**Reprodução:** cobertura contratada identificada como “Buffet do almoço” para `Arroz|kg|todos`. Ao avaliar arroz no cardápio de jantar, a lista também informa **“Incluído em serviço” e zero a comprar**.

**Causa:** a identidade da cobertura é nome + unidade + público. A seleção é feita a partir de um cardápio, mas o vínculo persistido não identifica essa refeição. A comparação não consegue representar “arroz do almoço, mas não do jantar”.

Evidências: `lib/presentation/modules/calculadora/sections/calculadora_festa_planejamento.dart:43`, `lib/domain/services/revisao_cardapio_service.dart:33`, `lib/domain/services/lista_compras_calculadora_service.dart:116`.

**Correção necessária:** dar escopo à cobertura por evento/cardápio/item ou por serviço explicitamente global. Tratar vínculos antigos ambíguos como pendentes de conferência, com compatibilidade e regras de acesso adequadas.

**Aceite:** cobertura do almoço não elimina compra do jantar. Cobertura de várias refeições exige associação explícita.

### 6. P2 — Contexto do consumo anterior não inclui quantidades dos outros alimentos

**Reprodução:** a porção do feijão muda de 0,05 para 0,5 kg, mantendo nome, papel, receita e estado. A assinatura usada para comparar consumo de arroz permanece **idêntica**.

**Causa:** o contexto registra a identidade e o papel dos demais alimentos, mas não sua porção ou quantidade efetiva. Há comparação conservadora em várias dimensões e frouxa nessa dimensão relevante.

Evidência: `lib/domain/services/consumo_observado_service.dart:31`.

**Correção necessária:** definir um contexto de refeição compatível com o objetivo de aprendizado. Incluir porções/serviços pertinentes ou sinalizar a diferença sem apresentar os eventos como equivalentes. Evitar tanto reutilização indevida quanto filtros tão rígidos que eliminem todo histórico útil.

**Aceite:** uma alteração material na oferta dos demais alimentos não é silenciosamente tratada como o mesmo contexto validado.

### 7. P2 — Percentuais de risco/conforto continuam sem calibração demonstrada

**Inspeção de código:** o fallback atribui risco 30 e conforto 60 ou 80. Na resposta generativa há valores padrão para índices ausentes. O histórico exibe conforto e risco com `%`.

Evidências: `functions/src/functions/calculadora/analisarCalculadoraFestaIA.ts:206` e `:237`, `lib/presentation/modules/calculadora/pages/minhas_simulacoes_calculadora_bottom_sheet.dart:360`.

Esses números não são probabilidades verificadas de falta nem uma medida validada de conforto. A fonte “análise local” não resolve, por si só, a aparência de precisão.

**Correção necessária:** retirar a apresentação probabilística ou identificar os índices como heurísticos com critérios verificáveis. Probabilidade de faltar exige definição do evento previsto, dados e avaliação posterior.

## O que falta para melhorar a qualidade das recomendações

### Referências e receitas

O catálogo contextual local contém cinco referências: arroz, feijão, duas fontes de massa seca e o conjunto de docinhos. Isso é diferente do catálogo de regras administráveis no Firestore, cujo conteúdo publicado não foi inventariado nesta auditoria.

Não há, nesse catálogo local, cobertura contextual equivalente para todas as carnes, bebidas, saladas e sobremesas encontradas em festas. Isso não significa que nenhum cálculo desses itens exista: podem existir regras configuradas, mas sua validade contextual não está comprovada pelo simples fato de terem um coeficiente.

A evolução precisa de referências por receita, papel na refeição, estado, público e ocasião, com procedência e versão. Rendimentos devem continuar sendo medidos para a receita; não inferidos pelo nome. Receitas próprias hoje ficam nas regras/snapshots da simulação; não equivalem a uma biblioteca privada independente de receitas automaticamente reaproveitada em toda festa.

### Consumo observado

Há registro real e uso de mediana privada, não treinamento automático de um modelo preditivo. A festa atual é excluída, repetições por evento são deduplicadas e registros de falta bloqueiam a adoção da mediana. Esses cuidados devem ser preservados.

Ainda faltam avaliação do tamanho e qualidade da amostra, tratamento de valores atípicos, recência e testes de previsão em eventos posteriores. Uma única amostra comparável já pode produzir mediana adotável. A aplicação informa o número de eventos e não promete suficiência, mas isso ainda não oferece calibração de confiança.

### Festa inteira e restrições

Hoje o núcleo operacional trabalha no cardápio selecionado. Uma visão consolidada de todas as refeições deve distinguir convidados presentes em cada serviço, estoque reservado por refeição, cobertura por serviço e custos já considerados. Não basta somar cards de almoço e jantar.

Restrições alimentares e preferências não integram, de forma estruturada, a fórmula auditada. Alertas de adulto/criança/bebê e papéis dos alimentos não comprovam que cada grupo tenha uma refeição adequada. Se essa promessa fizer parte do produto, precisa de requisitos e dados próprios.

### Operação da IA

O controller agenda análise com debounce de 500 ms. Existe descarte de respostas antigas e fallback no servidor, mas descartar a resposta no aplicativo não necessariamente cancela uma chamada já iniciada. A function analisada não mostra cache por versão do cenário ou quota própria por organizador.

Antes de escalar o uso, medir chamadas úteis, latência, custo e incidência de fallback; definir reaproveitamento de análises idênticas e limites de uso. Não é necessário aumentar a quantidade de chamadas para melhorar a inteligência das porções.

### Validação de valor

Os testes técnicos não demonstram redução real de desperdício, ausência de falta, facilidade operacional ou disposição para pagar. O relatório voluntário de sessão existe, mas não constitui um estudo longitudinal.

Avaliar com festas reais: conclusão de uma lista utilizável, dúvidas de unidade/estado, correções, custo entendido pelo organizador e sobra/falta após o evento. Usar os resultados para revisar os coeficientes e a interface, sem preencher lacunas com percentuais artificiais.

## Próxima sequência recomendada

1. Corrigir as cinco pendências P1 e acrescentar regressões completas entre cálculo, compras, orçamento, cobertura e IA.
2. Unificar os estados de completude e garantir que todas as telas contem a mesma história, inclusive o histórico.
3. Resolver os índices não calibrados e o contexto do consumo anterior.
4. Ampliar receitas/referências com procedência e critérios de adequação; definir o que realmente precisa de dado manual.
5. Validar a jornada e as previsões com uso real antes de afirmar suficiência, economia ou aprendizado confiável.

Não recomendo uma nova rodada de funcionalidades amplas ou de layout antes dos pontos 1 e 2. O ganho mais importante agora é o organizador poder confiar que porções, compras, orçamento e explicação estão usando a mesma base.

## Publicação

“Implementado localmente”, “testado tecnicamente” e “disponível em produção” são estados distintos. A decisão anterior de não fazer deploy continua sendo respeitada. Publicação pendente por solicitação do usuário não deve ser confundida com defeito de implementação ou com validação de consumo já realizada.
