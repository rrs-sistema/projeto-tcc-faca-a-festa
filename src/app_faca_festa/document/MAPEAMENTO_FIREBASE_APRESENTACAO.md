# Mapeamento real do Firebase — Faça a Festa

Data da análise: 11/08/2026

## 1. Escopo e conclusão

Este levantamento foi feito cruzando:

- os modelos de `lib/data/models`;
- os acessos ao `FirebaseFirestore` em controllers, telas, repositories e datasources;
- as Cloud Functions em `functions/src`.

O projeto usa Cloud Firestore, portanto o termo mais correto é **coleção/documento/subcoleção**, e não tabela/linha. Para a apresentação acadêmica, cada coleção pode ser comparada a uma tabela, mas as chaves estrangeiras são apenas campos `id_*`: o Firestore não impõe integridade referencial.

Foram encontrados **29 nomes de coleções de nível raiz** usados pelo aplicativo ou pelas Cloud Functions e **17 caminhos de subcoleção**. A coleção fictícia `x`, usada somente para gerar um ID em memória, não foi contabilizada.

## 2. Legenda de chaves

- **PK lógica**: ID do documento Firestore (`document.id`).
- **PK duplicada**: o mesmo ID também é salvo em um campo como `id_evento`.
- **FK lógica**: campo textual que aponta para outro documento; não há restrição automática.
- **ID composto**: string montada pelo aplicativo, por exemplo `${idFornecedor}_${idServico}`.

## 3. Coleções principais e campos

### 3.1 Usuários e localização

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `usuarios/{uid}` | UID do Firebase Auth; também `id_usuario` | — | `nome`, `email`, `tipo`, `cpf`, `foto_perfil_url`, `senha_hash`, `ativo`, `data_cadastro`, `cidade`, `uf` |
| `usuarios/{uid}/enderecos/{id}` | `id` gerado | `id_usuario`, `id_cidade` | `logradouro`, `numero`, `bairro`, `cep`, `complemento`, `nome_cidade`, `uf`, `principal`, `data_cadastro` |
| `estado/{id}` | ID do documento; modelo possui `id_uf` | — | `nome`, `uf` |
| `estado/{id}/cidades/{id}` | ID do documento; modelo possui `id_cidade` | estado pai | `nome`, `uf`, `estado` |

Fontes: `usuario_model.dart`, `endereco_usuario.dart`, `usuario_controller.dart`, `uf_cidade_controller.dart`.

### 3.2 Evento, convidados e planejamento

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `tipo_evento/{id}` | ID do documento / `id_tipo_evento` | — | `nome`, `ativo` |
| `evento/{idEvento}` | `id_evento` | `id_usuario`, `id_tipo_evento`, `id_cidade` | `nome_evento`, `descricao`, `data`, `hora`, `status`, `ativo`, `total_convidados`, `total_adultos`, `total_criancas`, `total_bebes`, endereço e campos específicos do tipo de festa |
| `convidado/{idConvidado}` | `id_convidado` | `id_evento`, `id_grupo`, `id_mesa` | `nome`, `contato`, `email`, `status`, `tipo_convidado`, `nome_grupo`, `numero_mesa`, `ocupa_assento`, `cuidado_especial`, datas de envio/resposta/cadastro/atualização |
| `grupos_convidado/{idGrupo}` | `id_grupo` | `id_evento` | `nome`, `descricao`, `icone`, `cor_hex`, totais de convidados/adultos/crianças/bebês/confirmados, datas |
| `tarefa/{idTarefa}` | `id_tarefa` | `id_evento`, `id_responsavel` → convidado | `titulo`, `descricao`, `data_prevista`, `status`, `data_cadastro` |
| `cardapios/{idCardapio}` | `id_cardapio` | `id_evento` | `titulo`, `publico_alvo`, `icone`, `cor_hex`, `ativo`, totais por tipo |
| `cardapios/{idCardapio}/itens/{idItem}` | `id_item` | `id_cardapio`, `id_evento` | `nome`, `tipo`, `unidade`, `publico_alvo`, `quantidade_sugerida`, `quantidade_final`, `confirmado`, `observacao`, `gerado_pela_calculadora` |

Observação: `MesaEventoModel` existe, mas não foi localizado um CRUD de coleção `mesa_evento`; na implementação atual, mesa aparece principalmente por `id_mesa`, `numero_mesa` e grupos.

### 3.3 Inspirações e referências do evento

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `inspiracoes/{id}` | ID do documento | `tipoEventoId` | `titulo`, `descricao`, `categoria`, `tipoEvento`, `tipoEventoNormalizado`, `imagemUrl`, `galeriaUrls`, `paletaCores`, `tags`, `faixaCusto`, `nivelDificuldade`, `tarefasSugeridas`, `itensOrcamentoSugeridos`, `ativo`, `destaque`, auditoria |
| `evento/{idEvento}/referencias/{id}` | `insp_{usuario}_{inspiracao}` ou automático | evento pai, `userId`, `inspiracaoId` | dados copiados da inspiração, `favorito`, `status`, `prioridade`, `anotacao`, `fornecedoresRelacionados`, `ativo`, `deletado`, datas |
| `evento/{idEvento}/tarefas/{id}` | automático | evento pai, referência/inspiração | mapas de tarefas geradas por inspiração |
| `evento/{idEvento}/orcamento/{id}` | automático | evento pai, referência/inspiração | mapas de itens de orçamento gerados por inspiração |

As duas últimas subcoleções convivem com as coleções raiz `tarefa` e `orcamento`, criando duas fontes para conceitos equivalentes.

### 3.4 Presentes

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `evento/{idEvento}/presentes/{idPresente}` | ID do presente | evento pai | `nome`, `descricao`, `imagem`, `categoria`, `tipo`, `status`, `valor`, `meta_valor`, `valor_arrecadado`, `pix`, `link`, `loja`, reserva e `created_at` |
| `evento/{idEvento}/presentes/{idPresente}/contributions/{id}` | automático | presente pai, `uid` | `nome`, `uid`, `valor`, `mensagem`, `data` |

### 3.5 Fornecedores e catálogo

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `fornecedor/{idFornecedor}` | normalmente UID; também `id_fornecedor` | `id_usuario` | `razao_social`, `cnpj`, `email`, `telefone`, `descricao`, `banner_url`, `ativo`, `apto_para_operar`, faixas de preço, categorias, tipos de evento, métricas de avaliações/contratações/resposta |
| `categoria_servico/{id}` | campo `id` | — | `nome`, `descricao`, `ativo` |
| `subcategoria_servico/{id}` | campo `id` | `id_categoria` | `nome`, `descricao`, `ativo` |
| `servico_produto/{id}` | campo `id` | `id_subcategoria` | `nome`, `tipo_medida`, `descricao`, `ativo` |
| `fornecedor_categoria/{id}` | automático | `id_fornecedor`, `id_categoria` | `nome_categoria`, `subcategorias`, `data_cadastro` |
| `fornecedor_servico/{id}` | geralmente ID composto | `id_fornecedor`, `id_produto_servico`, `id_subcategoria` | `preco`, `preco_promocao`, `ativo`, `media_servico`, `total_avaliacoes_servico`, `data_cadastro` |
| `servico_foto/{id}` | campo `id` | `id_fornecedor`, `id_produto_servico` | `url`, `data_upload` |
| `territorio/{idTerritorio}` | `id_territorio` | `id_fornecedor` | `tipo_cobertura`, `descricao`, `regioes`, `latitude`, `longitude`, `raio_km`, `ativo` |

### 3.6 Avaliações: quatro estruturas concorrentes

| Caminho | Finalidade observada | Campos principais |
|---|---|---|
| `fornecedor/{id}/avaliacoes/{id}` | avaliação do fornecedor | `id`, `id_fornecedor`, `id_cliente`, `nome_cliente`, `nota`, `comentario`, `data`, `id_evento`, `nome_evento` |
| `fornecedor_servico/{idComposto}/avaliacoes/{id}` | avaliação do serviço | acima + `id_servico` |
| `avaliacao_fornecedor/{id}` | controle de avaliação já realizada | consultas por `id_evento`, `id_fornecedor`, `id_usuario` |
| `avaliacoes/{id}` / `fornecedor_avaliacoes/{id}` | fonte geral/compatibilidade da recomendação | IDs de fornecedor/cliente/evento, nomes, `nota`, `comentario`, `data` |

Risco: médias e rankings podem divergir porque o código lê mais de uma origem.

### 3.7 Cotações, orçamento e chat

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `cotacao/{idCotacao}` | ID do documento | `id_evento`, `id_usuario_solicitante` | solicitante, `descricao`, `categoria_nome`, datas, `status`, listas `fornecedores` e `servicos`, `valor_estimado_total` |
| `cotacao/{idCotacao}/fornecedores/{idFornecedor}` | fornecedor como chave | cotação e fornecedor | `id_cotacao`, `id_fornecedor`, `nome_fornecedor`, `prazo_entrega`, `condicao_pagamento`, `status`, observação e data de resposta |
| `.../fornecedores/{idFornecedor}/servicos/{idServico}` | serviço como chave | cotação, fornecedor, produto/serviço | `id_produto_servico`, `nome_produto_servico`, `quantidade`, `valor_unitario`, `valor_total` |
| `.../fornecedores/{idFornecedor}/mensagens/{id}` | automático | usuário/remetente | `id_usuario`, conteúdo da mensagem, data e `lido` |
| `orcamento/{idOrcamento}` | `id_orcamento` | evento, fornecedor, solicitante, categoria, serviço, tipo de pagamento | nomes, `custo_estimado`, `status`, `anotacoes`, datas, `fechado_por` |
| `orcamento/{idOrcamento}/orcamento_gasto/{idGasto}` | `id_gasto` | `id_orcamento`, `id_servico` | `nome`/`nome_servico`, `custo`, `pago`, `data_cadastro` |

### 3.8 Calculadora e IA

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `calculadora_itens_base/{id}` | ID semântico | — | catálogo: nome, categoria, tipo, público, unidade, quantidade por convidado, valor médio, ordem, obrigatório, ativo |
| `calculadora_evento_itens/{id}` | ID semântico | item base e tipo de evento | campos do catálogo + `id_item_base`, `tipo_evento`, `quantidade_estimativa`, `valor_estimado`, seleção e totais |
| `calculadora_festa/{idCalculo}` | `id_calculo` | `id_evento`, `id_usuario` | perfil/base de cálculo, totais de convidados, duração, margem, orçamento, custo estimado, status, conversão e `analise_ia` |
| `calculadora_festa/{idCalculo}/itens/{idItem}` | `id_item_resultado` | cálculo e evento | nome, categoria, quantidade, unidade, custos, regra aplicada, flags de cardápio/orçamento |
| `calculadora_festa/{idCalculo}/analises_ia/{id}` | automático | cálculo/evento/usuário | resposta de IA, índices, diagnósticos, recomendações, sugestões, versões de prompt/schema/modelo e `created_at` |
| `ia_sugestoes_base/{id}` | ID semântico | — | `titulo`, `descricao`, módulo, tema, tipos de evento, perfis, categoria, prioridade, gatilhos, tags, revisão, versão, ordem e auditoria |

### 3.9 Recomendação de fornecedores por Cloud Functions

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `fornecedor_interacoes/{id}` | automático | evento, fornecedor, usuário | `id_evento`, `id_fornecedor`, `id_usuario`, `acao`, `peso`, tipo do evento, cidade, `created_at` |
| `fornecedor_recomendacoes/{id}` | gerado pela função | evento, fornecedor, usuário | `eventoId`, `fornecedorId`, `usuarioId`, `score`, compatibilidade, nível, motivos, distância, dados resumidos do fornecedor, `createdAt`, `updatedAt` |

O cliente ainda consulta versões antigas em `snake_case`, enquanto o modelo atual usa principalmente `camelCase`.

### 3.10 Comunidade

| Caminho | Chave do documento | FKs lógicas | Campos persistidos principais |
|---|---|---|---|
| `posts/{id}` | automático | autor textual | `autor`, `texto`, `imagem`, `data`, `curtidas` |
| `posts/{id}/comentarios/{id}` | automático | post pai | `autor`, `texto`, `data` |

## 4. Modelos que não representam uma coleção ativa própria

- `PagamentoModel` e `TipoPagamentoModel`: há campos de pagamento em orçamento, mas não foi localizado CRUD de coleções `pagamento` ou `tipo_pagamento`.
- `MesaEventoModel`: sem coleção própria localizada.
- modelos `admin` e `DTO`: projeções para tela/consulta, não documentos próprios.
- `EstimativaFinanceiraModel`, requests/responses de planejamento e parte dos modelos `fornecedor_intelligence`: cálculo, transporte ou estado em memória; nem todo `toMap()` implica persistência.
- modelos `gift_local`: persistência local Drift, não Firestore.

## 5. Achados de arquitetura

1. **IDs duplicados** — muitos documentos usam o ID do caminho e repetem `id_*` no corpo. Isso facilita consultas, mas permite divergência.
2. **Sem integridade referencial** — excluir evento/fornecedor não garante exclusão de convidados, tarefas, cotações ou vínculos.
3. **Duas estruturas para o mesmo conceito** — `tarefa` e `evento/{id}/tarefas`; `orcamento` e `evento/{id}/orcamento`; várias origens de avaliação.
4. **Convenções misturadas** — `snake_case` predomina, mas recomendações usam `camelCase`; existem aliases de compatibilidade nos modelos.
5. **Acesso direto na interface** — algumas telas escrevem/lêem Firestore sem repository, aumentando o risco de campos diferentes do modelo.
6. **Regras e índices não versionados aqui** — `firebase.json` configura Functions e Flutter, mas não aponta para arquivos de regras/índices do Firestore. Eles podem existir apenas no console ou em outro repositório.
7. **Coleção `x` não é banco real** — `collection('x').doc().id` é usado só como gerador de ID e não grava documento.

## 6. Recomendações para o novo mapeamento

- Definir um dicionário oficial por coleção: caminho, dono, ID, campos obrigatórios, tipo e enum.
- Padronizar `snake_case` ou `camelCase` e remover aliases após migração.
- Escolher uma única fonte para tarefas, orçamento e avaliações.
- Criar constantes centrais para nomes de coleções e campos.
- Concentrar o Firestore em repositories/datasources; telas devem consumir controllers/use cases.
- Versionar `firestore.rules` e `firestore.indexes.json` junto do aplicativo.
- Documentar políticas de exclusão em cascata e criar Functions para mantê-las.
- Tratar `DocumentReference` ou validação transacional quando uma FK lógica for crítica.

## 7. Roteiro sugerido para 10 minutos

1. 45 s — objetivo e método do levantamento.
2. 60 s — como Firestore substitui tabelas por coleções/documentos.
3. 90 s — núcleo: usuário → evento → convidados/tarefas/cardápio.
4. 90 s — fornecedores → catálogo → território/avaliações.
5. 90 s — cotação → fornecedores → serviços/mensagens → orçamento.
6. 75 s — calculadora, presentes, inspirações e IA.
7. 90 s — chaves lógicas e riscos encontrados.
8. 60 s — proposta de padronização e fechamento.

## 8. Principais arquivos de evidência

- `lib/data/models/**`
- `lib/controllers/evento_controller.dart`
- `lib/controllers/convidado/**`
- `lib/controllers/fornecedor/**`
- `lib/controllers/contacao/**`
- `lib/controllers/orcamento_controller.dart`
- `lib/controllers/orcamento_gasto_controller.dart`
- `lib/controllers/calculadora/**`
- `lib/controllers/inspiracao/**`
- `lib/data/repositories/**`
- `lib/data/datasources/remote/gift_remote_datasource.dart`
- `functions/src/services/**`
- `functions/src/functions/**`
- `firebase.json`
