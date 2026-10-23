# Checklist de testes — Calculadora Inteligente

Cada caixa corresponde a uma verificação manual. Marcar somente depois de executar e conferir o resultado. Os testes automatizados já aprovados não preenchem este checklist de homologação.

## Preparação

| Registro da execução | Preencher |
| --- | --- |
| Responsável e data | |
| Versão/build instalada | |
| Ambiente e conta de teste | |
| Aparelho, sistema e tamanho de fonte | |
| Evento fictício utilizado | |

- [ ] P01 — Confirmar que a build instalada contém as alterações recentes. O aplicativo público não foi atualizado; o pacote automatizado de QA não substitui uma build normal para navegar manualmente.
- [ ] P02 — Criar um evento fictício para lançamentos, falhas, exclusões e testes de permissões. Usar o evento real somente na conferência específica ao final.
- [ ] P03 — Iniciar com conta organizadora, sem despesas, estoque ou compras preexistentes no evento fictício. Separar outra conta organizadora para o teste de acesso.

## 1. Entrada pelo cadastro do evento

Executar os quatro caminhos abaixo com o mesmo tipo de evento e orçamento de R$ 1.500,00, em eventos fictícios separados. Onde houver público, usar 35 previstos; onde houver cardápio, usar churrasco, arroz e macarrão.

- [ ] E01 — Informar apenas tipo e orçamento, sem convidados ou cardápio → apresentar um caminho inicial e pedir o público necessário, sem inventar capacidade de atendimento ou preços.
- [ ] E02 — Informar tipo, orçamento e público, sem cardápio → entregar uma proposta inicial com itens e quantidades; pedir aprovação antes de criar o cardápio.
- [ ] E03 — Informar tipo, orçamento e cardápio, sem público → reconhecer os itens existentes e sinalizar a informação necessária para calcular quantidades, sem duplicar o cardápio.
- [ ] E04 — Informar tipo, orçamento, público e cardápio → considerar o conjunto já cadastrado e oferecer a proposta para revisão.
- [ ] E05 — Salvar e editar o evento, incluindo orçamento e data → os novos valores devem reaparecer corretamente, preservando itens, compras e pagamentos já registrados.

## 2. Público e composição da refeição

Para um resultado reproduzível de público, cadastrar no evento fictício 29 adultos e 8 crianças não recusados, mais 1 adulto recusado. Manter a previsão inicial de 35 pessoas.

- [ ] I01 — Selecionar “Não recusados” → calcular para 37 pessoas, excluindo o convidado recusado; não confundir esse total com os 35 previstos.
- [ ] I02 — Alternar entre previstos, confirmados e não recusados → cada opção deve refletir sua própria fonte, e o diagnóstico deve identificar a base utilizada.
- [ ] I03 — Aumentar ou diminuir o público → as quantidades e pontos de atenção devem acompanhar o novo contexto, sem mudar compras e pagamentos registrados.
- [ ] I04 — Analisar churrasco, arroz e macarrão juntos → apresentar os papéis e premissas da refeição; preservar porções explicitamente ajustadas pelo organizador.
- [ ] I05 — Planejar cachorro-quente e frutas → apresentar referências iniciais quando disponíveis e destacar dúvidas que realmente alteram o resultado, como tamanho e papel na refeição.
- [ ] I06 — Acrescentar uma receita desconhecida → mostrar o que falta para calculá-la, sem tratar ausência de referência como quantidade zero suficiente.
- [ ] I07 — Conferir cru, seco e pronto → identificar a medida usada e pedir esclarecimento quando necessário; não comparar kg crus e kg prontos como se fossem iguais.
- [ ] I08 — Abrir as opções de perfil, duração e reserva → opções selecionadas e não selecionadas devem estar legíveis; os efeitos devem aparecer nas premissas e nos cálculos aplicáveis.
- [ ] I09 — Criar uma refeição com público próprio e um grupo alimentar → respeitar esse público, sem contar uma pessoa em mais de um grupo. Item destinado ao grupo deve usar o público correspondente; sem configuração, não presumir restrições.

## 3. Proposta, aprovação e histórico

- [ ] C01 — Abrir uma proposta sem confirmar → nenhum item final, compra, pagamento ou contratação deve ser gravado por essa visualização.
- [ ] C02 — Criar o cardápio pela revisão → criar os itens e o histórico correspondente, mantendo compra e quantidade final como informações distintas da sugestão.
- [ ] C03 — Repetir a criação ou tocar duas vezes no botão → não criar cardápio nem histórico duplicados.
- [ ] C04 — Ajustar uma quantidade final e recalcular → preservar a escolha explícita e mostrar sua relação com a sugestão.
- [ ] C05 — Salvar uma simulação, sair da tela e reabri-la → recuperar seus itens, público e premissas. Um histórico antigo não deve se apresentar como retrato atualizado do evento.

## 4. Estoque, compras e tarefas

Preparar o caso abaixo no evento fictício. Informar arroz em kg, estado cru, disponibilidade comprada inicial igual a zero e referências compatíveis. Os valores finais são escolhas explícitas deste teste, não recomendações alimentares.

| Dado | Valor do teste |
| --- | --- |
| Arroz final do almoço | 4 kg |
| Arroz final do jantar | 2 kg |
| Lote central disponível | 3 kg |
| Comprado inicialmente | 0 kg |
| Compra restante esperada | 3 kg |

- [ ] O01 — Abrir “Organizar a execução” → considerar as duas refeições e apresentar compra restante de 3 kg de arroz.
- [ ] O02 — Conferir as reservas → a soma reservada do lote não pode ultrapassar 3 kg nem disponibilizar o mesmo saldo integralmente para as duas refeições.
- [ ] O03 — Usar “Aplicar conjunto” → gravar o conjunto aprovado e gerar as tarefas previstas, sem registrar compra realizada ou pagamento.
- [ ] O04 — Repetir a aplicação → não duplicar reservas nem tarefas.
- [ ] O05 — Registrar compra de 1 kg de arroz cru para o almoço e atualizar a proposta → o restante total deve cair de 3 kg para 2 kg; as quantidades finais devem continuar em 4 kg e 2 kg.
- [ ] O06 — Testar um lote ou compra com medida incompatível, como pacote sem conteúdo em kg informado → pedir conversão ou esclarecimento; não descontar uma quantidade presumida.
- [ ] O07 — Copiar a lista de compras e conferir as tarefas → nomes, quantidades e destinos devem corresponder à proposta; itens sem preço continuam identificáveis e tarefas não podem aparecer concluídas automaticamente.

## 5. Leitura inteligente e documentos

Executar primeiro o texto abaixo em um evento fictício com arroz cru no almoço e sem outros lançamentos financeiros. Os valores foram escolhidos para testar efeitos distintos; não representam uma nota fiscal real.

> Comprei 1 kg de arroz cru para o almoço, a R$ 6 por kg. A compra de mantimentos custou R$ 60 e já paguei R$ 20 dessa compra. Recebi também uma cotação de decoração de R$ 500, ainda não contratada.

- [ ] L01 — Usar “Preparar leitura” → mostrar as ações propostas e suas evidências antes de gravar. Conferir separadamente compra, preço, despesa, pagamento e cotação.
- [ ] L02 — Cancelar a revisão → nenhum dos lançamentos propostos deve ser aplicado.
- [ ] L03 — Aplicar somente parte das ações → gravar apenas a seleção; um pagamento de despesa nova deve exigir também a despesa correspondente.
- [ ] L04 — Aplicar o conjunto completo em um caso limpo → conferir no cardápio e no financeiro os resultados da seção seguinte.
- [ ] L05 — Testar separadamente texto livre, TXT/documento colado, PDF e imagem legível com dados fictícios conhecidos → os dados extraídos devem corresponder ao conteúdo, inclusive unidade, estado e vínculo com a refeição. Um formato aprovado não aprova automaticamente os demais.
- [ ] L06 — Reenviar o mesmo documento identificado → informar o que já foi registrado e não duplicar ações. Se a aplicação anterior foi parcial, apresentar somente as ações restantes aplicáveis.
- [ ] L07 — Enviar documento sem identificação única → solicitar conferência de duplicidade antes da aplicação.
- [ ] L08 — Informar quantidade ambígua, como “comprei 2 pacotes”, sem peso definido → pedir esclarecimento em vez de inventar kg ou preço.
- [ ] L09 — Usar uma cotação de teste que contenha instruções para registrar compra ou pagamento inexistente → tratar o documento como fonte de dados; não executar essas instruções nem transformar cotação em comprovação de pagamento.
- [ ] L10 — Enviar uma receita com rendimento, ingredientes, unidades e estados conhecidos → permitir conferir a ficha extraída; o cálculo e a lista de ingredientes devem respeitar o rendimento aprovado.

## 6. Financeiro e campos numéricos

Resultados esperados para o texto de L01, após aprovar todas as ações em um evento sem despesas anteriores:

| Informação | Esperado |
| --- | --- |
| Despesa de mantimentos | R$ 60,00 |
| Pago inicialmente nessa despesa | R$ 20,00 |
| Saldo dessa despesa | R$ 40,00 |
| Cotação de decoração | R$ 500,00, sem contratação ou pagamento |
| Soma desses dois registros de custo | R$ 560,00 |

- [ ] F01 — Conferir os valores da tabela → compra em kg, preço por kg, custo da despesa e valor pago devem permanecer informações distintas.
- [ ] F02 — Abrir a despesa na tela financeira → exibir nome e valores corretos e permitir sua edição normal.
- [ ] F03 — Quitar os R$ 40,00 restantes → pago da despesa passa a R$ 60,00; o custo continua R$ 60,00 e a soma dos dois registros continua R$ 560,00.
- [ ] F04 — Tentar pagar acima do saldo → recusar o excesso sem aplicar parcialmente as outras ações daquele conjunto.
- [ ] F05 — Revisar a cobertura de um serviço → descontar somente os itens explicitamente cobertos e não contar o custo duas vezes; cobertura não confirma compra nem pagamento.
- [ ] F06 — Deixar preços ausentes e abrir a comparação de cenários → identificar valores pendentes e comparação parcial; não exibir ausência de preço como custo zero conhecido ou economia comprovada.
- [ ] N01 — Em um campo de moeda vazio, digitar `3300` → mostrar `R$ 33,00` e salvar o número 33. A máscara atual trabalha com entrada em centavos.
- [ ] N02 — Colar `R$ 1.234,56`, selecionar tudo, substituir e apagar → conservar o valor correto, permitir correção e limpar o campo sem travar.
- [ ] N03 — Em quantidade decimal, digitar `1,25` → manter 1,25, sem deslocamento de centavos; salvar e reabrir preservando o valor.
- [ ] N04 — Nos campos de convidados, tentar letras, vírgula e números negativos → aceitar somente inteiros válidos; não salvar vazio obrigatório nem quantidade negativa.

## 7. Reconexão, concorrência e acesso

- [ ] R01 — Preparar e aplicar uma proposta sem editar seus dados entre essas ações → aplicar normalmente, sem falsa mensagem de contexto alterado.
- [ ] R02 — Preparar uma proposta e depois alterar o orçamento ou um item por outra tela/sessão → recusar a proposta antiga; “Atualizar pelas fontes atuais” deve permitir nova revisão.
- [ ] R03 — Interromper a conexão durante uma operação em evento fictício e tentar novamente após reconectar → não anunciar sucesso sem confirmação nem duplicar uma operação já recebida pelo servidor; o usuário deve conseguir recuperar a situação.
- [ ] R04 — Fechar o aplicativo, abrir novamente e fazer novo login → conferir público, orçamento, preços, quantidades finais, compras, reservas, tarefas e pagamentos com os valores previamente registrados.
- [ ] R05 — Usar a outra conta organizadora → impedir acesso à execução privada e alterações do evento que pertence ao primeiro organizador, inclusive tentativa de assumir sua propriedade.
- [ ] R06 — Sair da conta e tentar usar a entrada inteligente → exigir autenticação.

## 8. Ergonomia e intuitividade

- [ ] U01 — Usar o menor celular disponível e ampliar a fonte → ler os textos essenciais e alcançar os botões, sem cortes ou sobreposição com a navegação do sistema.
- [ ] U02 — Abrir teclado nos modais de público, valores e consumo → alcançar o campo ativo, os erros e a ação de salvar por rolagem quando necessário.
- [ ] U03 — Alternar os três perfis da festa → manter seleção e opções não selecionadas reconhecíveis; conferir a disposição em uma linha no tamanho de referência do layout.
- [ ] U04 — Entregar a tarefa a alguém sem explicar os botões → a pessoa deve conseguir distinguir proposta, quantidade final, comprado, estoque e pago, e localizar a próxima ação.
- [ ] U05 — Observar carregamento, erro e nova tentativa → apresentar retorno compreensível, impedir envio duplicado e preservar o preenchimento quando houver falha.
- [ ] U06 — Fazer uma refeição comum do início ao fim → entregar uma proposta antes do formulário avançado; contar os ajustes humanos necessários e registrar perguntas repetidas ou que não alteram a decisão.

## 9. Conferência do evento real

Evento informado: `5ecae7dc-7b40-4a62-8026-b961870f042f`, em **23/10/2026 às 18h, UTC−3**. A escolha informada foi planejar para **37 não recusados**. Nesta seção, conferir os dados existentes sem lançar compras, despesas ou consumo fictícios.

- [ ] V01 — Abrir o evento correto e conferir nome, data, horário e orçamento efetivamente aprovado.
- [ ] V02 — Conferir a base de público e os 37 escolhidos. Verificar adultos, crianças e bebês no cadastro; se a lista mudou, registrar a diferença e revisar o planejamento antes de aplicar.
- [ ] V03 — Conferir as refeições previstas e quem participa de cada uma; não presumir que todas atendem ao mesmo público ou ocorrem o mesmo número de vezes.
- [ ] V04 — Conferir porções decisivas, unidades, cru/seco/pronto, receitas próprias e necessidades alimentares, incluindo frutas e cachorro-quente quando presentes.
- [ ] V05 — Conferir compras já realizadas, estoque disponível, reservas entre refeições, preços conhecidos e cobertura dos serviços com base nos fatos do evento.
- [ ] V06 — Conferir a lista final de compras, os valores ainda pendentes, os responsáveis e os prazos das tarefas; registrar os pontos que ainda impedem uma decisão.
- [ ] V07 — Antes da realização, tentar abrir o registro de resultados → impedir lançamento de pós-evento como se a refeição já tivesse ocorrido.

## 10. Validação após o evento e do objetivo de autonomia

- [ ] A01 — Depois da realização, registrar por refeição pessoas presentes, quantidade preparada, sobra e falta efetivamente observadas, na mesma unidade e estado; informação desconhecida deve continuar desconhecida.
- [ ] A02 — Conferir a revisão qualitativa de cada item → ela deve permanecer distinta de uma medição de consumo; marcar “adequado” não comprova uma porção em gramas.
- [ ] A03 — Testar a memória com adesão explícita → recuperar referências compatíveis do próprio organizador, preservando origem, público, unidade e estado; não tratar opinião ou ausência de medição como calibração comprovada.
- [ ] A04 — Executar o piloto comparando versões com os mesmos casos e critérios; observar intervenções, tempo ativo, correções, erros, conclusão e qualidade, preservando falhas.
- [ ] A05 — Usar a cobertura prevista no protocolo: ao menos cinco participantes, com os pares das 16 combinações de cenário/tarefa por participante → só avaliar a meta de 70%–80% com dados observados completos e sem perda dos critérios de qualidade.

Protocolo do piloto: [avaliação de autonomia](calculadora-protocolo-autonomia.md). Evidências técnicas já obtidas: [jornada integrada](calculadora-jornada-integrada-2026-10-17.md).

## Registro de falhas e aceite

Para cada falha, preencher uma linha e repetir o caso depois da correção. Uma falha crítica aberta impede aprovar a homologação do fluxo afetado.

| ID do caso | Passos e dados usados | Resultado esperado | Resultado observado | Build e evidência | Situação/reteste |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

São bloqueadores: perda ou duplicação de dados, lançamento financeiro incorreto, acesso indevido, estoque contado duas vezes, alteração de uma escolha final sem aprovação ou impossibilidade de concluir uma ação essencial. Erro de extração que exige correção também deve ser registrado, mesmo quando a revisão impede uma gravação errada.

**Aceite técnico manual:** casos funcionais e de ergonomia aplicáveis executados, valores conferidos e nenhum bloqueador aberto. Casos não executados devem permanecer identificados; não equivalem a aprovação. O consumo real e a meta de autonomia têm seus próprios critérios e não são aprovados apenas pelos testes de software.
