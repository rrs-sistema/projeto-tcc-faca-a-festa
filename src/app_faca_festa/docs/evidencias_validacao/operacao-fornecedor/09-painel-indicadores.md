# 09 â€” Painel operacional e indicadores rastreÃ¡veis

ValidaÃ§Ã£o local em 27/10/2026. RepositÃ³rio existente, branch main, com alteraÃ§Ãµes anteriores preservadas. NÃ£o foram encontrados AGENTS.md aplicÃ¡veis no repositÃ³rio/ancestrais durante a inspeÃ§Ã£o inicial. Sem deploy, commit, push, escrita em produÃ§Ã£o, dependÃªncias novas ou plataforma externa.

## ImplementaÃ§Ã£o e fontes

O resumo do fornecedor agora abre com fila operacional e navegaÃ§Ã£o para Atendimentos, Agenda, Financeiro e ReputaÃ§Ã£o. Indicadores ficam separados dos atalhos CatÃ¡logo, Estoque, Perfil/configuraÃ§Ãµes e ComissÃµes. O painel antigo de cartÃµes equivalentes e mÃ©tricas estimadas nÃ£o alimenta a nova visÃ£o. A IA continua disponÃ­vel na elaboraÃ§Ã£o de propostas com revisÃ£o humana; o Ã­ndice heurÃ­stico das solicitaÃ§Ãµes deixou de ser apresentado como porcentagem de probabilidade.

`consultarPainelFornecedorFn` usa exclusivamente o UID autenticado, exige perfil F ativo e recusa identificador de outro fornecedor. As consultas sÃ£o limitadas ao fornecedor, inclusive orÃ§amentos, participaÃ§Ãµes de cotaÃ§Ã£o, agenda, finanÃ§as e avaliaÃ§Ãµes verificadas. NÃ£o hÃ¡ acesso administrativo geral novo. As fontes independentes podem falhar isoladamente: a fonte indisponÃ­vel fica nula, o painel fica parcial e os demais alertas continuam visÃ­veis.

| InformaÃ§Ã£o | Origem e critÃ©rio |
|---|---|
| Primeira resposta | Envio da participaÃ§Ã£o da cotaÃ§Ã£o atÃ© primeira mensagem humana do fornecedor ou proposta com autoria do fornecedor. Mensagens de sistema, cliente, eventos anteriores ao envio e futuros sÃ£o excluÃ­dos; reenvios posteriores nÃ£o reiniciam a mediÃ§Ã£o. |
| PerÃ­odo comercial | Ãšltimas 720 horas corridas por padrÃ£o, intervalo fechado no inÃ­cio e aberto no fim [de, atÃ©). Horas corridas, sem supor expediente comercial; apresentaÃ§Ã£o em America/Sao_Paulo. PerÃ­odos explÃ­citos sÃ£o validados pelo backend, atÃ© 366 dias, sem futuro. |
| Amostra | Quantidade de solicitaÃ§Ãµes com primeira resposta comprovada. Sem resposta, sem evidÃªncia histÃ³rica e sem data de envio aparecem explicitamente, sem mÃ©dia zero. O campo legado data_resposta nÃ£o substitui o evento original. |
| ConversÃ£o | SolicitaÃ§Ãµes ganhas vigentes com vÃ­nculo contratual / solicitaÃ§Ãµes recebidas na coorte. Perdidas, recusadas, canceladas, abertas e ganhas sem vÃ­nculo sÃ£o separados. Sem denominador, sem amostra. |
| ContrataÃ§Ãµes | Identidade contrato_financeiro.id_contrato; legado agrupado por cotaÃ§Ã£o quando disponÃ­vel, senÃ£o orÃ§amento. Somente contrataÃ§Ã£o reconhecida pela polÃ­tica existente ou histÃ³rico cancelado identificado. Data de aceite/proposta ou fechamento/snapshot existente, sem data inventada. Espelhos divergentes tornam a fonte indisponÃ­vel. |
| ConcluÃ­das | Estado atual aceito da execuÃ§Ã£o dos contratos da coorte de aceite. NÃ£o significa entregas ocorridas no perÃ­odo nem nova venda. Canceladas sÃ£o separadas. |
| ReputaÃ§Ã£o | Mesma validaÃ§Ã£o registrosConfiaveis da gestÃ£o de reputaÃ§Ã£o; tipo fornecedor, visibilidade e perÃ­odo. Legado sem comprovaÃ§Ã£o nÃ£o entra como verificado. AvaliaÃ§Ã£o de serviÃ§o pode gerar aÃ§Ã£o de resposta sem duplicar a mÃ©dia do fornecedor. |
| Movimento financeiro | ServiÃ§o canÃ´nico de planejamento, todas as datas registradas, explicitamente identificado na tela. NÃ£o Ã© saldo bancÃ¡rio, previsÃ£o garantida nem pagamento declarado pelo cliente. Falha nÃ£o vira zero. |

A fila usa todas as pendÃªncias atuais, independentemente da coorte histÃ³rica: atendimento aguardando fornecedor/cliente, prazo persistido vencido quando existente, compromisso operacional vigente/prÃ³ximos sete dias, repasse efetivamente impedido pela polÃ­tica atual, despesa com vencimento conhecido e saldo, avaliaÃ§Ã£o verificada sem resposta. Sem horÃ¡rio/prazo nÃ£o se inventa vencimento. CotaÃ§Ã£o ganha sem vÃ­nculo pede conferÃªncia, nÃ£o cria compromisso. Motivo, responsabilidade, fonte e prazo conhecido acompanham cada aÃ§Ã£o. A mÃ©dia histÃ³rica de 1 hora nÃ£o retira o atendimento parado hÃ¡ 64 horas.

## NavegaÃ§Ã£o, atualizaÃ§Ã£o e privacidade

Cada botÃ£o passa a identidade real: jornada por idCotacao/idFornecedor, agenda por idOrcamento, acompanhamento por evento/orÃ§amento/fornecedor, planejamento por idObrigacao, reputaÃ§Ã£o por idAvaliacao. Planejamento destaca a obrigaÃ§Ã£o autorizada; a consulta de reputaÃ§Ã£o valida o foco e mantÃ©m a base canÃ´nica dos agregados. Voltar ao painel atualiza a consulta.

Controller descarta respostas de requisiÃ§Ã£o anterior e de outra sessÃ£o, limpa os dados na troca, cancela assinaturas/timer ao encerrar e invalida tambÃ©m a fachada antiga de estatÃ­sticas. AtualizaÃ§Ã£o falha preserva apenas a Ãºltima leitura do mesmo usuÃ¡rio com aviso; esse aviso permanece atÃ© sucesso. ApÃ³s cinco minutos, os dados sÃ£o marcados desatualizados. AtualizaÃ§Ã£o manual e pull-to-refresh disponÃ­veis. NÃ£o existe atualizaÃ§Ã£o instantÃ¢nea garantida entre consultas.

A fila e os cartÃµes usam conteÃºdo expansÃ­vel, botÃµes nativos com semÃ¢ntica/teclado e rodapÃ© respeitado. Falha inicial oferece retry; ausÃªncia de amostra e fonte parcial ficam visÃ­veis.

## Arquivos desta implementaÃ§Ã£o

- functions/src/services/fornecedores/painelOperacionalService.ts e export em functions/src/index.ts.
- functions/src/services/avaliacoes/gestaoReputacaoService.ts: consulta focada autorizada.
- lib/presentation/modules/fornecedor/controllers/painel_operacional_controller.dart e fornecedor_painel_ao_vivo.dart; integraÃ§Ã£o em fornecedor_controller.dart.
- lib/presentation/modules/fornecedor/sections/painel_operacional_fornecedor.dart, resumo_section.dart, solicitacoes_section.dart e pages/fornecedor_home_screen.dart.
- lib/app/routes/app_routes.dart; controller/widget de gestÃ£o de reputaÃ§Ã£o; planejamento_financeiro_page.dart para focos de navegaÃ§Ã£o.
- functions/scripts/testPainelFornecedorEmulator.js, test/features/painel/painel_operacional_test.dart, duas fixtures JSON retornadas pelo emulador e comando test:painel:fornecedor em package.json.

Nenhum Ã­ndice novo: reutilizado collectionGroup fornecedores/id_fornecedor ASC jÃ¡ existente em firestore.indexes.json. Nenhuma concessÃ£o de regras ampliada; o endpoint lÃª via Admin SDK apÃ³s restringir explicitamente o fornecedor. NÃ£o altera fatos financeiros, contrataÃ§Ã£o ou nota para construir indicadores.

## VerificaÃ§Ãµes executadas

Ambiente Windows/PowerShell, Flutter/Dart local e JDK 21 para Firestore Emulator. Projeto sintÃ©tico demo-painel-fornecedor; relÃ³gio fixo 31/05/2030 15:00 UTC nas fixtures (nÃ£o sÃ£o dados reais ou datas atuais).

```powershell
$env:JAVA_HOME = Join-Path $env:TEMP 'codex-chat-jdk/jdk-21.0.12.1+1'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
npm run test:painel:fornecedor
flutter test test/features/painel --update-goldens --reporter expanded
flutter test test/features/painel test/features/avaliacoes/gestao_reputacao_test.dart test/features/planejamento test/features/agenda test/features/cotacoes --reporter expanded
```

- Backend TypeScript compilado e teste Firestore Emulator: PASS, saÃ­da 0. Exercita documentos persistidos de cotaÃ§Ã£o/mensagens/propostas, contrataÃ§Ã£o, agenda, planejamento, impedimento de repasse, criaÃ§Ã£o real de avaliaÃ§Ã£o elegÃ­vel, agregados e consulta focada. Inclui fornecedores distintos, cliente, administrador, ausÃªncia de autenticaÃ§Ã£o, mÃ©tricas/perÃ­odos, reenvio, cancelamento/perda/recusa e corrupÃ§Ã£o real de espelho financeiro que torna a fonte indisponÃ­vel. NÃ£o usa somente mocks como prova de integraÃ§Ã£o.
- RegressÃ£o Flutter: **65 testes aprovados**, incluindo **12 do painel**. As fixtures do painel sÃ£o saÃ­das reais do teste de emulador; o gateway Ã© substituÃ­do apenas para transportar esses dados no teste de widget. Cobre estado parcial, sem amostra, retry, troca de sessÃ£o/consulta antiga, atualizaÃ§Ã£o, todos os destinos/argumentos dos alertas, tecla Enter, semÃ¢ntica, fonte ampliada 2x, larguras 360/1280 e comparaÃ§Ã£o de imagens 360/1600. O teste final rodou sem atualizar goldens.
- AnÃ¡lise estÃ¡tica dos 11 arquivos Dart de integraÃ§Ã£o alterados e test/features/painel: **No issues found**. Build TypeScript incluÃ­do no comando de backend.

## EvidÃªncias visuais

Imagens de widgets executados com Poppins e Ã­cones existentes do aplicativo, dados sintÃ©ticos vindos do emulador e Scaffold/rodapÃ© de teste. SÃ£o comparaÃ§Ãµes reproduzÃ­veis, nÃ£o captura de aplicativo instalado autenticado em produÃ§Ã£o.

![Celular: fila e pendÃªncia de 64 horas](09-painel-celular.png)
![Celular: indicadores e amostra](09-painel-celular-indicadores.png)
![Desktop](09-painel-desktop.png)

## Limites explÃ­citos

NÃ£o houve teste manual do aplicativo instalado em Windows/dispositivo, leitor de tela externo ou implantaÃ§Ã£o do callable em ambiente hospedado. IntegraÃ§Ã£o foi executada diretamente nos serviÃ§os reais com Firestore Emulator; transporte callable e autenticaÃ§Ã£o hospedada nÃ£o foram exercitados ponta a ponta. Sem eventos antigos comprovÃ¡veis, a mÃ©dia fica parcial; nÃ£o hÃ¡ migraÃ§Ã£o nem reconstruÃ§Ã£o artificial. A leitura de fontes diferentes nÃ£o representa snapshot transacional global: cada fonte informa sua atualizaÃ§Ã£o e o painel explicita incompletude. O endpoint usa o volume atual de participaÃ§Ãµes do fornecedor para calcular sua coorte; bases muito grandes podem exigir agregaÃ§Ã£o incremental futura, sem alterar o critÃ©rio aqui implementado.
