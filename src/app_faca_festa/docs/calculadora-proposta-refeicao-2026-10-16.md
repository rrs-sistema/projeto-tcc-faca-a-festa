# Proposta inicial de refeição — 16/10/2026

## Resultado

A calculadora passa a apresentar uma proposta local de quantidades antes dos formulários avançados. O usuário pode conferir poucas escolhas materiais, acompanhar o recálculo e usar as regras no cálculo. A proposta não registra compras, não confirma quantidades finais e não altera orçamento ou cobertura de serviços.

Esta etapa contém somente alterações locais. Não houve novo deploy, publicação do aplicativo ou alteração do evento real.

## Fluxo

1. No passo de sugestões, selecionar o cardápio. Público e estoque ficam recolhidos, com o total de pessoas visível.
2. A proposta mostra imediatamente quantidades por serviço, com a reserva atual, distinguindo alimento cru, seco e pronto. Não exige preços nem histórico anterior.
3. Em **Conferir e usar proposta**, responder somente às escolhas pertinentes aos itens presentes. A prévia recalcula no próprio modal.
4. Confirmar em **Usar no cálculo**. Quando há um item não resolvido, o botão identifica a proposta parcial. O fluxo existente de salvar simulação e revisar/aplicar sugestões continua disponível.
5. Fontes, hipóteses e parâmetros técnicos ficam em **Premissas e fontes**. Modos de planejamento e edição completa ficam em **Ajustes avançados do cálculo**. O resumo financeiro continua visível fora dessa área recolhida.

## Raciocínio e perguntas

| Situação | Proposta e decisão material |
| --- | --- |
| Churrasco + arroz + macarrão | Churrasco como principal, arroz e massa como acompanhamentos. Propõe compartilhar a porção dos dois acompanhamentos, explicitando 50% da referência de cada. Uma única escolha permite manter as porções inteiras. Essa divisão é uma hipótese do produto, não uma proporção validada pela fonte ou por consumo real. |
| Massa sem churrasco | Mantém a referência inteira de massa como principal. Não reduz porções apenas porque existem dois alimentos. |
| Públicos diferentes | Não divide acompanhamentos entre faixas de público ou destinos alimentares diferentes. Mantém a conferência de grupos e receitas necessária para necessidades alimentares. |
| Cachorro-quente | Pergunta papel na refeição e tamanho. Tradicional e grande usam referências editoriais distintas. Mini/tamanho próprio pede uma única porção numérica adicional; não presume equivalência física entre mini e tradicional. |
| Frutas | Propõe peso da parte comestível cortada. Pergunta se é complemento ou sobremesa principal e como será obtida. Não converte genericamente a mistura em peso de feira. |
| Carne/frutas prontas | Pode escolher comprar já pronto para servir. Para compra crua/inteira, só solicita rendimento se essa opção for escolhida. Sem rendimento medido, mantém a quantidade pronta disponível e sinaliza que a compra ainda não foi convertida. |
| Receita própria | Regras ajustadas explicitamente, receitas identificadas e seu grupo de composição são preservados. Propostas não sobrescrevem silenciosamente porções ou preços existentes. |
| Nome desconhecido ou unidade já definida incompatível | Mantém a pendência localizada. Não inventa uma referência para qualquer nome nem converte unidades já planejadas à força. Os demais itens podem receber proposta parcial. |

O reconhecimento inicial cobre churrasco, arroz, massas secas e aliases conhecidos, frutas/salada de frutas e cachorro-quente. Outras referências já existentes são preservadas. Não é um classificador universal baseado em LLM. O motor local realiza decisões reproduzíveis; a IA generativa continua como assistente analítico, sem poder inventar preço, perda ou consumo observado.

## Proteções

- A prévia também funciona quando não existe regra remota para nenhum dos itens, nem cálculo anterior — caso de frutas ou cachorro-quente no primeiro uso.
- Preço ausente deixa custos incompletos; não impede gerar ou usar quantidades. Não houve implementação de busca de preços nesta etapa.
- A identificação de bebê não gera porção automática nas novas referências. A alimentação deve ser confirmada com responsáveis.
- Peso pronto para servir não é automaticamente uma compra crua/inteira. A lista de compras pede conferência enquanto a conversão estiver indefinida.
- Preços e embalagens anteriores só são aproveitados quando unidade e estado de compra continuam compatíveis.
- Alterar a festa, o público, a refeição, o perfil, a reserva, a duração ou os dados enquanto o modal está aberto invalida sua confirmação. Histórico não pode ser sobrescrito por esse fluxo.
- Escolhas e regras adotadas são serializadas no snapshot da simulação. Propostas não salvas permanecem somente na sessão, como os demais ajustes do cálculo.
- Edição manual posterior torna a regra própria, retira a faixa da proposta e protege a nova porção de regeneração automática.
- Fontes indicam a natureza culinária/editorial da referência. Faixas não são intervalos estatísticos e não comprovam suficiência.

## Fontes e escolhas do produto

Conferidas em 16/10/2026:

- [SENAR-PR, A arte do churrasco, 2025, p. 11](https://www.sistemafaep.org.br/wp-content/uploads/2026/01/PR.0391-A-arte-do-churrasco-basico_web.pdf#page=13): referência de total de carnes já assadas. Não aplicada separadamente a cada corte nem como peso cru.
- [Cristal Alimentos](https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/): arroz cru como acompanhamento e distinção da massa seca como principal/acompanhamento.
- [Barilla](https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa): referência da porção de massa seca. Sua aplicação parcial junto de arroz é uma hipótese explicitada pelo produto, confirmável no modal.
- [Guia Festa Brasil — cachorro-quente](https://guiafestabrasil.com.br/quantidade-de-cachorro-quente-para-festa/): referência editorial de unidades conforme função e tamanho. Não é pesquisa de consumo do aplicativo nem comprovação nutricional.
- [Guia Festa Brasil — frutas](https://guiafestabrasil.com.br/quantidade-de-frutas-para-festa/): referência editorial da parte comestível conforme função, com diferenciação de crianças. Não foi adotado rendimento genérico da mistura.

Pontos centrais das faixas são usados para formar uma primeira proposta. Os pesos infantis, a divisão sugerida e a reserva são premissas exibidas; não equivalem a uma garantia de consumo. Bebês recebem peso zero nas novas referências. A repetição de refeições segue o número de serviços já informado, sem multiplicação pela duração total do evento.

## IA e preços

O prompt local passou à versão 1.7.0: interpreta `proposta_contextual`, respeita `proposta_respostas` e reconhece `proposta_apenas_servir`. Não reaplica divisão nem inventa perdas ou preços. Esta versão do prompt ainda não foi publicada nesta etapa.

Uma busca de preços é tecnicamente possível como etapa posterior. Precisa distinguir produto, unidade, embalagem, localidade, disponibilidade e data da oferta, apresentando origem e validade da consulta. Não deve transformar resultados incompatíveis em preço confirmado. Não foram incluídos valores fixos ou chamadas a fornecedores de preços nesta implementação.

## Verificação

- 16 novos testes de proposta: composição, preservação de receitas/grupos, unidades, público por refeição e grupo alimentar, ausência de preço/base remota, rendimento, edição manual, concorrência e histórico.
- Interface: escolhas recalculam e confirmam; mini usa entrada decimal; confirmação acessível com teclado em tela pequena; cancelamento preserva regras anteriores.
- Jornada existente ajustada à nova ordem visual e aprovada, incluindo edição de porção, compras, disponibilidade, estoque central, receita e cobertura.
- Capturas verificadas: `.dart_tool/qa-calculadora/proposta-refeicao-mobile.png` e `proposta-dialog-mobile.png`. São renderizações de testes, não nova instalação no aparelho.
- Replay local dos dados já consultados do evento real de 37 pessoas: os seis itens dos três cardápios receberam referência (incluindo frutas e cachorro-quente), prévia e cálculo adotado coincidiram, e o financeiro permaneceu incompleto. Não houve gravação no Firestore nem chamada à IA nesse replay. As quantidades eram hipóteses de teste, não um plano aprovado para execução.
- Backend: verificações TypeScript, financeiro, autorização, fallback e limites aprovadas.
- Análise estática das áreas alteradas sem problemas.

A suíte completa final aprovou **457 testes**, incluindo os 16 novos casos. O resultado está registrado em `.dart_tool/calculadora-proposta-suite-final.log`.

## Publicação posterior do backend

Após o relato do erro no primeiro salvamento, o prompt 1.7.0 foi publicado na função da calculadora, e as regras receberam uma correção compatível com o app existente. O aplicativo continua sem publicação. Ver [correção do primeiro salvamento](calculadora-primeiro-salvamento-2026-10-16.md).
