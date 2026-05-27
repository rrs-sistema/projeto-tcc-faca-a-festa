Descrição técnica da melhoria da calculadora

A calculadora do aplicativo Faça a Festa será evoluída para funcionar como um módulo inteligente de estimativa de consumo e orçamento para eventos.

Atualmente, a calculadora permite informar ou recuperar a quantidade de convidados. A melhoria proposta torna esse recurso mais completo, permitindo que o organizador estime gastos e quantidades antes mesmo de cadastrar todos os convidados oficialmente no sistema.

A nova lógica será baseada em três pilares principais:

1. Perfil da festa

O perfil da festa define o padrão de consumo e custo esperado para o evento. O usuário poderá escolher entre opções como:

Econômico;
Padrão;
Premium.

Cada perfil aplica multiplicadores diferentes sobre as quantidades e os custos estimados. Por exemplo, uma festa econômica utiliza quantidades menores e itens mais simples, enquanto uma festa premium considera maior variedade, margem de segurança e custo médio mais elevado.

Com isso, a calculadora deixa de trabalhar com um único cenário fixo e passa a gerar estimativas mais próximas da realidade do usuário.

2. Convidados equivalentes

Nem todos os convidados consomem da mesma forma. Por isso, a calculadora passa a diferenciar adultos, crianças e bebês.

A regra técnica proposta é converter todos os convidados em um número chamado convidados equivalentes.

Exemplo:

Adulto = 100% de consumo
Criança = 60% de consumo
Bebê = 20% de consumo

Assim, uma festa com:

20 adultos
10 crianças
5 bebês

não será calculada simplesmente como 35 pessoas. O sistema fará uma estimativa proporcional:

20 adultos x 1.0 = 20
10 crianças x 0.6 = 6
5 bebês x 0.2 = 1

Total equivalente = 27 convidados

Essa abordagem melhora a precisão da estimativa, evitando exageros ou cálculos abaixo do necessário.

3. Estimativa financeira

Após calcular os convidados equivalentes, o sistema poderá estimar os itens necessários para a festa e seus respectivos custos.

Cada item terá uma regra de cálculo, como:

Salgadinhos: 12 unidades por convidado equivalente
Docinhos: 6 unidades por convidado equivalente
Refrigerante: 600 ml por convidado equivalente
Bolo: 100 g por convidado equivalente

A estimativa financeira será gerada multiplicando:

quantidade calculada x valor médio do item

Exemplo:

324 salgadinhos x R$ 0,90 = R$ 291,60
162 docinhos x R$ 1,20 = R$ 194,40
3 kg de bolo x R$ 80,00 = R$ 240,00

Com isso, o usuário terá uma visão antecipada do custo aproximado da festa, podendo ajustar o perfil, a quantidade de convidados ou os itens antes de fechar fornecedores.

Benefício para o projeto

Essa melhoria agrega valor ao sistema porque transforma a calculadora em uma ferramenta de apoio à decisão. O usuário não apenas informa convidados, mas consegue prever despesas, comparar cenários e planejar melhor o orçamento do evento.

Além disso, a separação da lógica em modelos específicos melhora a organização do código, facilita futuras manutenções e permite que novas regras sejam adicionadas sem comprometer a estrutura atual do aplicativo.