# Revisão das porções e do realismo — 15/10/2026

> Atualização posterior: os recursos de referência contextual, rendimento medido e registro/calibração de consumo da versão 1.0.13+15 estão descritos em [calculadora-calibracao-contextual.md](calculadora-calibracao-contextual.md). As lacunas abaixo retratam a revisão da 1.0.12+14; as limitações empíricas permanecem explicitadas no documento novo.

## Conclusão

A versão 1.0.11+13 continha um motor determinístico funcional e IA para interpretar resultados. Isso não equivalia a um modelo de consumo calibrado para cada cardápio. A validação anterior comprovava o funcionamento, mas não a adequação das quantidades ao almoço mostrado pelo usuário.

As capturas comprovam que há regras e resultados; não comprovam a suficiência das porções. A primeira mostra 26 pessoas e 12,15 kg de churrasco. Outra mostra 10,56 kg com perfil Padrão, quatro horas e reserva de 10%. As capturas não informam a composição etária completa nem estabelecem que ambas representam os mesmos parâmetros.

## Problemas confirmados no código

| Problema | Efeito | Correção 1.0.12+14 |
| --- | --- | --- |
| Divisão automática por grupo | Arroz de 50 g e massa de 80 g viravam 25 g e 40 g simplesmente por coexistirem | Divisão depende de adesão explícita de cada item; a referência integral não é cortada pela presença de outro alimento |
| Duração universal | A escala de horas aumentava carne, arroz e massa mesmo para um único almoço | Um serviço por padrão, sem escala de horas; repetições são informadas por item. A escala antiga é opcional e identificada como heurística |
| Estado da medida indefinido | Kg crus, secos, prontos e de compra podiam ser interpretados como equivalentes | Estado e papel na refeição podem ser declarados na regra; sem estado definido há indicação da pendência. Conversão continua exigindo rendimento explícito |
| Custo ausente mostrado como zero | Comparador econômico mostrava atual e proposta R$ 0,00 | Comparação monetária ocultada se faltam regras/preços; indicação de preço pendente por item |
| Conta por pessoa escondida | Regra truncada sob a lista | Cards mostram referência em g/ml por equivalente e por serviço; modal apresenta pessoas, pesos, fatores, reserva e resultado |
| Perfis tratados como adequação | Redução de porção podia parecer uma economia garantida | Multiplicador e reserva explícitos; comparação renomeada para porções e reserva e explica sua limitação |

Não foram inventados novos coeficientes para obter números visualmente mais agradáveis. A referência de 50 g de arroz e de 80 g de massa permanece como ponto de partida, com as limitações de contexto documentadas.

## Reconstrução matemática, sem presumir os convidados reais

Se houver 24 adultos equivalentes, 400 g e 10% de reserva produzem:

`24 × 0,4 × 1,10 = 10,56 kg`.

Se a escala antiga de seis horas estiver ativa, o fator 1,15 leva a:

`24 × 0,4 × 1,15 × 1,10 = 12,144 kg`, arredondados para `12,15 kg`.

Isso demonstra um caminho do motor para os números das capturas. Não demonstra que havia exatamente 24 equivalentes ou seis horas na primeira captura. Para determinar a causa daquele resultado específico são necessários seus parâmetros salvos.

No teste de regressão independente, 20 adultos e seis crianças são 26 pessoas e 23,6 equivalentes pelos pesos atuais. Com 400 g e reserva de 10%, a compra é 10,39 kg. Duas, quatro ou oito horas produzem a mesma quantidade quando há um serviço e a escala de duração está desligada. Esse teste comprova a fórmula, não valida o consumo real desses convidados.

## Fontes e interpretação

- [Assaí — cálculo de churrasco](https://www.assai.com.br/blog/churrasco-no-assai-atacadista): referência de carne e acompanhamentos; não fornece validação personalizada para este evento.
- [Barilla — medidor de massa](https://www.barilla.com/pt-br/ajuda-com/novidades/guia-medidor-de-massa): porção individual de massa seca. Isso não estabelece automaticamente a quantidade de macarrão como acompanhamento de um almoço com churrasco e arroz.

Gramas de massa seca não devem ser comparados diretamente com gramas de massa pronta. A quantidade de compra depende da base da porção e do rendimento declarado. Escolher “acompanhamento” na edição registra o contexto; não reduz silenciosamente a porção nem presume uma conversão.

## O que permanece sem validação

1. **Calibração do almoço concreto:** número de adultos/crianças, papel de cada alimento, base cru/seco/pronto, repetição e consumo habitual ainda precisam ser confirmados. A pergunta foi apresentada ao usuário durante a correção.
2. **Referências contextuais:** o catálogo inicial não é uma matriz validada de receitas, acompanhamentos, perdas, tipos de serviço e padrões de consumo.
3. **Aprendizado com eventos anteriores:** não há registro estruturado de consumido/sobra/falta nem modelo treinado ou calibrado com esse retorno.
4. **Pesos por idade e perfis:** continuam sendo premissas explícitas de planejamento; não representam necessidades nutricionais validadas.
5. **Cobertura de serviço:** continua declarada pelo organizador. A interface ainda permite associar alimentação a qualquer orçamento; o nome do serviço não constitui prova dessa cobertura.

A IA continua interpretativa. O prompt 1.3.1 exige reconhecer essas limitações e impede atribuir divisão ou escala por duração a regras sem ativação explícita. Acrescentar IA generativa não valida os coeficientes do motor.

## Verificação

48 testes Flutter aprovados, incluindo a jornada móvel da tela, conta com 26 pessoas, duração sem multiplicação automática, divisão opcional, preservação do contexto e comparação sem preços fictícios. Compilação TypeScript, testes do callable e análise estática dos arquivos alterados aprovados.

Testes móveis usam a tela Flutter com repositórios de teste. Não houve ensaio de consumo real nem teste em aparelho físico nesta sessão. As regras históricas e os resultados salvos permanecem armazenados; ao recalcular, usam a semântica atual do motor, versão 3.
