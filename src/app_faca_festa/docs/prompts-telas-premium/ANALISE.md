# Análise das telas — Ergonomia e intuitividade

Avaliação heurística das seis capturas fornecidas e leitura das páginas Flutter correspondentes em 21/10/2026. Não é teste com usuários nem auditoria da exatidão financeira. As falhas técnicas das capturas foram excluídas do diagnóstico de infraestrutura, conforme pedido.

## Leitura geral

As páginas têm estrutura funcional, mas pouca hierarquia entre consulta, decisão e lançamento. Na largura de desktop, os campos atravessam quase toda a janela; ao mesmo tempo, números importantes ficam pequenos em frases ou chips. Formulários abertos criam densidade em uma área e grandes vazios em outra. A aparência depende de uma app bar colorida, sem uma organização equivalente do conteúdo.

Ergonomia envolve esforço de leitura, deslocamento visual, alcance das ações, uso de teclado e adaptação ao tamanho de tela. Intuitividade envolve reconhecer o contexto, saber o próximo passo e antecipar o efeito de cada comando. A melhoria precisa atingir os dois aspectos; alterar somente cor e borda não resolve.

## Diagnóstico por tela

| Tela | Ergonomia observada | Intuitividade observada | Direção |
|---|---|---|---|
| Financeiro da empresa | Métricas pequenas e juntas; blocos longos; alertas repetidos; campos extensos | Filtro exige ID; resultado expõe fórmula; lançar e consultar se misturam | Síntese com quatro métricas, resultado/caixa legíveis, registros sob demanda |
| Comissões do administrador | Simulação e cadastro ocupam topo inteiro; botões excessivamente largos | Não diferencia acompanhar cobrança, criar regra e experimentar percentual | Cobranças como entrada; políticas e simulador em áreas próprias |
| Financeiro administrativo | Filtros verticais dominam a tela; pouco uso da grade desktop | Fornecedor por ID; eixo temporal pouco explicado; exportação pode sugerir download enquanto copia CSV | Barra compacta, KPIs executivos, eventos em tabela/lista e exportação fiel |
| Estoque da empresa | Cadastro permanente antecede consulta; vazio não orienta | Termos técnicos precedem tarefa; diferença entre saldo, reserva e consumo pouco hierarquizada | Estoque consultável primeiro, Novo item sob demanda e operações contextualizadas |
| Comissões do pagador | Reutiliza composição administrativa pouco adequada | Mostra seção sem permissão e prioriza simulação, em vez de cobranças próprias | Extrato do usuário, detalhe da regra aplicada e simulação secundária |
| Financeiro do organizador | Filtros quebram em várias linhas, contadores antecedem conteúdo e área fixa reduz espaço da lista | Eixo muda sem mostrar opções; “Linhas” é ambíguo; zeros podem parecer confirmados em falha | Filtros sob demanda, cards úteis por evento e detalhe coerente, com referência temporal honesta |

As capturas de consulta com falha não permitem concluir que tabelas ou indicadores estão ausentes no código. Os prompts pedem verificar os contratos reais e construir também os estados preenchidos em testes/previews isolados.

## Arquitetura de informação proposta

A ordem comum é contexto, síntese, prioridades e detalhe. A ação principal depende da tarefa:

- Fornecedor financeiro: conferir valores e registrar custo/recebimento.
- Administrador de comissões: acompanhar cobrança, depois gerir política.
- Administrador financeiro: avaliar movimento e receita própria, depois investigar evento.
- Fornecedor de estoque: localizar item e disponibilidade, depois cadastrar/movimentar.
- Pagador de comissões: entender saldo e cobrança, depois consultar cálculo.
- Organizador: localizar evento, entender contratado/pago/saldo e verificar se a previsão cabe no limite.

Desktop usa grid com largura máxima confortável, formulários delimitados e tabelas para comparação. Celular reorganiza em uma coluna com resumo, ações acessíveis e cards; não comprime uma tabela grande até ficar ilegível.

## Linguagem e transparência

| Texto/controle atual | Proposta de apresentação | Informação preservada |
|---|---|---|
| ID do evento | Seleção por nome/data, quando há fonte autorizada | Identificador continua interno |
| resultado_direto = ... | Valor e “Como é calculado” | Fórmula e componentes continuam consultáveis |
| Componentes ausentes | “Faltam informações para concluir o resultado” | Natureza parcial e itens faltantes ficam próximos ao valor |
| Obrigações | “Cobranças” na experiência de comissões | Entidade e regra de obrigação não mudam |
| Políticas só no admin | Omitir seção administrativa na visão do pagador | Mostrar termos do próprio contrato quando autorizados |
| Exportar/ícone de download | “Copiar CSV” se esse for o comportamento real | Mesmos dados e filtros |
| Reserva não é consumo nem pagamento, no topo | Explicação curta junto à ação correspondente | Efeito da operação continua explícito |

A transparência não deve desaparecer para deixar a tela “limpa”. Deve aparecer junto da decisão relevante, com divulgação progressiva dos detalhes técnicos.

## Coerência visual

O projeto já possui `FornecedorPremiumPalette`, `PremiumSectionShell`, componentes administrativos e tema. Os prompts orientam inspecioná-los, preservar a identidade por perfil e extrair somente os componentes necessários. A implementação não precisa de uma etapa global anterior.

Priorizar tipografia, contraste, alinhamento de números e espaçamento. Acentos discretos: índigo no fornecedor, verde-petróleo na administração. Cores semânticas são acompanhadas de texto/ícone. Gráficos só quando ajudam uma pergunta e possuem dados reais.

## Como verificar a melhoria

Os prompts usam cenários de tarefa, não pontuações subjetivas inventadas:

- Localizar contratado/recebido/saldo sem abrir ajuda.
- Encontrar evento/fornecedor sem memorizar identificador, quando a fonte já permite.
- Cadastrar item sem atravessar formulário para consultar o estoque.
- Distinguir simulação, política inativa e cobrança real.
- Saber se o dado é parcial, vazio ou indisponível.
- Abrir detalhe, cancelar e retornar com foco preservado.
- Usar teclado e texto ampliado, sem perda de ação ou valor importante.

A execução futura verificará larguras 360, 390, 768, 1280 e 1920 px, além de texto a 200%. Essas são metas de QA, não testes já realizados. Testes com usuários, se feitos depois, poderão medir conclusão de tarefa, erros, necessidade de ajuda e tempo; não há números de sucesso coletados nesta análise.

## Limites

Este pacote não cria interfaces, não corrige erros das capturas e não muda regras comerciais. Ele fornece seis prompts de implementação focados na experiência, com critérios verificáveis e preservação do comportamento financeiro.


## Complemento: organizador no celular

A sexta captura reforça a necessidade de reduzir o topo fixo. Busca, situação comercial, escolha de referência temporal e contadores ocupam parcela relevante da altura antes do resultado. A proposta leva opções adicionais para um painel de filtros, mantendo contexto da seleção, cards legíveis e retorno do detalhe com posição preservada.

A leitura do controller indica que a referência de pagamento pode filtrar eventos pela última data de pagamento, sem recortar todos os lançamentos mensalmente. Também indica que a situação comercial seleciona eventos contendo linhas naquele estado. O redesign precisa confirmar esse comportamento e descrevê-lo corretamente: não pode transformar o rótulo em promessa de extrato mensal ou de totais restritos a contratos selecionados. Corrigir essa regra financeira está fora deste pacote.

No detalhe já existem limite, previsão final, folga/reserva, contratos, pagamentos e simulação. O prompt 06 inclui sua reorganização visual para manter continuidade com a lista, sem mudar cálculos ou fazer novas operações financeiras. Dados parciais e indisponibilidade devem ser evidentes, mas as causas do erro técnico da captura continuam excluídas do escopo.
