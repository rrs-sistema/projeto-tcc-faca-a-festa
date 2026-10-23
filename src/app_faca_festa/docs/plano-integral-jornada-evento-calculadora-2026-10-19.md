# Plano integral da jornada: cadastro do evento à Calculadora Inteligente

19/10/2026. Plano de produto, domínio, dados, integração, experiência e verificação. Complementa a auditoria `auditoria-inteligencia-eventos-2026-10-19.md` e reconcilia os documentos de fases existentes. Não altera o aplicativo, as regras alimentares ou o ambiente publicado.

## 1. Resultado que deve ser entregue

O organizador cria ou edita um evento, informa o que já sabe e continua o planejamento sem redigitar os mesmos dados. A calculadora recupera contexto e escolhas, identifica o que falta, propõe alternativas compatíveis e calcula somente o que possui base suficiente. O organizador revisa um conjunto compreensível de mudanças. Ao voltar, trocar de evento, fechar o app ou enfrentar falha de rede, encontra um estado coerente e recuperável.

O resultado não será considerado entregue somente porque um modal funciona, uma função de IA responde ou uma suíte unitária passa. A entrega precisa atravessar cadastro, estimativa, evento salvo, convidados, serviços alimentares, regras, financeiro, persistência, execução e retomada.

O aplicativo pode suportar tipos de evento extensíveis. Isso não autoriza prometer sugestão especializada para qualquer evento: contexto desconhecido deve conduzir a perguntas ou configuração livre, preservando o cálculo, sem oferecer um lanche genérico como recomendação especializada.

## 2. Método e limites da análise

Foram rastreados tela e controller de cadastro, repositório do evento, ativação da sessão, convidados, cardápios, entrada e inicialização da calculadora, restauração de operação e histórico, regras manuais, orçamento, proposta inicial, referências, executor e análise remota. Também foram lidos documentos das fases já implementadas.

Evidências: leitura do código atual; suíte Flutter de eventos, calculadora e cardápios; verificação TypeScript/backend; três reproduções diagnósticas isoladas. Os substitutos de repositório nos testes não confirmam o banco de produção. Nenhum dispositivo, função publicada ou versão instalada foi validado nesta rodada.

Documentos anteriores relatam testes autenticados no aparelho, mas o próprio roteiro documentado inicia o cadastro pelo repositório, não percorre todos os campos da tela. Isso é cobertura de integração, não prova integral da jornada visual solicitada agora.

## 3. Fluxo atual e lacunas verificadas

| Etapa | O que existe | Lacuna e efeito |
|---|---|---|
| Cadastro | Tipo, data, período de vários dias, hora opcional, local, previsão de público, orçamento opcional e tema. Identidade estável para repetição de gravação. | Tipo e tema não descrevem como os serviços ocorrerão. Horário ausente não pode virar premissa de serviço à meia-noite. Datas não geram uma agenda de refeições. |
| Estimativa antes do evento | Abertura explicitamente sem evento, evitando herdar a festa ativa; retorno de rascunho ao formulário. | Antes de uma tentativa de salvar, o rascunho permanece em memória. Fechar o processo nesse ponto não tem recuperação durável garantida. |
| Salvar evento com estimativa | Evento e vínculo têm IDs estáveis; falha do vínculo deixa pendência local recuperável no mesmo aparelho. | São operações separadas. É preciso apresentar claramente evento salvo versus vínculo pendente e permitir retomar sem repetir toda a jornada. Recuperação local não significa recuperação entre dispositivos. |
| Home e ativação | Seleção de evento e cancelamento de módulos; proteção de geração contra respostas antigas em diversos pontos. | Iniciar listeners não significa que convidados, cardápios, itens e orçamento estejam todos prontos. Ausência, carregamento, erro e vazio ainda precisam de contrato unificado para a calculadora. |
| Público | Bases previstos, cadastrados, confirmados, não recusados e manual. | Abertura normal usa não recusados. Sem lista, usa previstos; com o primeiro registro, pode mudar silenciosamente a população planejada. Não existe declaração de completude da lista nessa decisão. |
| Entrada na calculadora | Três passos: Pessoas, A festa, Sugestões; catálogo remoto, revisão de cardápio e fontes complementares. | Inicialização usa quatro horas se nenhum parâmetro vier. Valores locais são reiniciados; restauração depende de caminhos distintos. A origem e a persistência da escolha não são uniformes. |
| Cardápios | Público, escopo, itens, disponibilidade, regras e estoque por destino. Criação inicial transacional e idempotente. | Cardápio não modela uma ocorrência temporal completa. “Almoço” como título não substitui serviço de almoço do dia 1 ou do dia 2. Parte da classificação usa o nome do cardápio. |
| Proposta inicial | Formatos editáveis e proteção das regras próprias. | Automático usa churrasco quando o nome contém churrasco; demais casos usam lanche. Cardápio inicial é finito e local. |
| Regras | Modal grava ajustes por evento/cardápio/item e só fecha após confirmação no caminho integrado. | É persistência real que deve ser preservada. Não justifica concluir que toda escolha da calculadora também seja gravada automaticamente. |
| Financeiro | Limite do evento, compromissos, pagamentos, compras restantes e detecção de sobreposição. | “Usar verba” atualiza a sessão; configurações manuais, histórico e configurações aplicadas pela IA têm rotas distintas de persistência. Home ainda chama soma estimada de “Gasto”. |
| IA e memória | Análise generativa, interpretação estruturada, referências, preferências privadas e consumo observado. | A IA não substitui o contexto inexistente. Parser local, referência editorial, dado observado e modelo generativo precisam de apresentação e contratos distintos. |
| Retomada | Histórico contém snapshot; operação restaura regras e configuração de entrada quando existente. | Restaurar histórico não pode ser a única forma de recuperar o planejamento corrente. Alterações recentes no evento devem invalidar apenas os resultados afetados. |

### Evidências de maior impacto

- `evento_cadastro_persistencia.dart`: salva evento, tenta vincular rascunho, mantém pendência e só depois ativa o evento.
- `data/local/rascunho_calculadora_store.dart`: armazenamento por usuário e evento; não oferece sincronização entre dispositivos.
- `calculadora_festa_screen.dart:203–289`: resolve evento e público, usa base não recusados para evento salvo, aplica limite inicial e inicia operação depois da preparação.
- `calculadora_festa_controller.dart:753–874`: limpa estado, atribui perfil/duração iniciais e carrega convidados, referências e orçamento.
- `calculadora_festa_controller.dart:1227–1263`: lista preenchida prevalece sobre previstos na base não recusados, mesmo quando parcial.
- `calculadora_festa_controller.dart:1553`: legado sem distribuição etária é tratado como adultos para não zerar o cálculo. Precisa ser identificado como hipótese de compatibilidade.
- `calculadora_festa_entrada.dart:101`: há restauração de configuração persistida pelo fluxo de entrada; isso impede generalizar que toda configuração sempre se perde.
- `atualizarDuracao`, `aplicarPerfilPlanejamento`, `alterarBaseCalculo` e `atualizarVerbaAlimentacao`: modificam estado e recalculam, sem gravação durável direta nesses métodos.
- `EventoController` acompanha alterações remotas no evento; a tela da calculadora possui watchers de convidados e cardápios, mas não há ali uma reconciliação equivalente de todas as premissas do evento atualizado.

### Reproduções diagnósticas desta rodada

1. Quarenta adultos previstos, lista vazia, base não recusados: cálculo usa 40. Após chegar um convidado cadastrado, passa a 1. Semanas antes do evento, isso pode reduzir a compra sem que a previsão tenha mudado.
2. Duração local de seis horas e verba local de R$ 1.450: nova preparação com padrão de quatro horas e operação sem configuração persistida retorna quatro horas e verba ausente. O teste não abriu um histórico salvo e não representa o caminho que já restaura configuração aplicada pela entrada inteligente.
3. Sem cardápio, tipos Casamento, Evento corporativo e Retiro, modo automático: os três geram Cachorro-quente e Frutas.

São diagnósticos do comportamento atual, não regras desejadas de aceitação. Reprodução local em `.dart_tool/auditoria_continuidade_test.dart`; log em `.dart_tool/auditoria-continuidade-2026-10-19.log`.

## 4. Regras de negócio que precisam ser decididas explicitamente

Estas são recomendações para a implementação, não comportamento já existente.

1. **Público não muda de significado silenciosamente.** Antes da lista completa, previstos é a base sugerida. O usuário pode escolher cadastrados/confirmados/não recusados, vendo a contagem e a origem. Uma lista parcial não é somada aos previstos nem substitui a previsão automaticamente.
2. **Estimativa, presença e capacidade são entidades diferentes.** Cenário de adultos equivalentes não cria convidados, não confirma presença e não mede capacidade física do local.
3. **Evento não é refeição.** Dias do evento, duração global e duração de cada serviço são campos distintos. Não multiplicar todas as receitas pelos dias ou horas do evento.
4. **Tema visual não define consumo.** Tipo do evento sugere perguntas e candidatos; formato de atendimento e contexto confirmado determinam a referência aplicável.
5. **Ausente não equivale a zero.** Quantidade não informada, orçamento não definido, dado ainda carregando e zero confirmado precisam de estados diferentes. Legado deve manter a origem de qualquer hipótese.
6. **Ajuste confirmado é durável no evento salvo.** Cancelar não grava. Sem evento, salvar rascunho deve ser explícito quanto à durabilidade local e sincronização. Snapshot histórico é um registro separado do planejamento atual.
7. **Custos e ações reais são separados.** Estimado, cotado, contratado e pago não são sinônimos. Aprovar proposta não cria pagamento, compra ou contratação.
8. **Dado revisado prevalece sobre sugestão genérica.** Uma nova referência publicada não recalcula silenciosamente um plano aprovado.
9. **Adequação alimentar não é inferida pelo nome.** Restrições declaradas, composição, preparo e responsável pela conferência são usados como requisitos; ausência de informação mantém pendência.
10. **Revisar por impacto.** Mudança de convidados, data, receita ou custo revalida somente os componentes dependentes e apresenta o que mudou antes de alterar compromissos reais.

## 5. Jornada alvo, do primeiro acesso ao resultado

### A. Criar a festa sem preencher um questionário técnico

Manter cadastro progressivo: identidade/tipo, quando/onde e previsão de público. Hora, local definitivo e orçamento podem continuar desconhecidos quando o produto permitir; a pendência aparece no planejamento, não como zero inventado. Tema e capa permanecem opcionais conforme regras atuais de cada tipo.

Ao final, oferecer “Planejar alimentação” e “Continuar depois”. Não criar cardápio, cotação, compra ou tarefa apenas por salvar o evento. Conservar o caminho de estimar antes de salvar, com identidade de rascunho e recuperação após interrupção.

### B. Revisar o contexto recuperado

Ao entrar pela Home, pelo cadastro, por um atalho ou por um evento reaberto, apresentar o mesmo resumo: evento ativo, período, público escolhido e origem, completude da lista, limite total, verba alimentar e serviços cadastrados. Permitir corrigir cada bloco sem recomeçar.

Exemplo: “40 previstos · lista em preenchimento: 1 cadastrado · cálculo usando previstos”. Se o usuário escolher confirmados: “1 confirmado · ainda há pendentes”, sem assumir público definitivo.

### C. Definir os serviços alimentares

Perguntar formato, data/horário e duração apenas quando necessários. Para vários dias, propor uma grade revisável: almoço e jantar em ocorrências separadas; coffee breaks por intervalo. A equipe ou convidados extras de um serviço entram explicitamente, sem adulterar a lista principal.

Oferecer herança do público da festa ou público próprio por ocorrência. Se não houver referência para um formato, permitir cardápio livre e orientação manual. “Outro” não significa “lanche”. Refeições e grupos já cadastrados devem ser recuperados.

### D. Propor o conjunto e resolver lacunas por impacto

Identificar itens por IDs e aliases aprovados, recuperar receitas pessoais compatíveis e referências versionadas. Perguntar primeiro o que muda unidade de compra, público coberto ou resultado material: comprar pronto/preparar; receita/corte; tamanho do item; papel principal/acompanhamento; quais serviços compartilham estoque.

Com dados suficientes, exibir plano principal e alternativa somente quando houver diferença comprovável. Não pedir preço para apresentar uma quantidade; não declarar custo completo sem preço compatível; não inferir consumo universal de um catálogo pequeno.

### E. Revisar e aplicar

Revisão agrupada contém serviços, público por destino, quantidades para servir e comprar, compras restantes, custos conhecidos, pendências e efeitos em cardápios/tarefas/estoque. Identificar ações propostas e fatos já registrados. Aplicar exige contexto e revisão ainda válidos, identidade idempotente e autorização apropriada.

Botões precisam dizer o que fazem: “Salvar rascunho”, “Aplicar ao planejamento”, “Salvar simulação no histórico”, “Registrar compra” e “Registrar pagamento”. “Usar no cálculo” só pode comunicar persistência quando o caminho realmente a garantir.

### F. Retomar e atualizar

Ao reabrir, recuperar planejamento corrente e mostrar se houve mudança de fontes. Mostrar “Dados desatualizados” ou “Sincronização pendente” em vez de fingir sucesso. Mudança de público propõe recálculo, preservando compras e itens contratados; mudança só do título/capa não invalida quantidades.

## 6. Contrato de dados e fonte da verdade

Introduzir contratos tipados com metadados de origem, revisão e estado. Evitar duplicar verdades em campos avulsos de cada tela.

| Informação | Fonte canônica proposta | Regra de uso |
|---|---|---|
| Identidade, proprietário, tipo, período e local | Evento | Persistir revisão; campos não confirmados continuam identificados como desconhecidos. |
| Previsão de público | Evento | Independente da lista nominal e das presenças. |
| Convidados e respostas | Coleção de convidados | Derivar contagens, nunca copiar como previsão permanente sem decisão explícita. |
| Base de público e completude da lista | Planejamento privado versionado | Registrar fonte, confirmação, valores manuais e hipótese de legado. Não duplicar nomes. |
| Limite financeiro total | Evento, usando o caminho existente de limite | Nenhuma tela passa a ter outro limite canônico oculto. |
| Verba alimentar, perfil, margem e duração assumida | Planejamento privado | Toda edição confirmada usa o mesmo comando persistente, com ou sem IA. |
| Cardápio e itens | Estruturas atuais de cardápios | Preservar IDs; quantidades sugeridas, finais e disponibilidades separadas. |
| Ocorrências de serviço | Contrato privado ligado ao cardápio | ID próprio, data, hora/fuso quando conhecidos, duração, atendimento, público herdado/próprio, grupos e destinos. Um cardápio pode ser reutilizado em várias ocorrências. |
| Porções, receita e rendimentos | Regras por destino + referência versionada | Regras atuais já persistidas são preservadas, mantendo compra versus pronto e unidade. |
| Custos, pagamentos e contratações | Módulos financeiros atuais | Referências cruzadas por ID; conferir sobreposição de itens e serviços antes de somar. |
| Estoque e reservas | Operação atual | Não descontar quantidade reservada duas vezes nem reutilizar lote em destinos incompatíveis. |
| Proposta | Snapshot derivado e versionado | Referenciar revisões de fontes e motor; não constitui fato de execução. |
| Simulação histórica | Histórico existente | Imutável enquanto consultada; atualização cria revisão/cenário atual explícito. |

`ContextoPlanejamentoEvento` deve conter IDs de evento/rascunho/usuário; modo; revisões das fontes; estado de carregamento por módulo; público e origem; agenda; serviços; regras com versão; financeiro; permissões e pendências. Seção inválida não pode contaminar as demais.

Proveniência mínima para valores inferidos: valor, unidade, estado, origem (`organizador`, `evento`, `lista`, `referencia`, `observado`, `hipotese`), referência/versão, contexto de aplicação e confirmação. Não gravar um total derivado sem sua fonte.

## 7. Persistência: corrigir a assimetria entre caminhos

| Ação | Situação atual | Entrega necessária |
|---|---|---|
| Salvar evento | Remoto; identidade estável | Manter e testar repetição após resposta perdida. |
| Rascunho antes de salvar evento | Memória até tentativa de vínculo | Persistência local por usuário/rascunho com recuperação explícita; sincronização privada opcional como capacidade distinta. |
| Regra manual no evento salvo | Gravação aguardada na operação | Reutilizar o caminho existente; não refazer outra coleção. |
| Base, duração, perfil, margem e verba editados manualmente | Estado de sessão, com histórico/alguns fluxos separados | Comando unificado que persiste confirmação no planejamento corrente. |
| Configuração aplicada pela entrada inteligente | Backend grava configuração e cliente restaura | Reutilizar sem privilegiar a IA sobre controles manuais. |
| Limite total | Gravação no evento pelo caminho próprio | Propagar revisões a todas as telas e invalidar projeções financeiras antigas. |
| Histórico | Snapshot persistido | Mantê-lo distinto do autosalvamento corrente e da consulta ao plano aprovado. |
| Rascunho vinculado ao evento | Simulação privada com ID estável | Retomar vínculo e oferecer continuar com aquela estimativa, sem exigir que o usuário descubra o histórico. |

Estados de escrita: editando, salvando, confirmado no servidor, pendente de sincronização, falhou e conflito. Não mostrar “salvo” quando houve apenas mutação local. Na transição evento criado/vínculo pendente, não repetir criação nem perder rascunho. Fechamento forçado precisa de regra de recuperação documentada.

Conflitos materiais usam revisão esperada e apresentação de diferenças. Repetir gravação com o mesmo pedido deve retornar o recibo, não duplicar menu, ingrediente, tarefa ou despesa. Cancelar o editor não pode deixar aplicação parcial.

## 8. Máquina de prontidão e mudança de contexto

Não usar somente `carregando` global. Cada fonte deve distinguir não consultada, carregando, disponível com dados, disponível vazia, erro, desatualizada e escrita pendente.

Capacidades derivadas:

- **Pode estimar quantidades:** público confirmado como base e porções aplicáveis, com unidades e serviços conhecidos.
- **Pode estimar compra:** estado de compra e rendimentos/referências compatíveis, mais política de embalagem.
- **Pode projetar custo:** quantidades de compra, preços compatíveis e cobertura financeira conciliada.
- **Pode comparar alternativas:** ambas calculadas sob fontes comparáveis e objetivo explícito.
- **Pode aplicar:** evento/proprietário/contexto válidos, proposta revisada, sem conflito material e ações permitidas.

Uma seção pode estar pendente sem transformar o restante em “não funciona”. Exibir resultado parcial identificado e ação concreta para completar. Consultar histórico não deve ativar listeners que substituam seu snapshot.

Mudança material inclui público/base, serviços, receita/porção, estado/unidade, preço/cobertura, lote/reserva e revisão de referência escolhida. Mudança cosmética inclui capa e título quando não usados como identidade do domínio. Tipo alterado pode exigir revisão contextual, sem apagar os dados existentes.

## 9. Motor de inteligência de negócio

Separar aquisição do contexto, recuperação de referências, perguntas, geração de alternativas, cálculo, explicação e aplicação. `PlanoEventoService` deve coordenar serviços/ocorrências usando contexto tipado. `PropostaRefeicaoService` deve receber o contexto relevante e candidatos de um repositório, sem manter modelos alimentares como decisão final embutida.

Precedência: decisão explícita do item/evento; receita privada confirmada; medição observada compatível oferecida para adoção; referência aprovada e contextual; candidato a confirmar; pendência sem número inventado. Referências publicadas não sobrepõem decisões aceitas.

IA trabalha com candidatos e IDs e produz comandos validados. Não é fonte de preço real, disponibilidade, presença ou consumo medido. Preservar os controles e o executor já existentes. Parser local continua útil para comandos limitados, com indicação correta da capacidade.

Perguntas devem ser escolhidas por diferença material de resultado, não quantidade de campos disponíveis. Uma escolha já salva não é perguntada de novo sem mudança relevante. Se dois candidatos levam a compras ou custos distintos, explicar a diferença em termos do evento.

Catálogo remoto exige schema, alias/identidade, serviço/formato, porção/faixa, unidade, estado, público aplicável, limitações, origem, revisão e vigência editorial. O backend valida publicação e o motor valida aplicação. Manter versão conhecida para contingência, com aviso de origem e sem presumir atualidade.

Calibração usa preparado, servido, sobra, descarte, falta e público efetivo comparáveis; compra não é consumo. Não prometer aprendizado universal com poucas amostras. Necessidades alimentares e receitas privadas não são publicadas no documento compartilhado do evento.

## 10. Backlog de implementação com dependências e encerramento

As entregas abaixo são partes dependentes de uma única liberação integral. Terminar uma não autoriza declarar a jornada pronta.

| ID | Entrega e componentes | Depende | Critério de encerramento |
|---|---|---|---|
| J0 | Contrato de contexto, origens e estados; reconciliação das especificações e da falha do teste de capacidade | — | Política de público, persistência e ações aprovada como contrato verificável; testes antigos coerentes com confirmação explícita. |
| J1 | Cadastro e rascunho durável; controller/store existentes; recuperação do vínculo | J0 | Interrupção antes/depois de criar evento recupera no mesmo aparelho sem duplicar; limite e previsão retornam ao formulário. |
| J2 | Público com completude e decisão de base; convidados, evento e calculadora | J0 | Primeiro convidado não reduz previsto sem escolha; recusados/confirmados respeitados; manual não é sobrescrito por listener. |
| J3 | Configuração corrente persistente para todos os canais; operação/repositório/regras/backend | J0–J2 | Reabrir app preserva base, duração assumida, perfil, margem, verba e serviços confirmados; IA e formulário usam o mesmo domínio. |
| J4 | Serviços e agenda por ocorrência; adaptação de cardápios/operacao/plano | J2–J3 | Dois dias ou três intervalos mantêm públicos e estoque por destino sem duplicar nem multiplicar indevidamente. |
| J5 | Referências e modelos contextuais versionados; migração por adaptadores | J0,J4 | Sem palavra-chave “churrasco” como único classificador; evento sem cobertura segue manual com pendência; publicação não reescreve histórico. |
| J6 | Planejador híbrido e revisão agrupada; proposta, perguntas e IA | J4–J5 | Sugestão justificável por serviço, com origem, unidade e limite; preserva receita própria e restrições; nenhum fato real inferido da aprovação. |
| J7 | Financeiro e execução conciliados; verba/custos/estoque/tarefas existentes | J3,J6 | Projeção reproduzível, sem dupla contagem; pagamentos distintos; duplicidade e falha de operação têm recibo/reconciliação. |
| J8 | Experiência integrada das entradas, passos, modais e retorno | J1–J7 | Nenhuma redigitação desnecessária; teclado não encobre campo; próximo passo e efeito da confirmação estão claros. |
| J9 | Migração, compatibilidade, instrumentação e homologação completa | J1–J8 | Matriz de aceite passa com SDKs/regras reais em emuladores e aparelho; implantação compatível e reversão ensaiadas. |

J8 deve acompanhar o desenvolvimento de cada etapa, não ser deixada como acabamento final. Responsabilidades: produto/eventos confirma políticas e exemplos; domínio/dados implementa contratos e persistência; Flutter integra fluxo/acessibilidade; backend garante validação/autorização; QA cobre a jornada por dados e efeitos. Essas são funções de trabalho, não delegações realizadas nesta análise.

Não fixar cronograma fechado sem dimensionar migração, catálogo e os resultados dos testes autenticados. A sequência e o escopo são obrigatórios; estimativas de esforço entram por pacote após o contrato J0.

## 11. Matriz de aceite integral

| Caso | Resultado obrigatório |
|---|---|
| A01 Evento novo sem cardápio, orçamento e público ainda desconhecidos | Salva o que for permitido; mostra pendências sem zero fictício nem cardápio criado. |
| A02 Estimar antes de salvar com outro evento ativo | Nenhum dado ou listener da festa anterior contamina a estimativa. |
| A03 Alterar público/limite no formulário após a estimativa | Valores novos prevalecem ao vincular; snapshot registra a origem. |
| A04 Encerrar processo durante cadastro ainda não salvo | Rascunho recuperável segundo a política local anunciada. |
| A05 Falhar gravação do evento ou perder sua confirmação | Retentativa não duplica evento. |
| A06 Evento salvo e vínculo falha | Pendência explícita, retomada e histórico sem duplicação. |
| A07 Previsto 40 e apenas um convidado cadastrado | Preserva base confirmada; informa lista parcial; não muda para um atendido silenciosamente. |
| A08 Recusados, confirmados e não recusados | Bases e contagens distintas, com zero confirmado diferente de dado ausente. |
| A09 Público manual e atualização remota da lista | Manual preservado; mudança oferecida somente com decisão explícita. |
| A10 Legado com total sem distribuição etária | Expõe hipótese ou pede distribuição antes de declarar composição conhecida. |
| A11 Alteração de previsão/limite em outro acesso | Atualiza fontes e apresenta invalidação material; não mantém resultado aparentemente atual. |
| A12 Troca rápida de evento e retorno tardio de rede/IA | Resposta antiga descartada; rascunho/estado da origem preservado. |
| A13 Lista/cardápios vazios, ainda carregando ou consulta negada | Estados distintos, sem fabricar exemplo a partir de falha. |
| A14 Salvar regra de consumo e reabrir o app | Todos os campos e premissas reaparecem no mesmo evento/cardápio/item. |
| A15 Cancelar edição de regra, verba ou contexto | Nenhuma alteração persistida. |
| A16 Verba, perfil, margem, base e duração confirmados manualmente | Reabertura conserva escolhas sem exigir abrir uma simulação histórica. |
| A17 Aplicar configuração por texto ou IA | Mesmas validações e persistência dos controles manuais, com revisão e contexto. |
| A18 Aniversário infantil, casamento e evento corporativo sem menu | Perguntas/modelos compatíveis ou ausência de cobertura; nunca o mesmo fallback silencioso. |
| A19 Retiro de dois dias com quatro refeições | Ocorrências identificadas e população por refeição; nenhuma multiplicação por duração global. |
| A20 Congresso com vários intervalos | Público/porção por intervalo, receitas reutilizáveis e compras agregadas corretamente. |
| A21 Grupo com necessidade alimentar e item com ingredientes incompletos | Mantém pendência de conferência; não atesta adequação pelo nome. |
| A22 Receita própria, rendimento medido e referência nova publicada | Mantém decisão aceita; nova referência aparece como alternativa versionada. |
| A23 Alimento desconhecido ou unidade incompatível | Pede medida/receita; não aproxima arbitrariamente para alimento reconhecido. |
| A24 Carne crua, alimento pronto, embalagem e receita por ingredientes | Conversões rastreáveis; compra e servir distintos; nenhum ingrediente inventado. |
| A25 Estoque compartilhado em dois serviços | Reserva única por lote/destino; faltante consolidado sem dupla utilização. |
| A26 Buffet contratado com itens já cobertos | Não adiciona os mesmos alimentos novamente como compra a pagar. |
| A27 Preço ausente ou antigo/incompatível | Quantidade pode existir; custo incompleto claramente identificado. |
| A28 Simulação de capacidade com grupos específicos | Explica limitação; permite usar verba sem afirmar capacidade não calculada. |
| A29 Cotação, contratação, compra e pagamento parcial | Entidades e saldos consistentes; aprovação de plano não executa esses fatos. |
| A30 Conjunto aprovado repetido ou resposta perdida | Mesmo recibo; nenhuma duplicação de menu, despesa, reserva ou tarefa. |
| A31 Falha intermediária e conflito entre dois acessos | Sem sucesso enganoso nem aplicação parcial oculta; retomar ou reconciliar. |
| A32 Histórico antigo e atualização para fontes atuais | Consulta preservada; nova revisão identificada; não sobrescreve fatos. |
| A33 Teclado, orientação horizontal e fonte ampliada | Campo e ação principal utilizáveis; texto não cortado nem confirmação indevida pelo teclado. |
| A34 Sem rede/IA indisponível | Cálculo com fontes válidas disponíveis continua; origem/recência claras; escrita pendente identificada. |
| A35 Outro organizador, fornecedor ou usuário sem autorização | Leitura/escrita privada recusada com SDK/regras reais. |
| A36 Migração de evento antigo sem período ou configuração | Não altera fatos e receitas existentes; pendências identificadas; repetição segura. |

## 12. Homologação, liberação e métricas

Executar primeiro testes de domínio para contratos e precedência; depois repositórios e regras autenticadas em emuladores; depois navegação completa em aparelho. O roteiro no aparelho precisa preencher a tela de cadastro, salvar, entrar pela Home, planejar, editar, fechar o processo e reabrir. Testes que criam o evento diretamente no repositório continuam úteis, mas não substituem esse roteiro.

Combinar tipos e condições: infantil; casamento; corporativo com intervalos; retiro de vários dias; churrasco; serviço livre sem referência. Para cada um, incluir pelo menos um caminho incompleto e um completo. Conferir dados persistidos e efeitos nos outros módulos, não apenas texto na tela.

Registrar versão do app, motor/catálogo, backend e regras usados no ensaio. Instrumentar mudanças de origem do público, restauração, falha de vínculo, confirmação de configuração, pendência por contexto, conflito e repetição idempotente. Evitar texto privado, nomes e documentos em logs operacionais.

Critérios de liberação: zero falhas críticas na matriz; zero duplicações nos ensaios de repetição; zero aplicação cruzada entre eventos/usuários; todos os campos confirmados com política de retomada coberta; sugestão sem cobertura explicitamente pendente. Metas de tempo/quantidade de perguntas e qualidade das sugestões exigem linha de base e piloto, não porcentagem de autonomia inventada.

Implantar validação e leitura compatíveis antes de clientes que escrevam schema novo. Versionar catálogo e contratos, preservar snapshot anterior e migrar com IDs estáveis. A reversão desativa a seleção do motor novo; não apaga eventos, compras ou pagamentos. Pilotar o fluxo completo antes de liberar para toda a base.

## 13. Resultado da verificação nesta rodada

- Flutter, `test/features/eventos`, `test/features/calculadora` e `test/features/cardapios`: 345 aprovados, um com falha; reprodução em JSON em `.dart_tool/auditoria-jornada-2026-10-19.jsonl`.
- Falha identificada: `calculadora_autonomia_widgets_test.dart:101` espera verba 100 logo após simular; o fluxo atual só aplica após “Usar esta verba”. O teste precisa ser reconciliado com o contrato atual de confirmar/cancelar, sem voltar a gravar por mera simulação. A suíte não está totalmente aprovada.
- `npm --prefix functions run check:calculadora`: aprovado; inclui TypeScript e verificações de planejamento/IA, limite e callable. Não é teste de produção.
- Três reproduções diagnósticas adicionais: aprovadas, demonstrando os riscos de público parcial, configuração local sem retomada e fallback de formato. Não comprovam correção desses riscos.
- Não foram executados nesta rodada emuladores, IA remota real, teste visual em dispositivo, fechamento forçado do processo ou migração em ambiente publicado. São portas obrigatórias de J9, não aprovações presumidas.

## 14. Definição de pronto

O plano estará concluído quando o usuário conseguir atravessar A01–A36 com dados coerentes, persistência e feedback claros, e quando as recomendações forem determinadas pelo contexto confirmado dos serviços. Novos modais, mais `switch` de alimentos ou apenas mover constantes para o banco não encerram a entrega. Deve-se demonstrar a jornada inteira, com os resultados persistidos e os limites conhecidos registrados.
