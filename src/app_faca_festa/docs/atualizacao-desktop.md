# Instalação e atualização Windows — Faça a Festa

Publicação atual em **14/10/2026: 1.0.9+11**, disponível em https://faca-a-festa.web.app/desktop/. Pacotes, assinaturas e downloads verificados; registro em [publicacao-1.0.9.md](publicacao-1.0.9.md).

Pacote local validado em **11/10/2026: 1.0.7+9**. Setup: `release/windows-installer/2026-10-11/FacaFesta_Setup_v1.0.7.9.exe` (51.329.930 bytes). SHA-256: `26f6460b224999c75cc96300486bc2c9646a9113932f2169bc41fdaa0fe56b62`. Não houve instalação real, commit, push ou publicação externa.

O projeto é Flutter/GetX, com Firebase Auth/Firestore e Drift/SQLite para presentes. O instalador existente é Inno Setup 6; a versão vem de `pubspec.yaml`. A referência analisada foi `D:\repository\flutter\pdv\cardapio_digital`: seus arquivos, catálogo, credenciais e chave privada não foram alterados nem reutilizados.

## Publicar a próxima versão

Na raiz deste projeto:

```powershell
# Apenas gerar e validar localmente:
python build_production.py --windows

# Somente após autorização para publicação:
python build_production.py --windows --web --bundle --deploy
```

O comando incrementa patch e build uma vez. Windows, web e Android selecionados usam esse mesmo `pubspec`; a publicação só começa depois do sucesso de todos. O instalador já gerado é assinado/publicado sem um segundo build. Gerar AAB **não envia à Play Store**. `--no-bump` mantém a versão já escolhida e ainda não publicada. Um build distribuído não pode ser substituído, mesmo com outro número de versão: publique um build maior. Os campos Windows devem ficar até 65535.

Se o upload do pacote concluir mas o Hosting falhar, preserve o Setup original: não o recompile com o mesmo build. Reexecute `node tool/desktop_release.cjs --installer="caminho do Setup original" --publish`, copie `release/desktop-feed/desktop` para `build/web/desktop` sem a subpasta `packages` e retome `firebase deploy --project faca-a-festa --only hosting`. O objeto existente só é reutilizado se seus bytes/versão forem idênticos.

`--windows --deploy` usa o web já existente em `build/web`, sem recompilá-lo; se não existir, gere também `--web`. Um deploy somente `--web` preserva o catálogo desktop público atual e falha se não conseguir consultá-lo. Na primeira publicação, se o endpoint ainda devolver a página Flutter em vez de JSON, configure explicitamente `$env:FACA_FESTA_FIRST_PUBLICATION='1'` para aquele comando e depois remova a variável. Não execute publicações concorrentes.

Requisitos: Flutter, Python, Node.js, Inno Setup 6, PowerShell, Firebase CLI autenticada no projeto `faca-a-festa` e `npm --prefix functions ci`. O publicador de Storage usa Application Default Credentials do Faça a Festa (`GOOGLE_APPLICATION_CREDENTIALS` apontando para arquivo fora do repositório, ou credenciais locais do Google). Hosting usa o login do Firebase CLI. Não copie credenciais do Cardápio Digital. O bucket padrão é `faca-a-festa.firebasestorage.app`; `FACA_FESTA_UPDATE_BUCKET` permite escolher outro bucket **do mesmo projeto**.

Distribua, **depois da primeira publicação e verificação**, o link permanente:

**https://faca-a-festa.web.app/desktop/**

O catálogo é `/desktop/updates/latest.json`; o feed assinado é `/desktop/updates/appcast.xml`. O catálogo e a página são publicados no Hosting do próprio Faça a Festa. Os executáveis ficam separados em `desktop-faca-festa/releases/build-N/` no Storage, com precondição de criação, checksum e cache imutável. Nada usa o Hosting ou Storage do Cardápio Digital.

## Chave do atualizador e assinatura Windows

A chave Ed25519 independente criada nesta implementação está em:

`C:\Users\User\AppData\Local\FacaFesta\publishing\desktop-ed25519.key`

Somente a pública está em `windows/runner/updater_public_key.h`. Faça um backup criptografado da privada, com acesso restrito, e restaure a mesma chave em outra máquina publicadora. `FACA_FESTA_UPDATE_PRIVATE_KEY` permite apontar para esse backup restaurado fora do projeto. **Não gere outra chave para as próximas versões**: clientes já instalados só confiam na pública distribuída. O publicador exige correspondência entre as chaves e verifica a assinatura antes de disponibilizar o pacote. A chave privada nunca entra no instalador.

Ed25519 autentica o pacote perante o atualizador; **não é Authenticode reconhecida pelo Windows**. Não foi configurado certificado Authenticode nesta implementação. Para habilitar assinatura dos executáveis e do instalador, obtenha um certificado de assinatura de código e configure `FACA_FESTA_AUTHENTICODE_CERT_SHA1` (certificado no repositório de certificados Windows), `FACA_FESTA_SIGNTOOL` e `FACA_FESTA_AUTHENTICODE_TIMESTAMP_URL` fornecido pela autoridade certificadora. O comando assina e verifica com SignTool antes de assinar o pacote Ed25519. Não desative SmartScreen; assinatura não garante ausência de seus avisos.

## Comportamento e preservação de dados

A versão e o build exibidos vêm dos metadados compilados do executável Windows, também usados no título da janela. O app consulta ao iniciar, a cada hora e por “Verificar atualizações”. O WinSparkle 0.9.4, fixado por SHA-256, verifica Ed25519 antes de entregar um pacote; o JSON não escolhe uma URL executável arbitrária. Nenhuma instalação ocorre quando o download termina: o operador deve confirmar “Atualizar e reiniciar”.

A barreira `UpdateOperations` acompanha Futures dos repositórios, sincronização de presentes e exportação/compartilhamento. Bloqueia durante gravações, cotações, reservas/contribuições, uploads, exportações e também consultas em andamento (bloqueio conservador). Carrinho de cotação não vazio e EasyLoading ativo também impedem a atualização. Não há fila de impressão térmica neste projeto; os fluxos encontrados geram/compartilham documentos. Salve formulários ainda não submetidos antes de confirmar. Novos fluxos assíncronos de gravação/exportação devem usar `UpdateOperations.run`.

Após confirmação, a barreira fecha para novas operações, interrompe a escuta de sincronização, espera a fila do GetStorage, verifica/grava sua cópia persistida, aguarda gravações Firestore pendentes e fecha Drift. Tudo tem prazo de preparação de 20 segundos. Sem rede, gravações Firestore pendentes podem impedir a instalação; o app informa a falha, retira o carregamento e exige reabertura antes de outra tentativa, pois o banco pode já estar fechado. O aviso está acima do Navigator, menus e EasyLoading.

O canal nativo só inicia o auxiliar após a preparação e solicita **WM_CLOSE**, sem `SystemNavigator.pop`. O auxiliar, copiado para temporários, aguarda apenas o PID deste app por até 60 segundos, revalida SHA-256 com o arquivo protegido contra escrita, executa Inno sem fechar/forçar outros aplicativos e usa a pasta de instalação atual. Aguarda o instalador por até 10 minutos. Em cancelamento/falha, tenta reabrir a versão anterior; se o instalador exceder o prazo, avisa e não reabre enquanto ele pode estar gravando. A instalação pode solicitar UAC.

São mantidos o AppId do Inno, nome do executável e caminhos atuais: `faca_festa.sqlite`, `GetStorage.gs` e `GetStorage.bak` em Documentos do usuário, além da persistência Firebase da sessão. O instalador só substitui os arquivos do programa; não apaga/migra esses dados. Atualizações e desinstalação não removem esse banco/configurações. Não mova os arquivos para Program Files. Foi incluído em `dist/VC_redist.x64.exe` o runtime x64 oficial da Microsoft, obtido de `https://aka.ms/vs/17/release/vc_redist.x64.exe`, com Authenticode Microsoft validada. Preserve/reponha esse arquivo para empacotá-lo nas próximas versões; o comando valida a assinatura antes de empacotar. O Inno instala o runtime se a versão 14.44 ou superior ainda não existir.

## Migração e validação

Clientes anteriores ao primeiro build com atualizador precisam instalar o novo Setup **uma única vez**, no mesmo usuário Windows e na instalação existente. Faça isso primeiro em terminal piloto com backup; confirme que sessão, dados, configurações e atalhos permanecem. Depois passam a usar o atualizador interno.

Testes locais, sem instalação real ou acesso a dados de cliente:

```powershell
flutter test test/desktop_update_service_test.dart
python tool/test_build_production.py
node tool/test_desktop_release.cjs
powershell -File tool/compile_native_tests.ps1
powershell -File tool/test_update_helper.ps1 -HelperPath .codex_tmp/native-tests/helper.exe
powershell -File tool/test_update_helper_failures.ps1
node tool/test_desktop_download.cjs
flutter test test/desktop_update_overlay_test.dart
python tool/verify_windows_release.py
node tool/test_staged_desktop_download.cjs
```

O smoke usa servidor HTTP **somente local** e pacote sintético; produção usa HTTPS fixo. Não executa o pacote baixado. Testa assinatura íntegra, adulteração e build antigo/igual com WinSparkle real. Fixtures do auxiliar testam ordem, hash adulterado, falha do instalador, espera do processo e timeouts, sem matar processos. O alvo nativo de teste tem prazos reduzidos; o instalador contém somente o auxiliar com os prazos de produção.

Depois de publicar, consulte os dois endpoints, baixe o pacote, compare `sha256` e `size` com o catálogo e valide Ed25519 usando a pública incorporada. Faça um ciclo real N → N+1 em terminal piloto, incluindo UAC cancelado, rede indisponível, carrinho aberto, gravação pendente, menus/diálogos sobrepostos e reinicialização. Testes simulados não substituem essa validação.

Resultado local: **50 testes Flutter aprovados** (47 de fluxo/repositórios e 3 de interface), dois testes Python de ordenação da produção, verificações Node de identidade/imutabilidade e cenários nativos do auxiliar aprovados. O WinSparkle real baixou e validou tanto a fixture assinada quanto o **Setup real 1.0.7+9** pelo servidor local, sem executar instaladores; adulteração e build antigo/igual foram rejeitados. Foram conferidos SHA-256, assinatura Ed25519, metadados de versão do exe/Setup, chave pública incorporada, DLL, auxiliar, SQLite, AOT, ICU, assets e licença. A análise dos arquivos do atualizador está limpa. O teste real de preservação de sessão/dados, UAC, título da janela e atualização instalada continua reservado ao terminal piloto. Web e AAB não foram compilados nesta validação; a ordem conjunta foi testada com executores simulados. Endpoints públicos ainda não foram publicados/verificados.

Referência técnica: [API oficial WinSparkle 0.9.4](https://github.com/vslavik/winsparkle/blob/v0.9.4/include/winsparkle.h).

## Acesso por perfil no Windows

O painel administrativo e o cabeçalho do fornecedor têm o botão “Versão e atualizações do aplicativo”. Ele abre a versão instalada e a ação manual; quando o pacote está validado, o ícone muda para atualização disponível. O rodapé flutuante foi removido para não cobrir a navegação do organizador. No mobile os controles Windows não aparecem. A verificação inicial e periódica continua independente do perfil autenticado; o instalador atualiza a mesma aplicação. A confirmação, os bloqueios de operações e a preparação dos dados permanecem obrigatórios. Erros de preparação aparecem acima de menus e diálogos; indisponibilidade passiva da rede não ocupa a tela.

Esta revisão de interface ainda precisa ser incorporada a um novo build/instalador; o Setup 1.0.7+9 gerado anteriormente não contém esses ajustes.

Validação desta revisão: 16 testes Flutter de serviço/interface aprovados, incluindo confirmação/cancelamento, bloqueio de operação, falha acima de diálogos, botão contextual Windows, rede indisponível sem sobreposição e ausência no Android. Validação visual dos painéis reais fica pendente no terminal piloto.

Avisos de consulta, download e preparação são exibidos dentro do painel de atualizações, acima do Navigator. Não há faixa de notificação no topo da tela principal. Ao falhar a preparação, o painel retorna sem carregamento e apresenta o erro.
