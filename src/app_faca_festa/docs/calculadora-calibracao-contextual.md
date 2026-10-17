# Calibração contextual da calculadora — 1.0.13+15

## Entrega

A calculadora passa a oferecer referências por contexto, rendimento medido da receita e calibração retrospectiva com registros privados do organizador. Esses recursos não pressupõem a composição das 26 pessoas das imagens nem preenchem consumo real com a quantidade que o aplicativo sugeriu.

Na etapa de sugestões, os atalhos **Calibrar porções do cardápio** e **Registrar consumo, sobra e falta** permitem escolher o item. Seus detalhes também permitem comparar com o consumo anterior.

## Referências iniciais com contexto

| Alimento/contexto | Medida de referência antes da reserva | Estado |
| --- | --- | --- |
| Arroz como acompanhamento | 50–60 g por pessoa | Cru |
| Feijão, classificado no aplicativo como acompanhamento | 50–70 g por pessoa | Cru |
| Macarrão como principal | 100 g por pessoa | Seco |

Fonte: [Cristal Alimentos — planejamento de arroz, feijão e macarrão](https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/), consultada em 15/10/2026. A associação do feijão ao papel de acompanhamento é uma classificação editorial do aplicativo; a fonte fornece sua referência de quantidade crua. São orientações culinárias iniciais, não resultados de validação empírica do evento.

O organizador define o papel na refeição, busca a referência e escolhe uma porção dentro da faixa publicada. A aplicação depende dessa escolha. Não há divisão automática pelo número de acompanhamentos. Nomes ambíguos ou receitas diferentes, como “massa” ou “arroz doce”, não recebem essas referências por aproximação do nome.

Não foi localizada uma referência quantitativa primária suficiente para atribuir automaticamente uma porção à massa como acompanhamento no almoço das imagens. Nesse contexto o aplicativo informa a ausência, permite definir a porção da receita e pode usar consumo observado compatível no futuro. A regra genérica antiga não é apresentada como uma nova referência validada.

Essas referências contextuais acompanham a versão do aplicativo; o catálogo administrativo anterior do Firestore foi preservado. O módulo é extensível, mas esta entrega não cobre automaticamente todo alimento e toda receita.

## Compra, preparo e rendimento

Uma referência crua/seca pode ser convertida para compra pronta somente com medição informada do mesmo alimento antes e depois do preparo. A porção é convertida para o estado pronto e não volta a ser dividida pelo mesmo rendimento. Ao mudar a base de compra, um preço anterior incompatível é limpo para conferência.

Exemplo de verificação da fórmula, sem constituir rendimento recomendado: se o organizador mede 1 kg antes e 3 kg depois, uma referência de 50 g antes corresponde a 150 g depois. Para comprar pronto, a base será 150 g e o rendimento de compra será 1. Para comprar o ingrediente e preparar, a ferramenta de rendimento mantém a conversão explícita entre porção pronta e compra.

O rendimento é da receita informada. Não se aplica um fator universal de arroz, massa ou carne. A medição usa a mesma unidade, sem incluir apenas no peso final molho ou ingredientes que não estavam na base medida.

Referências contextuais não recebem o multiplicador genérico de quantidade dos perfis Econômico/Padrão/Premium. A reserva escolhida permanece separada. Quando a fonte oferece uma faixa, o card mostra os extremos calculados com a reserva; a faixa não é um intervalo estatístico.

Para alimentos e bebidas, os pesos de crianças e bebês podem ser ajustados por item, inclusive para zero quando aquele público não consumirá o alimento. Descartáveis continuam usando contagem física de pessoas, independentemente desses pesos. Os padrões antigos de 60%/20% são identificados como premissas; não foram promovidos a recomendações nutricionais por idade.

## Registro após a festa

O formulário recebe identificação da receita, participantes reais, duração observada, número de serviços, quantidade pronta disponibilizada, sobra pronta não servida, desperdício medido nos pratos e indicação de falta. O consumo observado é:

`disponibilizado pronto − sobra pronta − desperdício pronto`.

Não se subtrai sobra pronta de peso cru comprado. Para relacionar a medição pronta a uma regra crua/seca, é obrigatório informar o rendimento medido. Valores negativos, não finitos, público sem consumidores e sobra/desperdício superiores ao disponibilizado são rejeitados.

Ao salvar, a simulação é persistida e o registro é gravado separadamente no campo `consumo_observado` do documento `calculadora_festa/{id}`. O registro conserva sua regra e seu contexto. O salvamento comum da simulação não apaga as medições. Um novo registro do mesmo item na mesma simulação substitui o anterior; não foi implementado um histórico de revisões de cada medição.

O último registro encontrado da festa pode ser consultado no histórico de consumo, mas não entra na amostra usada para propor porções para ela mesma. Não foram criados registros fictícios em produção.

## Como a calibração usa os registros

A consulta usa somente o organizador autenticado e as 100 simulações com registro de consumo mais recente. O índice composto correspondente foi criado individualmente e confirmado como `READY`, sem remover ou alterar outros índices.

O comparador exige receita/preparo, papel, estado e unidade da porção, refeição, tipo de evento, duração, serviços, composição do cardápio, participação, pesos de público e proporção de adultos/crianças/bebês compatíveis. Itens sem regra também fazem parte da identidade do cardápio, para que sua presença não seja ignorada. A identificação dos preparos depende do cadastro correto pelo organizador; não se infere que duas receitas têm os mesmos ingredientes somente por seus nomes.

Simulações repetidas de um mesmo evento contam como um evento; prevalece a medição mais recente encontrada para o contexto. A festa em consulta é excluída da amostra. As proporções de público precisam coincidir; não foram introduzidos limiares arbitrários de similaridade etária.

A porção proposta para preparo usa `disponibilizado pronto − sobra pronta não servida`, preservando o desperdício medido nos pratos. Assim o aplicativo não presume que esse desperdício desaparecerá na próxima festa. O consumo líquido e o desperdício continuam registrados separadamente. A mediana dessa base normaliza rendimento medido, público efetivo, serviços e participação; a reserva futura continua separada. Não estima quanto faltou. Se houver falta em um evento comparável, esse evento não gera porção de suficiência e a adoção da mediana fica bloqueada para revisão. Sem dados comparáveis, a calculadora informa a ausência.

A proposta mostra o número de eventos e depende de escolha explícita. Adotá-la mantém a reserva e desativa multiplicadores genéricos de quantidade por perfil e duração, evitando reaplicar fatores já refletidos no consumo real. A sugestão não substitui a porção se os dados da tela mudarem durante a consulta.

É calibração descritiva dos registros consultados. Não há treinamento de modelo de aprendizado de máquina, garantia estatística, avaliação nutricional individual nem dados empíricos coletados nesta sessão para validar o almoço das imagens.

## Segurança e verificação

Os registros ficam no documento privado da simulação e usam suas regras de acesso existentes. A gravação transacional confirma o evento e o organizador; a consulta filtra o usuário autenticado. Os testes no emulador confirmaram consulta/gravação pelo dono e rejeição de outra conta ou acesso sem autenticação. Não houve ampliação das permissões do Firestore.

62 testes Flutter aprovados; testes TypeScript/callable aprovados; análise estática dos arquivos alterados sem problemas. Foram exercitados conversão sem duplicar rendimento, faixa de compra, público ajustável, dados impossíveis, falta, repetição do evento, mudança de contexto, formulário móvel e preservação das observações no salvamento comum.

O prompt da IA foi atualizado para 1.4.0 para explicar fontes, faixas, rendimento e observações sem atribuir garantias indevidas. A IA continua interpretando os cálculos e os dados disponíveis.

As validações móveis usam Flutter com repositórios de teste. Não houve instalação em aparelho físico, medição de comida real nem geração autenticada de análise com o provedor em produção nesta sessão. Os artefatos e a conferência pública ficam registrados no documento de publicação da versão.
