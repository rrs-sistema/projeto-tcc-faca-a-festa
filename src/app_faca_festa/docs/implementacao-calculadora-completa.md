# Calculadora inteligente — implementação completa 1.0.11+13

> Registro da entrega 1.0.11+13. A revisão posterior de realismo e as correções 1.0.12+14 estão em [revisao-realismo-calculadora-2026-10-15.md](revisao-realismo-calculadora-2026-10-15.md). “Completa” refere-se ao escopo daquela entrega, não à validação empírica das porções. A divisão e o fator de duração automáticos descritos abaixo foram substituídos por opções explícitas.

## Entregas

| Item combinado | Implementação |
| --- | --- |
| Catálogo de consumo | Cinco referências iniciais com fonte e versão, aliases e preço ausente explícito; publicador transacional cria apenas documentos inexistentes |
| Composição da refeição | Alternativas do mesmo grupo/público divididas pelos pesos de participação; itens independentes mantêm porção integral; padrão ajustável, explicado na tela |
| Rendimento e embalagens | Unidade consumida distinta da unidade de compra, rendimento configurável e arredondamento por tamanho de embalagem; custo acompanha a quantidade comprada |
| Financeiro | Orçado, contratado e pago separados; pagamentos acompanhados em tempo real; associação explícita de cobertura dos serviços; cancelados excluídos |
| Limite do evento | Inicializado pelo custo estimado do evento; alteração salva na mesma fonte usada pelo módulo financeiro |
| Histórico completo | Snapshot com regras e versões/fontes, modo, cardápio, itens desconhecidos, erros de catálogo e compromissos financeiros; restauração mantém pendências |
| Ações concretas | Editar porção/preço a partir do resultado ou recomendação da IA; associar cobertura; comparar e adotar cenário econômico mediante escolha |
| Ergonomia | Diagnóstico e resultados antes das opções de configuração; campos avançados recolhidos; fontes Poppins disponíveis offline |
| Qualidade | 44 testes Flutter; cenário completo equivalente às imagens em 420×910; teclado/texto ampliado; compilação TS e testes do callable; análise estática |
| Publicação | Build único 1.0.11+13 para Web, Windows, APK e AAB; Function da calculadora com prompt 1.3.0 |

## Fontes e premissas

As referências são orientações de planejamento, não garantia de consumo ou validação científica. Os preços não são presumidos.

- Churrasco e arroz: [Assaí — cálculo para churrasco](https://www.assai.com.br/blog/churrasco-no-assai-atacadista). Peso cru/preparado deve ser confirmado quando a fonte não explicita a medida.
- Macarrão: [Barilla — guia de massa](https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa), referência de massa seca.
- Refrigerante e suco: [iFood — quantidades para festa](https://institucional.ifood.com.br/clientes/como-calcular-quantidades-para-festa-calculos-e-o-que-considerar/), referência inicial.

A divisão igual entre alternativas é uma premissa do aplicativo, ajustável por peso. Ela não é atribuída às fontes. Se todos consomem a porção completa de dois acompanhamentos, configure-os como independentes. Rendimento padrão 1 não presume aumento de peso no preparo; informe o rendimento conhecido de sua receita. Embalagem 0 representa compra avulsa. Bebidas em garrafas usam consumo em litros e rendimento/capacidade explicitamente informada pelo organizador.

O catálogo inicial cobre os alimentos das imagens e suco como alternativa. Itens novos não reconhecidos continuam exigindo uma regra: o aplicativo mostra a pendência e permite defini-la, em vez de atribuir coeficiente arbitrário.

## Financeiro

Cobertura é declarada por orçamento e identifica itens integralmente contemplados no serviço. O orçamento é contado uma única vez; os itens cobertos não acrescentam uma segunda despesa. Isso não confirma pagamento, contratação ou disponibilidade de estoque.

Documentos sem vínculo identificável mantêm seu valor e deixam a projeção parcial. A consulta considera o maior valor entre custo real, orçamento estimado e detalhamento para não subestimar uma reserva enquanto dados estão divergentes. Pago vem do detalhamento; contratado depende de status/fechamento explícito. Para pagamentos detalhados, acompanha mudanças nas subcoleções `orcamento_gasto`.

O histórico representa o contexto salvo. Atualizar a calculadora consulta os dados atuais; abrir histórico não reconcilia silenciosamente os valores históricos com custos posteriores.

## IA

A IA interpreta o cálculo e recebe premissas de composição, rendimento, embalagem, cobertura e pagamentos. O prompt proíbe reaplicar fatores ou inventar preços/consumos. Sugestões relacionadas a um item podem abrir sua edição. O fetch do provedor tem timeout de 45 segundos. O diagnóstico local funciona mesmo sem resultado ou sem IA. Os antigos índices percentuais permanecem no contrato para compatibilidade, mas não são exibidos como probabilidades.

## Verificação e limites

Foram validados cálculos, contexto persistido, seleção, diálogo de edição e ações em testes. A jornada usa a tela real Flutter com repositórios de teste e dimensões de celular. Não houve aparelho Android físico nem emulador disponível; não se afirma teste de instalação real. O AAB é preparado para Play Console; publicar Hosting/APK não equivale a submeter à Play Store.

O documento de publicação contém a versão pública e as verificações dos pacotes. A auditoria original e o documento da etapa 1 ficam preservados como histórico, não como descrição das pendências atuais.

## Unidades iniciais do cardápio

A verificação de leitura do cardápio Almoço encontrou três alimentos em `un`, ainda sem quantidade final, e refrigerante em litros. Para itens não confirmados e sem quantidade final ou sugerida, uma referência reconhecida em kg/L pode produzir uma proposta nessa medida. A tela e o modal de aplicação explicam o ajuste. A aplicação reaproveita o item original, altera a unidade somente após seleção do usuário e mantém quantidade final e confirmação. Se esses dados mudarem durante a revisão, a transação recusa a alteração. Itens com quantidade já definida nunca têm sua unidade reinterpretada automaticamente.


A conversão em orçamento usa a mesma cobertura da projeção: vários alimentos podem reutilizar um único serviço. A proposta é agrupada por item/unidade, sem somar quantidades de medidas diferentes e sem sobrescrever custos contratados ou pagos. Mudanças de cobertura entre a revisão e a transação interrompem a conversão para nova conferência.


A proposta agrupada de um serviço representa os itens calculados naquela simulação, não uma nova cotação completa do fornecedor. O orçamento original conserva custo, status e pagamentos. Os detalhes de cada item ficam em `propostas_calculadora`; o valor sugerido é seu subtotal. O histórico da calculadora conserva as simulações anteriores.

O teste de jornada também altera o cardápio em segundo plano após abrir uma simulação: os quatro itens salvos permanecem até uma atualização explícita. Dessa forma, o histórico não muda silenciosamente durante a consulta.


Ao salvar uma simulação com parâmetros alterados e análise ainda pendente, a serialização limpa a análise anterior e seus aliases legados. A leitura do histórico não dispara análise sobre parâmetros que ainda estão carregando, nem substitui uma análise salva válida; quando não há análise salva, o diagnóstico da IA pode ser produzido após a restauração completa.
