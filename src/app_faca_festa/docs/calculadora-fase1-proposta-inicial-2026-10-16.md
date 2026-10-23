# Entrega 1 — proposta inicial do evento

16/10/2026. Alterações locais. Nenhum deploy de aplicativo, função, regras ou site.

## Comportamento implementado

O bloco “Seu plano do evento” substitui a prévia isolada da refeição e vem antes dos ajustes técnicos. Reúne os cardápios ativos do evento, calcula cada destino com seu próprio público e preserva receitas e respostas já registradas. Não troca o destino aberto para montar a visão geral.

Ao conferir um destino existente, o editor abre a proposta correspondente pelo ID. Itens sem referência permanecem visíveis com acesso ao ajuste. A prévia não cria cardápios, compras, compromissos ou pagamentos. O fluxo de revisão por destino permanece disponível; o executor agrupado pertence à entrega 2.

Sem cardápio e com consulta concluída, apresenta um exemplo inicial: churrasco quando o próprio tipo declara churrasco, ou lanche como hipótese explícita nos demais casos. Os números vêm do motor de propostas existente, não de geração livre. O formato pode ser trocado por lanche, churrasco, coquetel ou base de acompanhamentos. Após revisão, a proposta pode criar cardápio e histórico privado num evento salvo com público informado. Não cobre automaticamente todos os formatos de evento e informa que bebidas e demais serviços precisam ser considerados. Durante carregamento/falha da consulta não apresenta um cardápio substituto como se o evento estivesse vazio.

## Matriz de entrada

| Entrada | Comportamento |
| --- | --- |
| Tipo e orçamento | Formato inicial de exemplo; público pendente e limite do evento visível |
| Tipo, orçamento e público | Quantidades da proposta; criação após revisão em evento salvo; premissas e lacunas explícitas |
| Tipo, orçamento e cardápio | Destinos existentes e porções; público pendente quando ausente |
| Tipo, orçamento, público e cardápio | Prévia de todos os destinos, respeitando públicos próprios e receitas |
| Sem orçamento | Proposta quantitativa, sem afirmar cabimento financeiro |
| Consulta incompleta | Pendência explícita; não confunde ausência de carregamento com ausência de cardápio |

Quantidades mostram a medida (cru/seco/pronto). Quando só há peso pronto para servir, a tela informa que a compra ainda não foi convertida. Um cardápio compartilhado não é multiplicado pela quantidade de refeições. Grupos alimentares são analisados pelo motor existente, sem inferir adequação de receitas pelo nome.

## O que esta entrega ainda não encerra

O incremento inicial não encerrava a entrega 1. A continuação abaixo implementa rendimentos de referência, capacidade por verba de alimentação e priorização das perguntas. A continuação final desta entrega amplia o catálogo e permite materializar o exemplo inicial, conforme a seção abaixo. O executor entre estoque, ingredientes e tarefas continua na entrega 2. Busca externa de preços continua fora do escopo.

Não há alegação de 70%–80% de redução de trabalho. A linha de base técnica e a instrumentação foram complementadas na revisão da entrega 0; a avaliação com usuários continua distinta dos testes automatizados.

## Validação do primeiro incremento

Naquele incremento, a suíte Flutter completa teve 489 testes aprovados. Análise estática dos módulos alterados sem problemas. Os testes incluem as quatro combinações de entrada, consulta incompleta, público inválido, público específico por destino, preservação de receita, isolamento entre cardápios/eventos, item desconhecido, grupo alimentar, escopo compartilhado e tela de 320 × 568 com texto ampliado. O teste da jornada móvel também exercita a abertura de uma proposta a partir da visão geral e os fluxos operacionais existentes.

Logs locais: `.dart_tool/calculadora-fase1-suite-final.log`, `.dart_tool/fase1-analysis.log` e `.dart_tool/fase0-gravacao-test.log`. A captura da jornada foi inspecionada visualmente. Nenhum dado do evento real foi alterado.

## Continuação — compra, capacidade e perguntas decisivas

### Rendimento de referência

Ao escolher preparar o churrasco, o organizador pode indicar um único tipo de carne: sem osso, linguiça, frango com osso ou carne com osso. A referência usa, respectivamente, fatores estimados de 0,70; 0,50; 0,50; 0,45 kg prontos por kg cru. São cenários conservadores derivados dos limites de perdas citados pelo [SENAR-PR, 2025, p. 11](https://www.sistemafaep.org.br/wp-content/uploads/2026/01/PR.0391-A-arte-do-churrasco-basico_web.pdf#page=13), consultado em 16/10/2026. Não são rendimentos medidos da receita e não são garantia de resultado.

A opção não atribui um fator único a misturas de carnes ou frutas. Nesses casos, permanece a possibilidade de informar rendimento próprio ou calcular apenas a porção pronta. A lista de compras reconhece uma referência somente se ID, fator, nome, unidade, estados e fonte forem compatíveis. Alterar os dados não mantém uma referência válida por simples presença da marcação. A edição manual remove a atribuição estimada quando o contexto muda; medição própria continua distinta.

### Capacidade pela verba dos alimentos

“Simular verba dos alimentos” exige uma verba explícita e preços compatíveis. Não copia o orçamento inteiro do evento para alimentação. A verba é preservada no snapshot privado, no rascunho e no histórico, e é reiniciada ao preparar outro contexto. Não altera o público efetivo do evento.

O resultado é uma capacidade teórica de compra integral dos itens selecionados para um cenário de adultos, usando o mesmo motor, porções, reserva e arredondamento de embalagens. Não desconta estoque, compras ou coberturas de serviços e não representa saldo do evento, presença confirmada ou suficiência da refeição. Frete, preparo e custos não registrados continuam fora dessa conta.

Preço ou referência ausente, consulta incompleta e públicos/grupos/serviços específicos impedem extrapolação. O motor não converte ausência em zero. A busca é limitada a 10.000 adultos; ao atingir o limite, informa “pelo menos”, sem afirmar um máximo inexistente. Uma mudança de contexto invalida o resultado do modal.

### Perguntas por impacto

As alternativas são simuladas no motor. A ordenação prioriza mudança de medida ou possibilidade de compra, embalagens, custo conhecido e variação relativa de quantidade por identidade/unidade. Não soma kg e litros. Uma mudança de embalagem continua relevante mesmo abaixo de 5% de variação. O limiar de 5% e o de R$ 1 para custo são critérios de interface do produto, não limites de exatidão estatística.

Escolhas já aprovadas ficam recolhidas e editáveis. As respostas dadas durante a edição não fazem o campo desaparecer ao digitar. Perguntas numéricas inválidas não são consideradas respondidas. A alteração precisa ser aprovada na proposta existente, que verifica a revisão do contexto antes de aplicar regras; não realiza compras ou pagamentos.

Testes específicos estão em `calculadora_autonomia_fase1_test.dart` e `calculadora_autonomia_widgets_test.dart`. Os logs desta continuação usam o prefixo `.dart_tool/fase1-autonomia-`.

Validação final desta continuação: suíte completa com **500 testes aprovados**, análise estática sem problemas e `git diff --check` sem erros. Os testes incluem alteração de escopo de outro cardápio enquanto o modal está aberto, preservação da verba no rascunho e na vinculação ao evento, exclusão explícita de um item sem exigir preço e referência em tela pequena com texto ampliado. Código e documentação permanecem locais, sem push ou deploy.


## Continuação final — catálogo e criação do cardápio inicial

O conjunto inicial agora oferece lanche, churrasco, coquetel com salgados pequenos e uma base de acompanhamentos. A sugestão automática conserva o comportamento anterior: churrasco quando identificado pelo tipo; lanche como ponto de partida nos demais casos. A escolha do formato fica visível antes de criar. A base de acompanhamentos informa que ainda faltam prato principal e vegetais; nenhum modelo presume atender todas as necessidades do evento.

O catálogo contextual passou a reconhecer feijão de acompanhamento, bolo, docinhos, salgados pequenos e tábua de frios. Nomes ambíguos permanecem pendentes. Receitas próprias continuam protegidas. Porções de variedades do mesmo grupo e público são compartilhadas por hipótese explícita, editável; não se atribui a referência total a cada sabor. Públicos, serviços diferentes ou receitas protegidas impedem a divisão automática. Salgados junto de cachorro-quente exigem porção específica em vez de somar silenciosamente uma referência de coquetel.

Referências consultadas em 16/10/2026: [Cristal Alimentos](https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/) para feijão cru como acompanhamento e [Padaria Brasileira, tabela de encomendas, p. 11](https://padariabrasileira.com.br/wp-content/uploads/2023/11/V7_cardapio_encomenda_19x22cm_FINAL.pdf#page=11) para formatos de festa. As referências representam contextos específicos. Conversão para adultos equivalentes, ponto médio da faixa e divisão entre variedades são premissas do produto, não medições dessas fontes nem comprovação de suficiência alimentar. Preços continuam pendentes quando ausentes.

### Da proposta ao cardápio

Em evento salvo, sem cardápio ativo e com público informado, “Criar cardápio com esta proposta” abre uma revisão do conjunto, com nome editável, quantidades, medida, premissas e fontes. A aprovação cria o cardápio, seus itens e uma simulação privada com resultados e snapshot na mesma transação do Firestore. O histórico restaura as regras e o conjunto criado.

A identidade `plano_inicial_<id do evento>` torna a tentativa repetida identificável. Um conjunto já criado é preservado; colisões e registros órfãos bloqueiam a criação. Não se substituem edições anteriores. O botão fica indisponível durante a gravação e o modal mantém erro e nova tentativa em caso de falha. Uma mudança do contexto local durante a revisão impede aplicar a proposta desatualizada. Um cardápio manual criado simultaneamente por outro dispositivo pode coexistir com a proposta; esta transação não implementa unicidade global de nomes nem trava todos os cadastros do evento.

A criação grava **quantidade sugerida**, mantém quantidade final zero e confirmação falsa. Não cria compra, reserva de estoque, pagamento, contratação, ingredientes ou tarefas. Não grava durante estimativa anterior ao salvamento do evento, consulta incompleta ou histórico aberto.

### Regras e limite de publicação

As regras locais permitem autorizar itens pela existência do cardápio ao final da transação (`getAfter`) e consultar o destino privado inicial ainda inexistente. Uma simulação existente permanece privada. A exclusão de cardápio e itens no mesmo lote continua autorizada pelo documento anterior. Os testes no emulador verificam criação conjunta pelo organizador, bloqueio de outro usuário, privacidade e exclusão conjunta.

**Nenhum deploy foi feito.** Esta criação atômica depende das alterações de regras para funcionar em produção; elas deverão acompanhar a preparação da futura publicação. Não houve alteração dos dados do evento real.

### Escopo posterior

Os dois pontos desta continuação da entrega 1 foram implementados para os formatos descritos. A entrega 2 continua distinta: aprovação de alterações entre módulos, distribuição de estoque, ingredientes consolidados, tarefas vinculadas e replanejamento operacional. Busca externa de preços e a medição da meta de 70%–80% não foram antecipadas.


### Validação final da criação inicial

- Suíte Flutter completa: **511 testes aprovados**; log `.dart_tool/fase1-criacao-suite-final.log`.
- Análise estática dos serviços e módulos envolvidos: sem problemas; log `.dart_tool/fase1-criacao-analysis-final.log`.
- Regras no emulador Firestore com Java 21: aprovadas; log `.dart_tool/fase1-criacao-rules.log`. Nenhuma publicação.
- Onze testes novos cobrem os formatos, referências ambíguas, partilha entre variedades, serviços/públicos diferentes, preservação do contexto, gravação conjunta, repetição com edição anterior, colisões/órfãos, falha de conexão, alteração do público durante a revisão e restauração do histórico.
- Revisão em 320 × 568, texto ampliado e teclado aberto sem overflow. Captura móvel da criação inspecionada visualmente em `.dart_tool/qa-calculadora/criar-cardapio-inicial.png`.
- `git diff --check` sem erros. Alterações locais, sem commit adicional, push, deploy ou mudança no evento real.
