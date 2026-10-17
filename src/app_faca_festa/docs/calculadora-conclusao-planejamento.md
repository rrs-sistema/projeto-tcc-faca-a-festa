# Conclusão da evolução operacional da calculadora

Data: 15/10/2026. Entrega no código local, sem deploy e sem alteração de versão.

## O que foi concluído

| Frente combinada | Implementação disponível |
| --- | --- |
| Consolidar compras e financeiro | Resumo de compras restantes conhecidas, preços/quantidades pendentes, pagamentos pendentes e saldo condicionado à integridade dos dados. |
| Evitar dupla contagem | Conferência explícita de valores já orçados: despesas realizadas, valor fora dos itens do cardápio ou pendência. Mudanças de valor, identidade ou cobertura invalidam a declaração. |
| Considerar a refeição completa | Papéis declarados, ausência de principal em almoço/jantar, alternativas não divididas, grupos com papéis diferentes e participação de adultos/crianças/bebês. Sem redução automática nem certificação nutricional. |
| Ampliar referências | Catálogo publicado ampliado para formatos de massa e conjunto de docinhos; escolha de fonte quando há mais de uma. Receita própria com faixa, contexto e origem identificados. |
| Cenários de economia | Comparação de perfil existente, ajuste de reserva preservando a base, substituição com porção/preço informados e redução de alternativas previamente declaradas. |
| Aprender após a festa | Acesso ao painel de revisão, destaque após a data/finalização, consulta dos registros reais recentes e edição do último registro compatível da mesma festa. Mantida a comparação retrospectiva entre contextos compatíveis. |
| Medir a experiência | Relatório de sessão com tempo decorrido, listas abertas/copiadas, ajustes de regras/cenários, registros de consumo e avaliação opcional de facilidade. Copiado apenas por ação do usuário. |

## Onde o usuário encontra

- **Sugestões → Ver lista de compras:** quantidade disponível, compra restante e pendências. A composição da refeição também aparece quando precisa de conferência e acompanha a lista copiada.
- **Planejamento → Resumo financeiro:** total conhecido de compras restantes, pagamentos e pendências; acesso a **Conferir custos já orçados**.
- **Próximas ações:** destaca uma decisão de cada vez. As ferramentas completas ficam em **Outras opções**.
- **Editar porção → Definir referência da minha receita:** registra mínimo, máximo e origem; exige receita, papel, estado e uma porção atual dentro da faixa.
- **Depois da festa:** apresenta registros encontrados, suas medidas e faltas. O formulário não preenche medidas reais usando previsões.
- **Avaliar esta experiência:** nota de 1 a 5 escolhida explicitamente, contagens e cópia voluntária, sem envio automático ou persistência de telemetria.

## Regras que preservam a confiança

1. A disponibilidade física não comprova pagamento. Compras já realizadas sem custo vinculado mantêm o saldo financeiro em conferência.
2. Um orçamento possivelmente contendo compras futuras não é somado novamente como se fossem despesas diferentes. O usuário pode declarar que a linha corresponde apenas a despesas realizadas. Se ela mistura futuro e realizado, os valores precisam ser separados no Orçamento.
3. Um custo de espaço/decoração só deixa de ser ambíguo após declaração explícita; isso não configura fornecimento de comida.
4. A declaração financeira é vinculada a valor, identidade e cobertura. Permissões locais restringem a declaração e a transferência dos vínculos do orçamento ao organizador/solicitante ou administrador; o fornecedor mantém as atualizações normais permitidas.
5. Substituições exigem novo nome, porção, estado e preço, preservando público, tipo, papel e grupo de alternativas. A economia total permanece desconhecida se houver preços ausentes.
6. Troca/retirada são bloqueadas para itens com compra/estoque, quantidade final/confirmada ou orçamento vinculado. Redução de variedade precisa preservar outra alternativa declarada do mesmo papel e público.
7. A confirmação da substituição altera nome/sugestão no cardápio. **Salvar** guarda a porção e o preço no histórico da simulação, seguindo o fluxo da calculadora. Despesas e pagamentos existentes não são alterados automaticamente.
8. O cenário de limite considera o cardápio selecionado e os valores consultados; não inclui compras de outros cardápios ainda não informadas. Alterar reserva não transforma a estimativa em garantia de suficiência.
9. Mudanças de planejamento durante a revisão impedem a adoção de uma proposta antiga ou a gravação de medições contra um contexto alterado.
10. Registros de falta continuam impedindo redução baseada na mediana observada. Fontes genéricas e faixas próprias não são apresentadas como validação estatística.

## Referências e procedência

- [Cristal Alimentos](https://cristalalimentos.com.br/quanto-preparar-como-calcular-arroz-feijao-e-macarrao-sem-desperdicio/): mantidas as referências específicas de arroz cru, feijão cru e massa seca.
- [Guia do medidor de massa — Barilla](https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa): referência de 80 g de massa seca por pessoa e formatos identificados. O enquadramento de uso como principal é contexto do aplicativo, não uma alegação de suficiência publicada pela fonte.
- [Revista Assaí — Preparando a festa, página 12](https://www.assai.com.br/sites/default/files/book_assai_28_compressed.pdf): faixa de 5 a 7 docinhos por pessoa para o conjunto de variedades. Não aplicada separadamente a cada sabor.

As referências não definem pesos de crianças/bebês, rendimento de qualquer receita ou adequação universal ao cardápio. Esses parâmetros permanecem explícitos e revisáveis. A origem própria é identificada como informação do organizador, não fonte externa.

## Verificação técnica

- **95 testes Flutter aprovados** na suíte de calculadora e cardápios.
- Jornada reexecutada após o ajuste final de textos e avisos, com substituição efetiva no repositório de teste, ajuste de reserva, conferência financeira, referência própria, pós-festa e exportação da avaliação.
- Regras Firestore aprovadas em emulador: organizador/admin podem declarar; terceiros e fornecedor não podem alterar a declaração nem assumir os vínculos para contornar essa restrição. Atualização normal de fornecedor preservada.
- Análise estática sem problemas. Capturas de widgets em `.dart_tool/qa-calculadora/` para revisão visual.
- Nenhum evento, compra ou consumo real foi fabricado ou gravado no ambiente publicado. Regras e aplicação continuam sem publicação, conforme solicitado.

## Validação real: preparada, ainda não executada

A implementação técnica desta matriz está entregue. Facilidade para pessoas reais, redução de desperdício, retenção e valor comercial não foram comprovados pelos testes automatizados.

Roteiro preparado para a validação:

1. Planejar um cardápio usando dados reais de convidados.
2. Registrar disponibilidade e conferir pelo menos uma pendência de porção/unidade.
3. Produzir e copiar uma lista utilizável; observar dúvidas e correções necessárias.
4. Comparar uma alternativa ou reserva, verificando se a diferença é compreendida.
5. Após a festa, registrar presença real, disponibilizado, sobra, desperdício e falta.
6. Copiar voluntariamente a avaliação da sessão; comparar notas, tempo decorrido e pendências com as observações da sessão. Tempo inclui pausas e não deve ser interpretado sozinho como eficiência.

Retenção e disposição para pagar devem ser avaliadas em pesquisa com participantes e acompanhamento consentido. Não foi introduzido rastreamento entre sessões nem envio automático de dados para simular essa validação.
