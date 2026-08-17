# Guia do modelo SQL para o Vycanis

## Entregável

O arquivo `modelo_sql_vycanis.sql` contém o modelo relacional completo do Faça a Festa, reconstruído a partir de:

- `lib/data/models`;
- controllers, repositories e datasources que acessam o Firestore;
- Cloud Functions em `functions/src`;
- o modelo antigo exibido no Vycanis.

O script possui **54 tabelas**, com chaves primárias, chaves estrangeiras e tipos SQL conservadores. Ele foi validado integralmente pelo parser DDL do SQLite, sem criação de dados.

## Compatibilidade com o Vycanis

O Vycanis informa que a Engenharia Reversa cria o DER a partir de SQL DDL. Por isso, o arquivo evita construções dependentes de um único banco:

- não usa `CREATE TYPE`;
- não usa `SERIAL`, `IDENTITY` ou sequências;
- não usa `IF NOT EXISTS`;
- não usa índices parciais, triggers ou procedures;
- usa apenas `CREATE TABLE`, `PRIMARY KEY`, `FOREIGN KEY` e tipos comuns;
- mantém IDs Firebase como `VARCHAR(128)`.

O tipo `JSON` foi mantido para mapas e listas sem estrutura fixa. O próprio modelo antigo já utilizava campos JSON.

## Como importar

1. Faça backup do Projeto Remoto atual no Vycanis.
2. Preferencialmente crie um projeto novo ou uma cópia de teste. A Engenharia Reversa pode criar as tabelas do DDL; não se deve presumir que ela fará merge inteligente com tabelas antigas.
3. Abra o menu de banco de dados no canto inferior esquerdo.
4. Selecione **Engenharia Reversa**.
5. Cole o conteúdo de `modelo_sql_vycanis.sql` no editor.
6. Execute a conversão para o DER.
7. Revise o posicionamento das tabelas e os relacionamentos.
8. Somente depois da revisão, salve/substitua o Projeto Remoto.

## Organização das tabelas

### Identidade, endereço e eventos

- `estado`
- `cidade`
- `usuario`
- `endereco_usuario`
- `tipo_evento`
- `evento`

### Convidados e planejamento

- `grupo_convidado`
- `mesa_evento`
- `convidado`
- `tarefa`
- `cardapio`
- `cardapio_item`

### Fornecedores e catálogo

- `fornecedor`
- `fornecedor_tipo_evento`
- `categoria_servico`
- `subcategoria_servico`
- `servico_produto`
- `fornecedor_categoria`
- `fornecedor_categoria_subcategoria`
- `fornecedor_servico`
- `servico_foto`
- `territorio`
- `territorio_regiao`

### Comercial e financeiro

- `cotacao`
- `cotacao_fornecedor`
- `cotacao_servico`
- `cotacao_mensagem`
- `orcamento`
- `orcamento_gasto`
- `tipo_pagamento`
- `pagamento`
- `avaliacao_fornecedor`
- `avaliacao_servico`

### Inspirações e presentes

- `inspiracao`
- `evento_referencia`
- `presente`
- `presente_contribuicao`

### Calculadora e IA

- `calculadora_item_base`
- `calculadora_evento_item`
- `calculadora_festa`
- `calculadora_festa_item`
- `calculadora_analise_ia`
- `ia_sugestao_base`

### Inteligência de fornecedores

- `fornecedor_interacao`
- `fornecedor_recomendacao`
- `fornecedor_score_cotacao`
- `fornecedor_proxima_acao`
- `fornecedor_insight`
- `fornecedor_sugestao_resposta`
- `fornecedor_sugestao_catalogo`
- `fornecedor_resumo_reputacao`
- `fornecedor_sugestao_pacote`

### Comunidade

- `post_comunidade`
- `comentario_comunidade`

## Decisões de normalização

### Subcoleções do Firestore viraram tabelas

Exemplos:

- `usuarios/{uid}/enderecos` → `endereco_usuario`;
- `cardapios/{id}/itens` → `cardapio_item`;
- `evento/{id}/presentes` → `presente`;
- `presentes/{id}/contributions` → `presente_contribuicao`;
- `cotacao/{id}/fornecedores` → `cotacao_fornecedor`;
- `cotacao/.../servicos` → `cotacao_servico`;
- `cotacao/.../mensagens` → `cotacao_mensagem`;
- `calculadora_festa/{id}/itens` → `calculadora_festa_item`;
- `calculadora_festa/{id}/analises_ia` → `calculadora_analise_ia`.

### Listas de relacionamento viraram tabelas associativas

- tipos de evento atendidos pelo fornecedor → `fornecedor_tipo_evento`;
- subcategorias do vínculo fornecedor/categoria → `fornecedor_categoria_subcategoria`;
- regiões do território → `territorio_regiao`.

### Duplicidades do Firestore foram consolidadas

- avaliações gerais e subcoleções foram representadas por `avaliacao_fornecedor` e `avaliacao_servico`;
- tarefas da raiz e tarefas geradas por inspiração usam `tarefa.origem` e `tarefa.id_inspiracao`;
- orçamentos da raiz e itens gerados por inspiração usam `orcamento.origem` e `orcamento.id_inspiracao`.

### Campos dinâmicos permaneceram JSON

Listas, metadados, respostas de IA, paletas, galerias, gatilhos e sugestões permaneceram `JSON`. Transformá-los em dezenas de tabelas adicionais deixaria o DER maior sem acrescentar relações estáveis.

## Tabelas que representam evolução do domínio

As tabelas abaixo existem no modelo lógico completo, embora o aplicativo atual não tenha um CRUD Firestore independente para todas elas:

- `mesa_evento`;
- `tipo_pagamento`;
- `pagamento`;
- tabelas `fornecedor_*` de insights e sugestões inteligentes.

Elas foram incluídas porque existem como modelos ou resultados de domínio no código atual. No Firestore, parte dessas informações ainda é calculada em memória, gravada dentro de outro documento ou produzida por Cloud Functions.

## Pontos para revisão antes de substituir o projeto remoto

- confirmar se `usuario.tipo` continuará como código de um caractere ou passará a texto completo;
- decidir se `senha_hash` deve permanecer no modelo, pois a autenticação já usa Firebase Auth;
- decidir se mesas terão persistência própria ou continuarão derivadas de grupos/convidados;
- escolher definitivamente uma origem para avaliações;
- definir se os resultados de inteligência serão persistidos ou continuarão temporários;
- revisar as cardinalidades no diagrama depois da Engenharia Reversa;
- salvar primeiro em um projeto de teste, pois um import de DDL não deve ser tratado como migração automática dos dados do Firestore.
