# Revisão da documentação para a banca

Edição consolidada em 29/10/2026. Os documentos históricos foram preservados para consulta. O ponto de entrada da documentação geral do produto passa a ser `document/tcc/README.md`.

## Alterações de conteúdo

| Tema | Correção aplicada |
| --- | --- |
| Escopo | Inclusão explícita de administração, operação do fornecedor, mediação e regras financeiras |
| Arquitetura | Cliente separado do backend; responsabilidades de domain, data, presentation, app e core |
| Dados | Distinção entre modelo relacional de referência e persistência Firestore; vínculos lógicos sem prometer constraints SQL |
| Conectividade | Sincronização completa com Drift delimitada ao módulo de presentes |
| IA | Nome real da função, validação de acesso, segredo no backend, limites e fallback; retorno não confundido com persistência |
| Financeiro | Recebimento, comissão, alocação, autorização e confirmação diferenciados; transferência bancária manual |
| Regras | Versionamento atual de regras e índices reconhecido, em substituição ao achado histórico de agosto |
| Versão | Cliente 1.0.17+19 distinguido das alterações locais e publicação de backend posteriores |
| Testes | Resultados vinculados às suas entregas; contagens sobrepostas não somadas; execução interrompida preservada |
| Requisitos | Catálogo RF01 a RF15, RQ01 a RQ08, RN01 a RN10, UC01 a UC06 e V01 a V07 |
| Interfaces | Capturas identificadas como widgets com dados sintéticos; estados de falha explicados |
| Conclusões | Removidas promessas sem medição de desempenho, impacto econômico, disponibilidade e satisfação |

## Revisão técnica realizada nesta consolidação

Nas edições 1 e 2, foram lidos documentos principais e conferidos pontos críticos em middleware, IA, modelos, intermediação e configuração Firebase. Nessas etapas não foram executadas novamente as suítes funcionais; os resultados citados pertenciam aos registros referenciados. A execução nova pertence à edição 3, descrita abaixo.

## Conferências para a entrega institucional

- Validar grafia dos nomes, identificação acadêmica e orientador; nomes da capa foram recuperados da definição original do projeto.
- Adequar à norma e ao formato solicitados pela instituição quando forem definidos. Nesta etapa foi autorizado relatório sem modelo obrigatório.
- Completar revisão bibliográfica se exigida no formato final; o catálogo S01 a S18 é de fontes documentais e código do próprio projeto.
- Escolher e registrar a compilação e o backend da demonstração; executar a jornada de aceitação por perfil no ambiente escolhido.
- Incluir somente afirmações de desempenho, acessibilidade ou impacto que tenham medições próprias.
- A fonte Markdown e o Word são entregues juntos; a regeneração exige nova atualização de sumário e inspeção visual.

## Verificação de apresentação

O renderizador padrão `render_docx.py` foi tentado e falhou por ausência de LibreOffice no ambiente. O Word instalado foi usado em instância de automação oculta para atualizar campos e sumário, paginar e exportar PDF temporário. As páginas foram renderizadas com Poppler para inspeção visual. O PDF e as imagens são intermediários de revisão e não substituem o Word entregue.

A edição 1 possui 23 páginas. Todas foram inspecionadas visualmente após sua geração, incluindo sumário, tabelas, diagrama, capturas e referências. Não foram identificadas páginas vazias, texto cortado ou imagens deformadas. A verificação `git diff --check` nos caminhos alterados foi concluída sem erros.

## Edição 2 Revisão do capítulo de arquitetura

O capítulo 8 foi confrontado com os imports e com fluxos efetivos do código atual. A organização em diretórios não foi tratada como prova de aderência integral a Clean Architecture. Foram documentados acessos da apresentação a dados, resolução de dependências com GetX em gateways e a dependência indireta de Flutter por NumericInput em um serviço do domínio.

O capítulo passou a ocupar as páginas 14 a 16: organização e dependências do cliente; comunicação com serviços e exemplo real de consulta de evento; limites e recomendações. Dois diagramas substituem a visão anterior que misturava dependências e comunicação. A persistência de presentes e o uso direto de contrato de repositório no fluxo de eventos foram conferidos. Nenhuma refatoração de código foi executada.

A edição 2 possui 25 páginas, com sumário e numeração de figuras atualizados. O idioma de revisão do Word foi definido como português do Brasil. Todas as páginas da última exportação foram inspecionadas visualmente. A referência S19 registra os arquivos que sustentam esta revisão; o índice da documentação arquitetural histórica recebeu aviso sobre as diferenças de seu inventário para o código atual.

## Edição 3 Comparação funcional do aplicativo completo

O levantamento passou a cobrir os 21 diretórios funcionais de apresentação, os 854 arquivos Dart no inventário, composição, rotas, exports de backend, nomes literais de coleções, imports e testes. O relatório comparativo separa evidência estática, resultado executado, publicação histórica e homologação ainda necessária. Os hashes das fontes e logs foram preservados em analise-aplicativo-2026-10-29.

Foram ampliados escopo e requisitos RF16 a RF25 para identidade/MFA, rascunhos, público e planejador de refeições, aplicação e revisão do plano, estoque, obrigações, reputação e privacidade. Foram acrescentadas estruturas de dados e capturas atuais de testes, identificadas como cenários sintéticos com divergências visuais ainda não aprovadas.

A suíte Flutter terminou com 996 aprovados e 11 falhas. A repetição dos cinco arquivos afetados terminou com 41 aprovados e as mesmas 11 falhas. Dart analyze apontou um warning e quatro infos. Build TypeScript e checks de calculadora e financeiro passaram. Não foram alterados código de negócio, assertivas ou goldens para obter aprovação. Não houve nova execução de emuladores, integration_test em aparelho, sessão autenticada completa de produção ou deploy.

A edição 3 possui 33 páginas, todas inspecionadas visualmente após a última geração. O sumário e as referências S01 a S25 foram atualizados. A documentação registra leituras amplas de eventos nas regras locais e limites de lotes de atendimento de dados como pendências de análise e homologação, sem afirmar privacidade ou remoção integral garantidas.

## Edição 4 Aprofundamento do núcleo técnico

A leitura do texto fornecido pelo usuário confirmou que a edição 3 funcionava como visão geral, com pouco detalhamento para a complexidade do produto. A edição 4 amplia de 6 para 14 os casos de uso, mantém os 25 requisitos e acrescenta sua decomposição em critérios críticos, amplia as regras de RN01–RN10 para RN01–RN22 e utiliza 31 referências internas.

Foram incluídos estados comerciais e de execução, sequência transacional de confirmação, decisões arquiteturais reconstruídas do código, fronteiras de implantação, relações entre agregados, dicionário de campos centrais, memória de cálculo e exemplo fictício, validação retrospectiva de medições, contratos de integração, tratamento de erros, orientação por perfil, glossário e guia técnico. A matriz de cenários propostos não foi apresentada como resultado já executado.

A edição 3 foi preservada em historico/Documentacao_do_Software_Faca_a_Festa_edicao3.docx. A fonte atual possui aproximadamente 17 mil palavras, 9 figuras e 59 páginas na exportação do Word. As 59 páginas foram inspecionadas visualmente. Foram corrigidas quebras que isolavam continuações curtas e ajustados diagramas e larguras de tabelas. Na última regeneração, somente as imagens das páginas 34 e 35 mudaram, conforme comparação de hashes; ambas foram novamente inspecionadas.

O renderizador empacotado foi novamente tentado e confirmou ausência de soffice.exe. A verificação utilizou Word COM oculto para campos, sumário e exportação e Poppler para imagens. Não houve edição de código do aplicativo, testes, goldens, regras ou serviços de produção nesta ampliação. Os resultados de execução de testes permanecem os da revisão anterior, com 11 falhas Flutter registradas. Os módulos auxiliares e o dicionário completo de todos os campos ainda exigem detalhamento próprio; estudos acadêmicos e empíricos não foram inventados para preencher essas lacunas.
