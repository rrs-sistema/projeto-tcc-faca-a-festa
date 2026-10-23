# Prompt 07 — Planejador híbrido e perguntas por impacto

Atue como engenheiro sênior Flutter/Firebase e analista de negócio de eventos. Implemente esta entrega no aplicativo Faça a Festa; não se limite a sugerir um plano ou produzir documentação.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Ambiente Windows/PowerShell; app Flutter/Dart com GetX, Firestore, Firebase Auth e Cloud Functions TypeScript em `functions/`.

Este prompt é autossuficiente. Não depende de outro chat ou da execução de outro prompt. Leia o código atual e as instruções AGENTS.md aplicáveis, verifique o estado do Git e preserve alterações existentes. Os arquivos indicados são pontos de investigação: confirme os caminhos antes de editar. O código pode ter evoluído desde a auditoria.

Se uma infraestrutura necessária ainda não existir, implemente a menor fundação de produção necessária dentro desta entrega, com testes e integração real. Se já existir, reutilize-a. Não exija que o usuário execute outra tarefa, não duplique serviços equivalentes e não entregue somente interfaces, telas desconectadas, stubs ou mocks de produção. Isso não autoriza expandir para funcionalidades sem relação com o objetivo.

## Contrato comum que esta entrega deve respeitar

- Preserve o isolamento entre organizadores, eventos, cardápios e itens, incluindo callbacks tardios e troca de sessão.
- Evento salvo, rascunho, planejamento corrente, proposta, histórico e fatos executados são estados distintos. Históricos aprovados não são sobrescritos silenciosamente.
- Ausente, zero confirmado, carregando, vazio, erro, desatualizado e sincronização pendente não são equivalentes.
- Previsão de público, lista nominal, presença e capacidade são informações diferentes. Uma lista parcial não substitui automaticamente a previsão.
- Limite total pertence ao evento. Configurações alimentares e receitas privadas pertencem ao planejamento privado. Reutilize `calculadora_operacao/{idEvento}` e seus mecanismos atuais quando forem adequados; não acrescente campos incompatíveis sem atualizar validação, regras e leitores.
- Confirmação deve gravar pelo caminho de domínio apropriado; cancelar não grava. Não apresentar mutação local como confirmação remota.
- IA interpreta e propõe; cálculos e comandos são validados. Não invente preços, presenças, ingredientes, rendimentos medidos ou adequação alimentar. Não trate aprovação de plano como compra, pagamento, contratação ou envio de mensagem.
- Regras técnicas e fórmulas podem permanecer no código. Referências editoriais e políticas configuráveis precisam de origem, contexto e versão. Não elimine validações para produzir um resultado aparente.
- Garanta usabilidade em celular, teclado aberto, fonte ampliada e telas pequenas; mantenha leitura, contraste e áreas de toque. Não exponha detalhes técnicos desnecessários ao organizador.
- Não execute deploy, alterações em produção, migração destrutiva, commit ou push. Prepare os artefatos necessários e descreva a ativação posterior. Testes autenticados devem usar projeto demo/emuladores e recusar conexões acidentais com produção.

## Objetivo específico

Implemente planejamento alimentar contextual, capaz de recuperar o que já existe, escolher perguntas relevantes e propor um conjunto justificável por serviço. Não basta chamar um modelo generativo ou acrescentar mais casos em um switch.

## Pontos de entrada

- `lib/domain/services/plano_evento_service.dart`, `proposta_refeicao_service.dart`, `composicao_refeicao_service.dart` e `revisao_cardapio_service.dart`
- `memoria_calculadora_service.dart`, `consumo_observado_service.dart` e referências de porção/rendimento.
- Controller da calculadora, widgets de plano e revisão, serviço remoto de IA e `functions/src/services/calculadora/`.

## Requisitos de implementação

1. Modele contexto por serviço: objetivo/formato confirmado, público e origem, data/duração quando relevantes, itens existentes, receitas, forma de obtenção, infraestrutura declarada, orçamento alimentar e compromissos conhecidos. Se não existir um contrato de contexto no código, implemente o necessário e integre-o aos dados atuais.
2. Separe aquisição de contexto, recuperação de candidatos, perguntas, proposta, cálculo, explicação e aplicação. Use repositório de referências com origem/versão, reutilizando o existente ou criando a fundação mínima necessária.
3. Adote precedência: decisão explícita do item/evento; receita privada confirmada; consumo observado compatível oferecido para adoção; referência aprovada contextual; candidato a confirmar; pendência. Nunca substitua silenciosamente uma receita revisada.
4. Escolha perguntas simulando o impacto nas decisões: pronto/preparar, tamanho, papel na refeição, rendimento, unidade e público por destino. Reutilize respostas válidas; não repita perguntas sem mudança material nem abra um formulário técnico inteiro por padrão.
5. IA interpreta briefing e sugere candidatos por IDs. Valide a saída, as unidades, públicos, limites e permissões no motor antes de calcular ou gravar. Preserve o parser local como capacidade limitada e identificada.
6. Exiba recomendação principal e alternativa somente quando houver objetivo e diferença sustentados pelos dados. Não reduza reservas e declare economia quando faltam preços; não afirme confiança percentual sem calibração.
7. Mostre origem, premissas, limitações, faixa quando disponível e o que falta. Quantidade conhecida pode existir com custo pendente.
8. Fora da cobertura, permita configuração manual e retorno posterior. Não invente um menu universal para encerrar o fluxo.

## Critérios de aceite próprios

- Trate infantil, casamento, congresso e retiro por contexto de serviço, e não apenas pelo rótulo do evento.
- Preserve receita própria ao gerar alternativa e ao atualizar catálogo.
- Não reutilize medição de público/contexto incompatível nem apresente preferência como consumo observado.
- Um preço ausente impede conclusão financeira completa, sem impedir a quantidade sustentada por referência válida.
- Restrição alimentar sem composição conferida permanece pendente.
- IA indisponível ou saída inválida não corrompe o planejamento e não impede o cálculo determinístico válido.

## Execução, validação e entrega

Comece reproduzindo os cenários desta entrega e identificando o comportamento atual. Implemente verticalmente as camadas necessárias: domínio, persistência, permissões/backend e interface. Preserve o comportamento correto já existente e teste falhas, repetição e retomada, além do caminho feliz.

Execute formatação e análise estática nos arquivos modificados e os testes pertinentes. Verifique os scripts atuais antes de usar comandos: a base contém `flutter test`, `npm --prefix functions run check:calculadora`, `npm run test:rules:calculadora` e testes em `integration_test/`. Não rode deploy por esses comandos. Não afirme que testes com substitutos comprovam a integração com Firestore ou com dispositivo.

Se faltar aparelho, emulador, credencial de teste ou outro recurso externo, continue todo o trabalho independente, entregue teste e roteiro reproduzíveis e registre exatamente o que não foi executado. Não marque como homologado o que não foi comprovado. Não desative testes ou enfraqueça regras apenas para obter aprovação.

Registre a evidência da entrega em `docs/evidencias_validacao/jornada/07-planejador-hibrido.md`: diagnóstico, decisão de negócio, arquivos alterados, formato persistido, compatibilidade/migração, testes e resultados reais, limitações externas e instruções de ativação sem publicação. Não inclua segredos ou dados pessoais reais.

Ao finalizar, explique o comportamento anterior e o novo, o que foi efetivamente implementado e validado, e qualquer requisito pendente. Não declare a jornada inteira concluída apenas por encerrar este escopo.
