# Levantamento da documentação do Faça a Festa para o TCC

Data: 29 de outubro de 2026.

## Conclusão

Já existe documentação do software Faça a Festa. O principal ponto de partida é `D:/repository/unicesumar/tcc/app/documentos/Documentação do Projeto.docx`, que reúne definição do problema, objetivos, escopo, requisitos funcionais e não funcionais, design, arquitetura e estratégia de testes.

Entretanto, entre os materiais examinados, não foi identificado um documento único atualizado que consolide o produto entregue, seus requisitos, arquitetura, dados, interfaces, validação e conclusões para a banca. A recomendação é produzir esse documento a partir do material existente, revisando divergências e separando proposta, implementação e resultados demonstrados.

Este levantamento avalia conteúdo documental. Não constitui auditoria completa do código, revisão visual de todas as páginas e diagramas, comprovação de publicação atual ou nova execução dos testes descritos nas fontes. O formato institucional exigido pela banca não foi identificado nos documentos principais examinados e deve ser confirmado com o orientador.

## Acervo encontrado

Contagem de arquivos antes da criação deste levantamento. Inclui cópias, arquivos temporários e evidências; não representa quantidade de documentos independentes.

| Diretório | Arquivos | Característica do acervo |
| --- | ---: | --- |
| `D:/repository/unicesumar/tcc/app/documentos` | 96 | Base acadêmica, Word e PDF, casos de uso, diagramas, modelos SQL e NoSQL |
| `D:/repository/unicesumar/tcc/app/src/app_faca_festa/docs` | 418 | Evolução técnica, auditorias, planos, publicações, roteiros e evidências de validação |
| `D:/repository/unicesumar/tcc/app/src/app_faca_festa/document` | 19 | Arquitetura, mapeamento Firebase, IA, orçamento e modelo SQL para representação |

### Base acadêmica em documentos

Os caminhos desta subseção são relativos a `D:/repository/unicesumar/tcc/app/documentos`.

| Material | Conteúdo identificado | Uso recomendado |
| --- | --- | --- |
| `Documentação do Projeto.docx` | Problema, objetivos, escopo, requisitos, design, arquitetura e testes | Documento base para a consolidação; atualizar antes da entrega |
| `TCC definição.pdf` | Identificação acadêmica, problema, objetivos e escopo inicial, com ano 2025 | Recuperar a motivação e delimitar a evolução do projeto |
| `Mapeamento de mercado de eventos.pdf` | Contexto de Curitiba, concorrentes, estimativas de gastos e referências | Apoiar a justificativa; verificar referências e sustentação dos números antes de reutilizá-los |
| `casos-de-usos/Casos de Uso Descritivos - Completo.docx` | Atores, objetivos, pré e pós-condições, fluxos, regras e relações entre casos | Base para os casos de uso finais; revisar numeração e aderência ao produto |
| `casos-de-usos/000 ... 016 ...` | Documentos individuais de cadastro, eventos, convidados, checklist, orçamento, pagamento, serviços, cotações, avaliações e presença | Detalhamento e possíveis apêndices; evitar duplicar todo o conteúdo no corpo |
| `documentação-da-arquitetura/Documentação da Arquitetura.docx` | Camadas, fluxo de dados, sincronização, padrões, SOLID, GetX e testes | Referência histórica; contém promessas amplas que precisam ser corrigidas |
| `modelagens/Dicionário de Dados – Projeto Faça a Festa.docx` e `Documentação das Tabelas – Projeto Faça a Festa.docx` | Campos e relações descritos com tipos e constraints relacionais | Modelo relacional de referência; não apresentar como esquema físico do Firestore |
| `modelagens/Modelagem NoSQL - Projeto Faça a Festa.docx` | Exemplo de estruturas JSON e agregação de dados | Referência inicial; conferir nomes, campos e distinção entre arrays e subcoleções |
| Diagramas em `diagramas`, `modelagens`, `casos-de-usos` e arquivos Draw.io | Artefatos de processo, atividade, sequência, casos de uso e dados | Selecionar e revisar os que correspondem à versão demonstrada |

O arquivo `Checklist de Diagramas para o TCC.docx` apresentou apenas o título na extração textual. Isso não permite considerá-lo um checklist textual preenchido; conteúdo gráfico precisa ser conferido visualmente. O arquivo `~$R – Projeto Faça a Festa.docx` é um arquivo temporário do Word e deve ser desconsiderado como documento.

### Documentação técnica em document

Os caminhos desta subseção são relativos à raiz do aplicativo.

| Material | Conteúdo e limite |
| --- | --- |
| `document/arquitetura/README.md` e arquivos `01`, `02`, `03` | Melhor ponto de partida encontrado para a arquitetura geral; descreve camadas, composição, módulos e fluxos, com inventário de setembro de 2026 |
| `document/README.md` | O texto é específico do módulo de presentes, apesar do nome genérico |
| `document/documentacao_arquitetural.md` | Também trata do módulo de presentes; não cobre sozinho o sistema completo |
| `document/MAPEAMENTO_FIREBASE_APRESENTACAO.md` | Levantamento de coleções, campos, vínculos e riscos em 11/08/2026; necessita atualização |
| `document/GUIA_MODELO_SQL_VYCANIS.md` e `document/modelo_sql_vycanis.sql` | Representação relacional para engenharia reversa e DER; a existência do DDL não comprova uso de SQL como backend |
| `document/BACKEND_IA_GENERATIVA_CALCULADORA_FESTA.md` e `document/Documento_Tecnico_Backend_IA_Generativa_Faca_a_Festa.docx` | Proposta técnica de integração generativa com contratos, validação e fallback; contém linguagem de planejamento e não comprova por si só entrega integral |
| `document/README_ORCAMENTO.md`, `README_IA_INTERFACE.md`, `README_ia_recomendacao_fornecedores.md`, `VERSIONAMENTO_IA.md` | Fontes complementares por módulo; conferir com implementação e evidências antes de incorporá-las |

Há dois arquivos com nomes iniciados em `Apresentacao_` e terminados em `.pptx.inspect.ndjson`. São registros de inspeção, não apresentações `.pptx` utilizáveis. Nenhum `.pptx` foi encontrado nos três diretórios inventariados.

### Histórico e evidências em docs

O diretório contém material sobre calculadora e jornada do evento, ergonomia administrativa, orçamentos, contratação, comissões, repasses, auditoria e publicação. `docs/evidencias_validacao` reúne relatórios, capturas e saídas de validação que podem apoiar o capítulo de resultados.

As evidências devem ser selecionadas por versão e cenário. Um roteiro de teste não equivale a execução; um teste de domínio ou widget não equivale a uma validação completa de produção. Alguns relatos declaram explicitamente cenários não executados naquela entrega.

`docs/publicacao-1.0.17.md` registra uma entrega de 23/10/2026 e seus testes, compilação e publicação. O `pubspec.yaml` consultado declara `1.0.17+19`. Esses dados são referências locais; a versão a ser apresentada deve ser congelada e identificada no documento final.

## Divergências a resolver antes da banca

| Tema | Evidência encontrada | Ajuste necessário |
| --- | --- | --- |
| Banco remoto | A documentação inicial usa entidades SQL e prevê MySQL; a documentação posterior descreve Firestore | Separar modelo conceitual, representação relacional e persistência efetivamente usada |
| Funcionamento offline | O Word de arquitetura afirma que toda operação é persistida localmente; `document/arquitetura/01-camadas-e-regras.md` restringe Drift com sincronização completa ao módulo de presentes | Descrever o comportamento por módulo, incluindo dependências de rede |
| Regras e índices | O mapeamento de agosto afirma ausência de versionamento; o `firebase.json` atual referencia `firestore.rules` e `firestore.indexes.json` | Atualizar esse achado histórico; a referência no arquivo não comprova implantação das regras |
| Abrangência arquitetural | Os arquivos genéricos de arquitetura em `document` descrevem presentes; a subpasta `arquitetura` descreve o cliente completo | Usar a documentação geral como base e os textos de presentes como exemplo de módulo |
| Pagamentos | `docs/operacao-contratacao-repasses.md` descreve conferência e transferência bancária manual | Distinguir registro financeiro, autorização e repasse de uma integração bancária automática |
| IA | Os documentos de backend apresentam recomendações e roadmap | Confirmar funções, contratos, tratamento de falha e evidências da versão apresentada; separar cálculo determinístico de análise generativa |
| Requisitos de qualidade | O documento base traz resposta inferior a 2 segundos e “até n usuários simultâneos” | Definir critérios mensuráveis; metas sem medição devem permanecer como requisitos ou pendências, não resultados |
| Plataformas | O Word de arquitetura inclui iOS; os registros recentes examinados documentam Web, Windows e Android | Declarar como entregue apenas o que puder ser demonstrado e sustentado por evidências |
| TDD e qualidade | Os textos iniciais afirmam adoção ampla de TDD, SOLID e padrões | Apresentar exemplos verificáveis e resultados; testes existentes não comprovam sozinhos a sequência de desenvolvimento TDD |
| Casos de uso | Há documentos individuais e uma versão consolidada com organização própria | Definir identificadores oficiais e conferir relações include/extend, regras e fluxos antes de reutilizar os diagramas |

## Cobertura documental para o documento final

| Parte | Situação no material examinado | Trabalho necessário |
| --- | --- | --- |
| Problema, objetivos e justificativa | Base existente | Revisar redação, delimitação e fontes |
| Escopo e atores | Base existente | Atualizar administração e os fluxos financeiros e inteligentes incluídos na entrega |
| Requisitos e regras de negócio | Base existente, sem consolidação atual identificada | Criar catálogo com identificadores, critérios de aceite e situação de entrega |
| Casos de uso e diagramas | Acervo amplo | Selecionar, unificar e validar aderência |
| Arquitetura | Base técnica geral e documentação histórica | Consolidar a visão atual com limites e decisões justificadas |
| Dados | Modelos SQL, NoSQL e mapeamento Firebase | Atualizar dicionário de coleções e explicar as representações |
| Interfaces e operação | Capturas e relatos distribuídos | Selecionar telas atuais e explicar uma jornada por perfil |
| Segurança e permissões | Material técnico e roteiros específicos | Consolidar autenticação, autorização, proteção de dados e evidências |
| Metodologia do desenvolvimento | Afirmações técnicas nos documentos iniciais | Relatar o processo efetivamente seguido, com evidências e decisões |
| Testes e resultados | Evidências disponíveis por entrega | Montar matriz requisito → cenário → evidência → resultado e registrar limites |
| Conclusões, limitações e trabalhos futuros | Trechos pontuais | Redigir conclusão geral vinculada aos objetivos e resultados |
| Formatação acadêmica e referências | Identificação acadêmica em alguns PDFs | Aplicar o modelo confirmado com o orientador e revisar referências |

## Estrutura sugerida para a consolidação

Título sugerido: **Documentação do Software Faça a Festa**. Se a instituição exigir artigo, monografia ou relatório técnico com estrutura própria, adaptar a organização ao modelo institucional.

1. Introdução: contexto, problema, justificativa, objetivo geral e objetivos específicos.
2. Escopo da solução: público, atores, funcionalidades entregues e limites.
3. Metodologia: levantamento, modelagem, desenvolvimento, versionamento e validação efetivamente realizados.
4. Requisitos e regras de negócio: identificadores, critérios de aceite, prioridades e rastreabilidade.
5. Modelagem funcional: casos de uso e diagramas essenciais de atividade e sequência.
6. Arquitetura e tecnologias: cliente Flutter, camadas, GetX, Firebase, Cloud Functions e persistência local por módulo.
7. Modelagem de dados: visão conceitual, coleções e subcoleções, campos, vínculos e decisões de persistência.
8. Implementação e interfaces: jornadas do organizador, fornecedor, convidado e administrador; calculadora e IA conforme a versão entregue.
9. Segurança e operação: permissões, validações, auditoria, dependências de rede e regras financeiras.
10. Testes e resultados: método, ambiente, cenários, resultados, capturas e limitações das evidências.
11. Conclusões: atendimento aos objetivos, limitações e trabalhos futuros.
12. Referências, apêndices e anexos: referências conferidas e materiais extensos selecionados.

## Sequência recomendada

1. Confirmar com o orientador o tipo de documento, modelo, extensão e critérios da banca.
2. Definir a versão do software que será demonstrada e registrar o escopo da entrega.
3. Usar `Documentação do Projeto.docx` como base de conteúdo e a subpasta `document/arquitetura` como referência inicial da arquitetura atual.
4. Consolidar requisitos, casos de uso, dados e regras, resolvendo as divergências deste levantamento.
5. Selecionar evidências existentes e executar apenas as validações adicionais necessárias para sustentar as afirmações finais.
6. Redigir resultados e conclusão, revisar fontes e produzir o Word final segundo o modelo institucional.
7. Preparar a apresentação e a demonstração a partir do documento validado.

O documento final pode aproveitar grande parte do acervo. O trabalho principal é atualizar, selecionar e conectar as informações para que a banca consiga relacionar problema, solução, implementação e resultados.
