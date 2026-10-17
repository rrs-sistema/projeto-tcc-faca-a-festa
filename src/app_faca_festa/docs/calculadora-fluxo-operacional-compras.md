# Calculadora: planejamento e compras

Implementação local em 15/10/2026. Sem deploy, alteração de versão ou gravação de dados de teste no ambiente publicado.

## Experiência entregue

- Sugestões têm acesso direto a **Ver lista de compras**.
- A lista distingue: conferir porção, conferir disponibilidade, confirmar serviço, informar o que já tem, falta comprar, já disponível e incluído em serviço.
- A próxima ação prioriza falta de regra, contexto da porção, disponibilidade incompatível, serviços e disponibilidade ausente. Preços aparecem depois das pendências de quantidade. As demais ferramentas ficam em **Outras opções**.
- O registro **O que já tenho** usa comprado e estoque reservado para aquela refeição. Unidade e estado ficam disponíveis em uma expansão; estado não informado precisa ser confirmado.
- O mesmo registro pode ser acessado no menu do item no cardápio, com resumo visível no item. Não é necessário repetir os dados em cada tela.
- A lista pode ser copiada, incluindo itens que ainda não têm quantidade calculada e pendências. Simulações salvas são identificadas e não permitem registrar disponibilidade real a partir do histórico.

## Regras operacionais

1. Quantidade planejada e confirmação no cardápio não significam compra, pagamento ou disponibilidade.
2. Só se descontam compras e estoque explicitamente registrados para a mesma identidade, público, unidade e estado. Alteração incompatível exige revisão, sem conversão silenciosa.
3. Sem registro de disponibilidade, o saldo não é apresentado como zero nem como uma compra certa. O usuário pode registrar zero explicitamente.
4. Falta comprar = máximo entre zero e estimativa total de compra menos comprado menos estoque. Embalagens são arredondadas depois desse desconto.
5. Cobertura explícita de um único serviço contratado dispensa compra adicional para o item integralmente coberto. Orçamento sem contratação e coberturas duplicadas exigem conferência; pagamento isolado não comprova entrega.
6. Compra e preparo/serviço usam as bases já configuradas no motor; cru e pronto diferentes exigem rendimento medido. O rótulo distingue base de preparo cru/seco de quantidade pronta para servir. Não se presume rendimento culinário por nome.
7. O custo da compra pendente só aparece com preço informado. Esse custo não grava despesas, pagamentos ou contratação.
8. A origem da porção aparece como descrição (planejamento, contexto, rendimento medido ou histórico), sem inventar porcentagem de confiança. Ela não comprova suficiência do cardápio.

## Persistência e compatibilidade

- Campo opcional `disponibilidade` no item do cardápio, com comprado, estoque, unidade, estado e identidade na data do registro.
- Documentos antigos continuam legíveis. Salvamentos sem disponibilidade não apagam o campo existente em operações com merge.
- Edição geral de item agora preserva o restante da entidade, inclusive quantidades e disponibilidade.
- Sincronização da calculadora inclui mudanças de disponibilidade. Simulações preservam esse registro no snapshot; dados atuais não substituem o histórico silenciosamente.
- Gravação pela calculadora verifica alterações no planejamento e usa o item atual antes de salvar.
- Regras de acesso existentes preservadas; nenhuma permissão nova ou nova coleção.

## Verificação

- Suíte de calculadora e cardápios: **75 testes aprovados** (62 anteriores e 13 novos).
- Jornada real de widgets: estimativa de 5,50 kg, comprado 2 kg e estoque 1 kg resulta em 2,50 kg a comprar; planejamento e confirmação permanecem inalterados. Snapshot preserva a compra.
- Testes de embalagem após desconto, estoque excedente, NaN/negativos, dados antigos, mudanças de unidade/estado/público, confirmação sem compra, serviço não contratado e cobertura duplicada.
- Formulário testado com fonte ampliada, teclado e falha de gravação. Jornada e formulário reexecutados após os ajustes finais de apresentação.
- Análise estática dos componentes alterados sem problemas. Capturas locais em `.dart_tool/qa-calculadora/`.

## Avaliação de valor com usuários

A entrega facilita a conclusão da lista e evita confundir intenção com compra. Redução real de desperdício, retenção e disposição para pagar ainda precisam ser medidas com uso real; não foram presumidas a partir dos testes. Métricas sugeridas para essa validação: conclusão da lista, tempo até a lista utilizável, correções de quantidade e relatos de sobra/falta. Nenhuma coleta adicional de telemetria foi introduzida.
