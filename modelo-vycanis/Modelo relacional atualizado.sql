-- FACA A FESTA
-- Modelo relacional atualizado a partir do Firestore, modelos Dart e Cloud Functions.
-- DDL conservador para Engenharia Reversa do Vycanis Modeler.
-- Gerado em 11/08/2026.

CREATE TABLE estado (
    id_estado VARCHAR(128) NOT NULL,
    uf CHAR(2) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_estado)
);

CREATE TABLE cidade (
    id_cidade VARCHAR(128) NOT NULL,
    id_estado VARCHAR(128) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    uf CHAR(2) NOT NULL,
    PRIMARY KEY (id_cidade),
    FOREIGN KEY (id_estado) REFERENCES estado (id_estado)
);

CREATE TABLE usuario (
    id_usuario VARCHAR(128) NOT NULL,
    nome VARCHAR(180) NOT NULL,
    email VARCHAR(255) NOT NULL,
    tipo CHAR(1),
    cpf VARCHAR(20),
    foto_perfil_url TEXT,
    senha_hash TEXT,
    ativo BOOLEAN NOT NULL,
    data_cadastro TIMESTAMP,
    cidade VARCHAR(150),
    uf CHAR(2),
    PRIMARY KEY (id_usuario)
);

CREATE TABLE endereco_usuario (
    id_endereco VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128) NOT NULL,
    id_cidade VARCHAR(128),
    cep VARCHAR(12),
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(30),
    complemento VARCHAR(150),
    bairro VARCHAR(150),
    nome_cidade VARCHAR(150),
    uf CHAR(2),
    principal BOOLEAN NOT NULL,
    data_cadastro TIMESTAMP,
    PRIMARY KEY (id_endereco),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade)
);

CREATE TABLE tipo_evento (
    id_tipo_evento VARCHAR(128) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_tipo_evento)
);

CREATE TABLE evento (
    id_evento VARCHAR(128) NOT NULL,
    id_tipo_evento VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128) NOT NULL,
    id_cidade VARCHAR(128),
    nome_evento VARCHAR(200) NOT NULL,
    descricao TEXT,
    data_evento DATE,
    hora_evento TIME,
    status VARCHAR(40),
    ativo BOOLEAN NOT NULL,
    custo_estimado DECIMAL(15,2),
    total_convidados INTEGER,
    total_adultos INTEGER,
    total_criancas INTEGER,
    total_bebes INTEGER,
    local_evento VARCHAR(255),
    cep VARCHAR(12),
    logradouro VARCHAR(255),
    numero VARCHAR(30),
    complemento VARCHAR(150),
    bairro VARCHAR(150),
    nome_cidade VARCHAR(150),
    uf CHAR(2),
    data_cadastro TIMESTAMP,
    tema VARCHAR(180),
    nome_aniversariante VARCHAR(180),
    idade INTEGER,
    nome_noiva VARCHAR(180),
    nome_noivo VARCHAR(180),
    estilo_casamento VARCHAR(120),
    tipo_cerimonia VARCHAR(120),
    padrinhos INTEGER,
    dress_code VARCHAR(150),
    site_evento TEXT,
    hashtag_evento VARCHAR(120),
    tipo_cha VARCHAR(120),
    nome_gestante VARCHAR(180),
    nome_bebe VARCHAR(180),
    data_prevista_nascimento DATE,
    nome_responsavel VARCHAR(180),
    nome_pessoa_principal VARCHAR(180),
    PRIMARY KEY (id_evento),
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_cidade) REFERENCES cidade (id_cidade)
);

CREATE TABLE grupo_convidado (
    id_grupo VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    nome VARCHAR(180) NOT NULL,
    descricao TEXT,
    icone VARCHAR(80),
    cor_hex VARCHAR(10),
    total_convidados INTEGER NOT NULL,
    total_adultos INTEGER NOT NULL,
    total_criancas INTEGER NOT NULL,
    total_bebes INTEGER NOT NULL,
    total_confirmados INTEGER NOT NULL,
    data_cadastro TIMESTAMP NOT NULL,
    data_atualizacao TIMESTAMP NOT NULL,
    PRIMARY KEY (id_grupo),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE mesa_evento (
    id_mesa VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_grupo VARCHAR(128),
    numero_mesa INTEGER,
    nome_mesa VARCHAR(150),
    nome_grupo VARCHAR(150),
    capacidade_assentos INTEGER NOT NULL,
    total_ocupados INTEGER NOT NULL,
    total_livres INTEGER NOT NULL,
    cor_hex VARCHAR(10),
    ativa BOOLEAN NOT NULL,
    PRIMARY KEY (id_mesa),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_grupo) REFERENCES grupo_convidado (id_grupo)
);

CREATE TABLE convidado (
    id_convidado VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_grupo VARCHAR(128),
    id_mesa VARCHAR(128),
    nome VARCHAR(180) NOT NULL,
    contato VARCHAR(100),
    email VARCHAR(255),
    status VARCHAR(30) NOT NULL,
    tipo_convidado VARCHAR(30) NOT NULL,
    nome_grupo VARCHAR(180),
    numero_mesa INTEGER,
    ocupa_assento BOOLEAN NOT NULL,
    cuidado_especial BOOLEAN NOT NULL,
    data_envio TIMESTAMP,
    data_resposta TIMESTAMP,
    data_cadastro TIMESTAMP NOT NULL,
    data_atualizacao TIMESTAMP NOT NULL,
    PRIMARY KEY (id_convidado),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_grupo) REFERENCES grupo_convidado (id_grupo),
    FOREIGN KEY (id_mesa) REFERENCES mesa_evento (id_mesa)
);

CREATE TABLE tarefa (
    id_tarefa VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_responsavel VARCHAR(128),
    id_inspiracao VARCHAR(128),
    titulo VARCHAR(220) NOT NULL,
    descricao TEXT,
    data_prevista TIMESTAMP,
    status VARCHAR(30) NOT NULL,
    origem VARCHAR(40),
    data_cadastro TIMESTAMP NOT NULL,
    PRIMARY KEY (id_tarefa),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_responsavel) REFERENCES convidado (id_convidado)
);

CREATE TABLE cardapio (
    id_cardapio VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    publico_alvo VARCHAR(40) NOT NULL,
    icone VARCHAR(80),
    cor_hex VARCHAR(10),
    ativo BOOLEAN NOT NULL,
    total_itens INTEGER NOT NULL,
    total_comidas INTEGER NOT NULL,
    total_bebidas INTEGER NOT NULL,
    total_sobremesas INTEGER NOT NULL,
    PRIMARY KEY (id_cardapio),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE cardapio_item (
    id_item VARCHAR(128) NOT NULL,
    id_cardapio VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    nome VARCHAR(180) NOT NULL,
    tipo VARCHAR(40) NOT NULL,
    unidade VARCHAR(40),
    publico_alvo VARCHAR(40),
    quantidade_sugerida DECIMAL(15,3),
    quantidade_final DECIMAL(15,3),
    confirmado BOOLEAN NOT NULL,
    observacao TEXT,
    gerado_pela_calculadora BOOLEAN NOT NULL,
    PRIMARY KEY (id_item),
    FOREIGN KEY (id_cardapio) REFERENCES cardapio (id_cardapio),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE categoria_servico (
    id_categoria VARCHAR(128) NOT NULL,
    nome VARCHAR(180) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_categoria)
);

CREATE TABLE subcategoria_servico (
    id_subcategoria VARCHAR(128) NOT NULL,
    id_categoria VARCHAR(128) NOT NULL,
    nome VARCHAR(180) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_subcategoria),
    FOREIGN KEY (id_categoria) REFERENCES categoria_servico (id_categoria)
);

CREATE TABLE servico_produto (
    id_servico VARCHAR(128) NOT NULL,
    id_subcategoria VARCHAR(128),
    nome VARCHAR(200) NOT NULL,
    tipo_medida VARCHAR(40),
    descricao TEXT,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_servico),
    FOREIGN KEY (id_subcategoria) REFERENCES subcategoria_servico (id_subcategoria)
);

CREATE TABLE fornecedor (
    id_fornecedor VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128) NOT NULL,
    razao_social VARCHAR(220) NOT NULL,
    cnpj VARCHAR(30),
    email VARCHAR(255),
    telefone VARCHAR(40),
    descricao TEXT,
    banner_url TEXT,
    fcm_token TEXT,
    ativo BOOLEAN NOT NULL,
    apto_para_operar BOOLEAN NOT NULL,
    is_top_categoria BOOLEAN NOT NULL,
    preco_minimo DECIMAL(15,2),
    preco_maximo DECIMAL(15,2),
    preco_medio DECIMAL(15,2),
    media_avaliacoes DECIMAL(5,2),
    total_avaliacoes INTEGER NOT NULL,
    total_contratacoes INTEGER NOT NULL,
    tempo_medio_resposta_horas DECIMAL(10,2),
    data_cadastro TIMESTAMP,
    PRIMARY KEY (id_fornecedor),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE fornecedor_tipo_evento (
    id_fornecedor VARCHAR(128) NOT NULL,
    id_tipo_evento VARCHAR(128) NOT NULL,
    nome_tipo_evento VARCHAR(150),
    slug_tipo_evento VARCHAR(150),
    PRIMARY KEY (id_fornecedor, id_tipo_evento),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento)
);

CREATE TABLE fornecedor_categoria (
    id_fornecedor_categoria VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_categoria VARCHAR(128) NOT NULL,
    nome_categoria VARCHAR(180),
    data_cadastro TIMESTAMP,
    PRIMARY KEY (id_fornecedor_categoria),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_categoria) REFERENCES categoria_servico (id_categoria)
);

CREATE TABLE fornecedor_categoria_subcategoria (
    id_fornecedor_categoria VARCHAR(128) NOT NULL,
    id_subcategoria VARCHAR(128) NOT NULL,
    PRIMARY KEY (id_fornecedor_categoria, id_subcategoria),
    FOREIGN KEY (id_fornecedor_categoria) REFERENCES fornecedor_categoria (id_fornecedor_categoria),
    FOREIGN KEY (id_subcategoria) REFERENCES subcategoria_servico (id_subcategoria)
);

CREATE TABLE fornecedor_servico (
    id_fornecedor_servico VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128) NOT NULL,
    id_subcategoria VARCHAR(128),
    preco DECIMAL(15,2) NOT NULL,
    preco_promocao DECIMAL(15,2),
    ativo BOOLEAN NOT NULL,
    media_servico DECIMAL(5,2),
    total_avaliacoes_servico INTEGER NOT NULL,
    data_cadastro TIMESTAMP,
    PRIMARY KEY (id_fornecedor_servico),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico),
    FOREIGN KEY (id_subcategoria) REFERENCES subcategoria_servico (id_subcategoria)
);

CREATE TABLE servico_foto (
    id_foto VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128) NOT NULL,
    url TEXT NOT NULL,
    data_upload TIMESTAMP,
    PRIMARY KEY (id_foto),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico)
);

CREATE TABLE territorio (
    id_territorio VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    tipo_cobertura VARCHAR(40),
    descricao TEXT,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    raio_km DECIMAL(10,2),
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_territorio),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor)
);

CREATE TABLE territorio_regiao (
    id_territorio VARCHAR(128) NOT NULL,
    regiao VARCHAR(180) NOT NULL,
    PRIMARY KEY (id_territorio, regiao),
    FOREIGN KEY (id_territorio) REFERENCES territorio (id_territorio)
);

CREATE TABLE tipo_pagamento (
    id_tipo_pagamento VARCHAR(128) NOT NULL,
    nome VARCHAR(120) NOT NULL,
    PRIMARY KEY (id_tipo_pagamento)
);

CREATE TABLE orcamento (
    id_orcamento VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128),
    id_solicitante VARCHAR(128),
    id_categoria VARCHAR(128),
    id_fornecedor_servico VARCHAR(128),
    id_tipo_pagamento VARCHAR(128),
    nome_fornecedor VARCHAR(220),
    nome_solicitante VARCHAR(180),
    custo_estimado DECIMAL(15,2),
    status VARCHAR(40) NOT NULL,
    anotacoes TEXT,
    fechado_por VARCHAR(128),
    data_cadastro TIMESTAMP,
    data_fechamento TIMESTAMP,
    origem VARCHAR(40),
    id_inspiracao VARCHAR(128),
    PRIMARY KEY (id_orcamento),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_solicitante) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_categoria) REFERENCES categoria_servico (id_categoria),
    FOREIGN KEY (id_fornecedor_servico) REFERENCES fornecedor_servico (id_fornecedor_servico),
    FOREIGN KEY (id_tipo_pagamento) REFERENCES tipo_pagamento (id_tipo_pagamento),
    FOREIGN KEY (fechado_por) REFERENCES usuario (id_usuario)
);

CREATE TABLE orcamento_gasto (
    id_gasto VARCHAR(128) NOT NULL,
    id_orcamento VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128),
    nome VARCHAR(220),
    nome_servico VARCHAR(220),
    custo DECIMAL(15,2) NOT NULL,
    pago BOOLEAN NOT NULL,
    data_cadastro TIMESTAMP,
    PRIMARY KEY (id_gasto),
    FOREIGN KEY (id_orcamento) REFERENCES orcamento (id_orcamento),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico)
);

CREATE TABLE pagamento (
    id_pagamento VARCHAR(128) NOT NULL,
    id_orcamento VARCHAR(128) NOT NULL,
    id_tipo_pagamento VARCHAR(128),
    data_pagamento TIMESTAMP,
    valor_pago DECIMAL(15,2) NOT NULL,
    total DECIMAL(15,2),
    status_pagamento VARCHAR(40),
    observacoes TEXT,
    PRIMARY KEY (id_pagamento),
    FOREIGN KEY (id_orcamento) REFERENCES orcamento (id_orcamento),
    FOREIGN KEY (id_tipo_pagamento) REFERENCES tipo_pagamento (id_tipo_pagamento)
);

CREATE TABLE cotacao (
    id_cotacao VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_usuario_solicitante VARCHAR(128) NOT NULL,
    nome_usuario_solicitante VARCHAR(180),
    descricao TEXT,
    categoria_nome VARCHAR(180),
    data_limite_resposta TIMESTAMP,
    data_cadastro TIMESTAMP NOT NULL,
    data_envio TIMESTAMP,
    status VARCHAR(40) NOT NULL,
    valor_estimado_total DECIMAL(15,2),
    PRIMARY KEY (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_usuario_solicitante) REFERENCES usuario (id_usuario)
);

CREATE TABLE cotacao_fornecedor (
    id_cotacao_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    nome_fornecedor VARCHAR(220),
    prazo_entrega TIMESTAMP,
    condicao_pagamento VARCHAR(180),
    status VARCHAR(40) NOT NULL,
    observacao_fornecedor TEXT,
    data_resposta TIMESTAMP,
    PRIMARY KEY (id_cotacao_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor)
);

CREATE TABLE cotacao_servico (
    id_cotacao_servico VARCHAR(128) NOT NULL,
    id_cotacao_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128) NOT NULL,
    nome_servico VARCHAR(220),
    quantidade DECIMAL(15,3) NOT NULL,
    valor_unitario DECIMAL(15,2),
    valor_total DECIMAL(15,2),
    PRIMARY KEY (id_cotacao_servico),
    FOREIGN KEY (id_cotacao_fornecedor) REFERENCES cotacao_fornecedor (id_cotacao_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico)
);

CREATE TABLE cotacao_mensagem (
    id_mensagem VARCHAR(128) NOT NULL,
    id_cotacao_fornecedor VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128) NOT NULL,
    mensagem TEXT NOT NULL,
    data_mensagem TIMESTAMP NOT NULL,
    lido BOOLEAN NOT NULL,
    PRIMARY KEY (id_mensagem),
    FOREIGN KEY (id_cotacao_fornecedor) REFERENCES cotacao_fornecedor (id_cotacao_fornecedor),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE avaliacao_fornecedor (
    id_avaliacao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_cliente VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    nome_cliente VARCHAR(180),
    nome_fornecedor VARCHAR(220),
    nome_evento VARCHAR(220),
    nota DECIMAL(3,2) NOT NULL,
    comentario TEXT,
    data_avaliacao TIMESTAMP NOT NULL,
    origem VARCHAR(60),
    PRIMARY KEY (id_avaliacao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_cliente) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE avaliacao_servico (
    id_avaliacao VARCHAR(128) NOT NULL,
    id_fornecedor_servico VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128) NOT NULL,
    id_cliente VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    nome_cliente VARCHAR(180),
    nome_evento VARCHAR(220),
    nota DECIMAL(3,2) NOT NULL,
    comentario TEXT,
    data_avaliacao TIMESTAMP NOT NULL,
    PRIMARY KEY (id_avaliacao),
    FOREIGN KEY (id_fornecedor_servico) REFERENCES fornecedor_servico (id_fornecedor_servico),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico),
    FOREIGN KEY (id_cliente) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE presente (
    id_presente VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    nome VARCHAR(220) NOT NULL,
    descricao TEXT,
    imagem TEXT,
    categoria VARCHAR(120),
    tipo VARCHAR(40),
    status VARCHAR(40),
    valor DECIMAL(15,2),
    meta_valor DECIMAL(15,2),
    valor_arrecadado DECIMAL(15,2),
    pix VARCHAR(255),
    link TEXT,
    loja VARCHAR(180),
    reservado_por VARCHAR(180),
    reservado_uid VARCHAR(128),
    data_reserva TIMESTAMP,
    created_at TIMESTAMP,
    PRIMARY KEY (id_presente),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (reservado_uid) REFERENCES usuario (id_usuario)
);

CREATE TABLE presente_contribuicao (
    id_contribuicao VARCHAR(128) NOT NULL,
    id_presente VARCHAR(128) NOT NULL,
    uid VARCHAR(128),
    nome VARCHAR(180),
    valor DECIMAL(15,2) NOT NULL,
    mensagem TEXT,
    data_contribuicao TIMESTAMP NOT NULL,
    PRIMARY KEY (id_contribuicao),
    FOREIGN KEY (id_presente) REFERENCES presente (id_presente),
    FOREIGN KEY (uid) REFERENCES usuario (id_usuario)
);

CREATE TABLE inspiracao (
    id_inspiracao VARCHAR(128) NOT NULL,
    id_tipo_evento VARCHAR(128),
    titulo VARCHAR(220) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(150),
    tipo_evento VARCHAR(150),
    tipo_evento_normalizado VARCHAR(150),
    imagem_url TEXT,
    galeria_urls JSON,
    paleta_cores JSON,
    tags JSON,
    estilo VARCHAR(150),
    faixa_custo VARCHAR(80),
    nivel_dificuldade VARCHAR(80),
    tarefas_sugeridas JSON,
    itens_orcamento_sugeridos JSON,
    categorias_fornecedor_sugeridas JSON,
    destaque BOOLEAN NOT NULL,
    ativo BOOLEAN NOT NULL,
    deletado BOOLEAN NOT NULL,
    status VARCHAR(40),
    origem VARCHAR(60),
    criado_em TIMESTAMP,
    atualizado_em TIMESTAMP,
    PRIMARY KEY (id_inspiracao),
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento)
);

CREATE TABLE evento_referencia (
    id_referencia VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_inspiracao VARCHAR(128),
    id_usuario VARCHAR(128) NOT NULL,
    titulo VARCHAR(220),
    descricao TEXT,
    categoria VARCHAR(150),
    imagem_url TEXT,
    media JSON,
    favorito BOOLEAN NOT NULL,
    salva BOOLEAN NOT NULL,
    status VARCHAR(40),
    prioridade VARCHAR(40),
    anotacao TEXT,
    fornecedores_relacionados JSON,
    ativo BOOLEAN NOT NULL,
    deletado BOOLEAN NOT NULL,
    criado_em TIMESTAMP,
    atualizado_em TIMESTAMP,
    PRIMARY KEY (id_referencia),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_inspiracao) REFERENCES inspiracao (id_inspiracao),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE calculadora_item_base (
    id_item_base VARCHAR(128) NOT NULL,
    nome VARCHAR(220) NOT NULL,
    categoria VARCHAR(150) NOT NULL,
    tipo_item VARCHAR(80),
    publico_alvo VARCHAR(80),
    unidade VARCHAR(40) NOT NULL,
    quantidade_por_convidado_equivalente DECIMAL(15,5) NOT NULL,
    valor_unitario_medio DECIMAL(15,2) NOT NULL,
    obrigatorio BOOLEAN NOT NULL,
    observacao TEXT,
    ordem INTEGER NOT NULL,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_item_base)
);

CREATE TABLE calculadora_evento_item (
    id_evento_item VARCHAR(128) NOT NULL,
    id_item_base VARCHAR(128),
    id_tipo_evento VARCHAR(128),
    tipo_evento VARCHAR(150),
    nome VARCHAR(220) NOT NULL,
    categoria VARCHAR(150),
    publico_alvo VARCHAR(80),
    unidade VARCHAR(40),
    quantidade_por_convidado_equivalente DECIMAL(15,5),
    quantidade_estimativa DECIMAL(15,3),
    total_convidados_equivalente DECIMAL(15,3),
    valor_unitario_medio DECIMAL(15,2),
    valor_estimado DECIMAL(15,2),
    obrigatorio BOOLEAN NOT NULL,
    selecionado BOOLEAN NOT NULL,
    observacao TEXT,
    ordem INTEGER NOT NULL,
    ativo BOOLEAN NOT NULL,
    PRIMARY KEY (id_evento_item),
    FOREIGN KEY (id_item_base) REFERENCES calculadora_item_base (id_item_base),
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento)
);

CREATE TABLE calculadora_festa (
    id_calculo VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    id_usuario VARCHAR(128) NOT NULL,
    nome_evento VARCHAR(220),
    tipo_evento VARCHAR(150),
    perfil_festa JSON,
    base_calculo VARCHAR(80),
    base_calculo_label VARCHAR(120),
    total_convidados INTEGER,
    total_adultos INTEGER,
    total_criancas INTEGER,
    total_bebes INTEGER,
    convidados_equivalentes JSON,
    total_equivalente DECIMAL(15,3),
    total_equivalente_arredondado INTEGER,
    duracao_horas INTEGER,
    margem_personalizada DECIMAL(8,4),
    orcamento_disponivel DECIMAL(15,2),
    custo_total_estimado DECIMAL(15,2),
    status_simulacao VARCHAR(50),
    status_simulacao_label VARCHAR(120),
    convertido_em_orcamento BOOLEAN NOT NULL,
    data_calculo TIMESTAMP,
    data_atualizacao TIMESTAMP,
    data_conversao_orcamento TIMESTAMP,
    analise_ia JSON,
    data_analise_ia TIMESTAMP,
    fonte_analise_ia VARCHAR(120),
    analise_ia_generativa JSON,
    data_ultima_analise_ia TIMESTAMP,
    fonte_ultima_analise_ia VARCHAR(120),
    versao_schema_ia VARCHAR(60),
    PRIMARY KEY (id_calculo),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE calculadora_festa_item (
    id_item_resultado VARCHAR(128) NOT NULL,
    id_calculo VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    nome VARCHAR(220) NOT NULL,
    categoria VARCHAR(150),
    tipo_item VARCHAR(80),
    publico_alvo VARCHAR(80),
    quantidade DECIMAL(15,3),
    unidade VARCHAR(40),
    quantidade_por_convidado_equivalente DECIMAL(15,5),
    valor_unitario_medio DECIMAL(15,2),
    custo_estimado DECIMAL(15,2),
    regra_aplicada TEXT,
    adicionado_ao_cardapio BOOLEAN NOT NULL,
    adicionado_ao_orcamento BOOLEAN NOT NULL,
    id_orcamento_gerado VARCHAR(128),
    data_adicionado_ao_orcamento TIMESTAMP,
    PRIMARY KEY (id_item_resultado),
    FOREIGN KEY (id_calculo) REFERENCES calculadora_festa (id_calculo),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_orcamento_gerado) REFERENCES orcamento (id_orcamento)
);

CREATE TABLE calculadora_analise_ia (
    id_analise VARCHAR(128) NOT NULL,
    id_calculo VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    id_usuario VARCHAR(128),
    titulo VARCHAR(220),
    resumo TEXT,
    indice_economia DECIMAL(8,4),
    indice_risco_faltar_itens DECIMAL(8,4),
    indice_conforto DECIMAL(8,4),
    custo_total_estimado DECIMAL(15,2),
    orcamento_disponivel DECIMAL(15,2),
    diferenca_orcamento DECIMAL(15,2),
    diagnostico_financeiro TEXT,
    diagnostico_consumo TEXT,
    recomendacao_final TEXT,
    pontos_de_atencao JSON,
    proximas_acoes JSON,
    sugestoes JSON,
    fonte VARCHAR(120),
    versao_schema VARCHAR(60),
    versao_prompt VARCHAR(60),
    nome_prompt VARCHAR(180),
    modelo_ia_utilizado VARCHAR(120),
    ids_sugestoes_base_utilizadas JSON,
    versoes_sugestoes_base_utilizadas JSON,
    total_sugestoes_base_utilizadas INTEGER,
    data_analise TIMESTAMP,
    data_processamento TIMESTAMP,
    created_at TIMESTAMP,
    PRIMARY KEY (id_analise),
    FOREIGN KEY (id_calculo) REFERENCES calculadora_festa (id_calculo),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE ia_sugestao_base (
    id_sugestao VARCHAR(128) NOT NULL,
    titulo VARCHAR(220) NOT NULL,
    descricao TEXT NOT NULL,
    modulo VARCHAR(80) NOT NULL,
    tema VARCHAR(100),
    tipos_evento JSON,
    perfis_festa JSON,
    categoria VARCHAR(120),
    prioridade VARCHAR(40),
    gatilhos JSON,
    tags JSON,
    ativo BOOLEAN NOT NULL,
    ordem INTEGER NOT NULL,
    origem VARCHAR(80),
    status_revisao VARCHAR(40),
    revisado_por VARCHAR(128),
    observacao_revisao TEXT,
    data_revisao TIMESTAMP,
    data_publicacao TIMESTAMP,
    versao INTEGER,
    excluido BOOLEAN NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (id_sugestao),
    FOREIGN KEY (revisado_por) REFERENCES usuario (id_usuario)
);

CREATE TABLE fornecedor_interacao (
    id_interacao VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128),
    acao VARCHAR(100) NOT NULL,
    peso DECIMAL(8,4),
    id_tipo_evento VARCHAR(128),
    tipo_evento_nome VARCHAR(150),
    cidade VARCHAR(150),
    created_at TIMESTAMP NOT NULL,
    PRIMARY KEY (id_interacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario),
    FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento)
);

CREATE TABLE fornecedor_recomendacao (
    id_recomendacao VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128) NOT NULL,
    score DECIMAL(8,4) NOT NULL,
    compatibilidade_percentual DECIMAL(8,4),
    nivel VARCHAR(60),
    nivel_label VARCHAR(100),
    motivo_principal TEXT,
    motivos JSON,
    distancia_km DECIMAL(10,2),
    nome_fornecedor VARCHAR(220),
    banner_url TEXT,
    categoria_principal VARCHAR(180),
    media_avaliacoes DECIMAL(5,2),
    total_avaliacoes INTEGER,
    tipo_evento_compativel BOOLEAN,
    tipo_evento_incompativel BOOLEAN,
    tipo_evento_informado VARCHAR(150),
    tipo_evento_ids JSON,
    tipo_evento_nomes JSON,
    tipo_evento_slugs JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    PRIMARY KEY (id_recomendacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE fornecedor_score_cotacao (
    id_score VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    id_fornecedor VARCHAR(128) NOT NULL,
    score DECIMAL(8,4) NOT NULL,
    nivel VARCHAR(60),
    compatibilidade_tipo_evento DECIMAL(8,4),
    compatibilidade_categoria DECIMAL(8,4),
    compatibilidade_orcamento DECIMAL(8,4),
    compatibilidade_localizacao DECIMAL(8,4),
    score_reputacao DECIMAL(8,4),
    score_interacao DECIMAL(8,4),
    score_urgencia DECIMAL(8,4),
    motivos_positivos JSON,
    penalidades JSON,
    alertas JSON,
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    calculado_em TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_score),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor)
);

CREATE TABLE fornecedor_proxima_acao (
    id_acao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128),
    id_evento VARCHAR(128),
    titulo VARCHAR(220),
    descricao TEXT,
    tipo_acao VARCHAR(80),
    acao_principal TEXT,
    acoes_secundarias JSON,
    motivos JSON,
    prioridade INTEGER,
    score DECIMAL(8,4),
    urgente BOOLEAN,
    status VARCHAR(40),
    status_cotacao VARCHAR(40),
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_acao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE fornecedor_insight (
    id_insight VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128),
    id_evento VARCHAR(128),
    tipo VARCHAR(80),
    titulo VARCHAR(220),
    descricao TEXT,
    prioridade INTEGER,
    score DECIMAL(8,4),
    nivel VARCHAR(60),
    motivos JSON,
    acoes_sugeridas JSON,
    status VARCHAR(40),
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_insight),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE fornecedor_sugestao_resposta (
    id_sugestao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128) NOT NULL,
    id_evento VARCHAR(128),
    titulo VARCHAR(220),
    mensagem TEXT,
    tom VARCHAR(60),
    template_key VARCHAR(120),
    campos_usados JSON,
    campos_ausentes JSON,
    precisa_revisao BOOLEAN,
    status VARCHAR(40),
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_sugestao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE fornecedor_sugestao_catalogo (
    id_sugestao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_servico VARCHAR(128),
    titulo VARCHAR(220),
    descricao TEXT,
    score_catalogo DECIMAL(8,4),
    nivel_catalogo VARCHAR(60),
    total_servicos_ativos INTEGER,
    total_servicos_sem_imagem INTEGER,
    total_servicos_sem_preco INTEGER,
    total_servicos_sem_descricao INTEGER,
    pendencias JSON,
    melhorias_prioritarias JSON,
    campos_ausentes JSON,
    categorias_sem_servico JSON,
    servicos_com_alerta JSON,
    alertas JSON,
    status VARCHAR(40),
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_sugestao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_servico) REFERENCES servico_produto (id_servico)
);

CREATE TABLE fornecedor_resumo_reputacao (
    id_resumo VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    resumo TEXT,
    media_geral DECIMAL(5,2),
    media_ultimos_90_dias DECIMAL(5,2),
    total_avaliacoes INTEGER,
    total_comentarios_analisados INTEGER,
    percentual_positivas DECIMAL(8,4),
    percentual_neutras DECIMAL(8,4),
    percentual_negativas DECIMAL(8,4),
    tendencia VARCHAR(60),
    pontos_fortes JSON,
    pontos_atencao JSON,
    servico_melhor_avaliado JSON,
    servico_com_alerta JSON,
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_resumo),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor)
);

CREATE TABLE fornecedor_sugestao_pacote (
    id_sugestao VARCHAR(128) NOT NULL,
    id_fornecedor VARCHAR(128) NOT NULL,
    id_cotacao VARCHAR(128),
    id_evento VARCHAR(128),
    nome_pacote VARCHAR(220),
    descricao TEXT,
    tipo_pacote VARCHAR(80),
    itens_sugeridos JSON,
    total_convidados_equivalentes DECIMAL(15,3),
    valor_estimado DECIMAL(15,2),
    valor_minimo DECIMAL(15,2),
    valor_maximo DECIMAL(15,2),
    motivos JSON,
    alertas JSON,
    status VARCHAR(40),
    origem VARCHAR(80),
    versao_regra VARCHAR(60),
    metadados JSON,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    expires_at TIMESTAMP,
    PRIMARY KEY (id_sugestao),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor (id_fornecedor),
    FOREIGN KEY (id_cotacao) REFERENCES cotacao (id_cotacao),
    FOREIGN KEY (id_evento) REFERENCES evento (id_evento)
);

CREATE TABLE post_comunidade (
    id_post VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128),
    autor VARCHAR(180) NOT NULL,
    texto TEXT NOT NULL,
    imagem TEXT,
    data_postagem TIMESTAMP NOT NULL,
    curtidas INTEGER NOT NULL,
    PRIMARY KEY (id_post),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);

CREATE TABLE comentario_comunidade (
    id_comentario VARCHAR(128) NOT NULL,
    id_post VARCHAR(128) NOT NULL,
    id_usuario VARCHAR(128),
    autor VARCHAR(180) NOT NULL,
    texto TEXT NOT NULL,
    data_comentario TIMESTAMP NOT NULL,
    PRIMARY KEY (id_comentario),
    FOREIGN KEY (id_post) REFERENCES post_comunidade (id_post),
    FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);
