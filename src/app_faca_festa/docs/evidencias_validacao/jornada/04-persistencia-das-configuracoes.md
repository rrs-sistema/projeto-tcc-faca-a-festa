# Entrega 04 — Persistência uniforme das escolhas

Data: 19/10/2026. Flutter/Firebase, Windows/PowerShell. Alterações pré-existentes do workspace preservadas; sem deploy, produção, migração destrutiva, commit ou push.

## Diagnóstico e reprodução

Antes desta entrega, duração/perfil/margem/verba tinham mutações locais separadas da gravação da entrada inteligente. Texto só aplicava alterações em memória. A restauração da entrada inteligente cobria fonte/público/duração/perfil, mas não margem/verba. A preparação podia calcular com padrões antes de receber a operação privada.

Teste de regressão executado antes da implementação: escolher 6 horas e R$ 1.450, preparar novamente e esperar 6 retornou **4**. O teste final confirma explicitamente pelo novo comando e recupera ambos os valores na nova preparação. Não transforma edição de um controle em confirmação remota.

## Decisão de negócio e fluxo de produção

`ConfirmacaoConfiguracaoCalculadora` representa a confirmação tipada: identidade estável, revisão esperada, contexto de evento/usuário no cliente e alterações validadas. Reutiliza `CalculadoraFestaRepository.alterarOperacaoEvento`, transação Firestore e `calculadora_operacao/{evento}.configuracao_planejamento`. Não cria outro repositório equivalente nem depende do histórico.

O editor de configurações permite revisar fonte, faixas etárias manuais, duração, perfil, margem e verba. Editar/cancelar não grava. Confirmar aguarda o servidor; falha mantém campos e editor; pendente bloqueia toques repetidos e saída. Conflito informa o erro e permite revisar com a revisão atual, preservando os valores até decisão explícita. O editor mostra as escolhas guardadas quando há erro para comparação.

Controles de perfil e duração abrem esse editor. A confirmação de fonte reutiliza o mesmo comando. Texto converte suas intenções verificáveis no mesmo comando; agora aceita também margem e verba. A leitura por IA continua sendo proposta não executada: o serviço existente valida e aplica somente ações aprovadas em transação, usando a mesma configuração e limites. O schema do extrator ganhou margem/verba, sem transformar verba em limite total.

A comparação de cenário econômico e a redução de margem também aguardam confirmação persistida dentro do diálogo. Simular capacidade não grava. “Usar esta verba” persiste explicitamente a verba e só fecha após confirmação, mesmo quando a capacidade não pode ser estimada. Isso não comprova suficiência, presença ou compra.

Limite total continua em `evento.custo_estimado` pelo caminho canônico existente. A verba é privada; confirmação manual e backend comparam com o limite do evento. Margem admite 0 a 0,3; verba admite zero confirmado ou null para ausência; duração inteira de 1 a 24; perfis e fontes são os enums existentes. Público manual zero é válido, sem fallback à previsão.

## Persistência, idempotência e concorrência

Exemplo de conteúdo privado (demais configurações são preservadas):

```json
{
  "configuracao_planejamento": {
    "base": "manual",
    "base_confirmada": true,
    "publico": {"adultos": 40, "criancas": 0, "bebes": 0},
    "duracao": 6,
    "perfil": "premium",
    "margem": 0.1,
    "verba_alimentacao": 1450,
    "revisao": 4,
    "campos_alterados": ["duracao", "perfil", "margem", "verba_alimentacao"],
    "confirmacoes": {"identidade-do-comando": "assinatura canônica das alterações"}
  }
}
```

A transação lê proprietário e revisão atual antes da mutação. O comando compara revisão esperada. Guarda até 20 recibos recentes: repetir a mesma identidade e conteúdo devolve o estado atual sem nova revisão; reutilizar identidade com outro conteúdo falha. Uma repetição antiga cujo recibo tenha sido descartado continua sujeita à revisão esperada; não reaplica silenciosamente uma versão antiga. O datasource evita escrever novamente um documento idêntico. A entrada assistida mantém sua própria deduplicação transacional já existente.

Editores preservam a identidade da tentativa durante a repetição. Respostas verificam usuário/evento/geração; comando de outro contexto é recusado. Resposta com revisão menor não substitui uma operação mais nova. Se escolhas mudarem depois do ack, o cliente informa conflito em vez de marcar as escolhas antigas como atuais. Snapshots repetidos não desfazem edição local; alterações remotas diferentes geram aviso e preservam a edição.

Campos novos são opcionais. Configurações antigas válidas são lidas, com padrões para campos ainda ausentes, sem migração em lote. Os mapas de receita, porção, estado, serviços, rendimento, embalagem, preço, estoque e configuração própria de refeição são preservados. O comando altera somente a configuração global; não regrava regras nem eventos compartilhados.

## Restauração e histórico

A preparação consulta a operação privada e aguarda o primeiro estado válido, com erro explícito se a leitura não chegar. Quantidades não são apresentadas como atuais enquanto essa fonte estiver pendente ou com erro. No datasource, snapshots de cache ou com gravações pendentes não contam como confirmação do servidor.

A restauração cobre todos os campos, sem depender apenas de `campos_alterados` da última ação. Quando o perfil restaurado muda, consulta o catálogo desse perfil e aguarda sua carga antes de concluir a preparação ou confirmação. Um teste registra o perfil efetivamente pedido ao repositório de catálogo. Uma configuração repetida não desfaz mudanças locais. História aprovada continua sendo snapshot; voltar explicitamente ao planejamento corrente remove os valores históricos e consulta a configuração corrente. Salvar/abrir histórico não altera silenciosamente a configuração privada corrente.

## Arquivos envolvidos

- Novo comando: `lib/domain/entities/confirmacao_configuracao_calculadora.dart`.
- Domínio: `lib/domain/services/operacao_calculadora_service.dart`, `comando_texto_calculadora_service.dart`.
- Persistência: `lib/data/datasources/remote/calculadora_festa_remote_datasource.dart`.
- Controller e partes no módulo calculadora: `calculadora_festa_controller.dart`, `calculadora_festa_configuracao.dart`, `calculadora_festa_operacao.dart`, `calculadora_festa_entrada.dart`, `calculadora_festa_personalizacao.dart`, `calculadora_festa_publico.dart`.
- Interface: `calculadora_configuracao_dialog.dart`, `calculadora_comando_texto_dialog.dart`, `calculadora_capacidade_dialog.dart`, tela `calculadora_festa_screen.dart` e seções `calculadora_festa_totais.dart`, `calculadora_festa_decisoes.dart`, `calculadora_festa_planejamento.dart`.
- Regras/backend: `firestore.rules`, `publicoPlanejamentoService.ts`, `entradaAssistenteService.ts`, `interpretarEntradaCalculadora.ts`.
- Testes: `configuracao_duravel_test.dart`, ajustes de expectativa de confirmação em `calculadora_jornada_test.dart`, `calculadora_personalizacao_test.dart`, `contexto_prontidao_test.dart`; `calculadora.rules.test.js`, `testCalculadoraPlanejamento.js`.
- Integração real: `integration_test/configuracao_planejamento_emulator_test.dart`, `functions/scripts/testConfiguracaoPlanejamentoDesktop.js`.

## Resultados e limites da validação

- `flutter test test/features/calculadora test/features/eventos test/features/cardapios test/features/convidados --reporter expanded`: **411 testes aprovados**, saída 0.
- Regressão inicial falhou como esperado: duração esperada 6, obtida 4.
- O teste de capacidade no estado recebido já exigia confirmação explícita após a simulação. Foi preservado e executado; não se reintroduziu aplicação automática.
- `dart format`: arquivos Dart alterados formatados. `dart analyze` em produção, partes de controllers, testes alterados e integração: **sem problemas**.
- `node --check` nos scripts JS da entrega: aprovado. `git diff --check` nos arquivos envolvidos: sem erros de whitespace.
- Testes novos cobrem restauração de 6 horas/R$ 1.450, perda de ack e repetição sem duplicar revisão, identidade adulterada, concorrência, edição local preservada, retorno tardio de outro evento, equivalência manual/texto, zero versus ausência após reabertura, cancelar sem gravação e falha com editor mantido. Widget a 320 × 740 e fonte 1,3, incluindo teclado aberto e ações acessíveis.
- `npm --prefix functions run check:calculadora`: **aprovado**, incluindo `tsc --noEmit`, configuração completa, null/zero, limites, planejamento/IA, autorização, limite de chamadas e fallback.
- Regras Firestore no emulador: **Calculadora Firestore rules: OK**, saída 0. Cobre duração/perfil/margem/verba/recibos válidos e inválidos, null/zero e acesso negado a outro usuário/fornecedor/anônimo. PERMISSION_DENIED nas negativas é esperado.
- Serviço de entrada assistida de produção conectado ao Firestore emulado: **aprovado**, valores 6/premium/0,1/1.450 e repetição idempotente. O extrator é sintético; não houve chamada a modelo externo.
- Windows com SDKs reais de Firebase Auth/Firestore e repositórios de produção: **1 teste aprovado**, `Configuração corrente SDK real: OK`, saída 0. Recuperou configuração em novo controller sem histórico, repetiu sem nova revisão, preservou fonte/manual/público próprio e negou gravação/leitura privada a outro organizador. Evento compartilhado não recebeu configuração privada.

O harness recusa hosts fora de localhost para Auth/Firestore e fixa projeto `demo-configuracao-planejamento`. Usa evento sintético único por execução para evitar interferência de cache/estado anterior do SDK Windows. O teste exige flag QA e identidade fornecida pelo harness. Inicializa Firebase demo explícito e conecta emuladores antes da autenticação. IA/base são substitutos controlados no Flutter; Storage/presentes são sentinelas não usados. Não comprova modelo externo, upload, envio de convites ou aparelho móvel. Compilação Windows pode emitir avisos existentes de PDB/assembly de impressoras; o teste encerrou com saída 0.

## Reproduzir e ativar posteriormente

```powershell
flutter test test/features/calculadora test/features/eventos test/features/cardapios test/features/convidados --reporter expanded
npm --prefix functions run check:calculadora
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-configuracao-planejamento --config firebase.calculadora-test.json --only 'firestore,auth' "node functions/scripts/testConfiguracaoPlanejamentoDesktop.js"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
```

Executar Flutter unit/widget e build Windows sequencialmente, pois ambos podem tocar registradores de plugins gerados. O harness carrega os serviços TypeScript de produção para teste local sem regenerar os artefatos compilados do repositório.

Antes de disponibilizar o cliente, revisar e publicar regras/backend pelo processo normal do projeto. Nenhuma publicação foi executada. Sem as novas validações e o schema atualizado do backend, não considerar a entrega ativada em produção.

Roteiro móvel pendente: abrir evento, confirmar 6 horas e R$ 1.450, sair/encerrar/reabrir sem histórico; cancelar mudanças e reabrir; aplicar equivalentes por controles/texto/IA; interromper rede durante gravação e repetir; editar simultaneamente em outro acesso; alternar usuário/evento durante resposta; conferir margem padrão versus zero e verba ausente versus zero; simular capacidade sem aplicar e depois confirmar verba; conferir teclado, fonte ampliada e áreas de toque. Não há homologação Android/iOS nem declaração de conclusão da jornada inteira.
