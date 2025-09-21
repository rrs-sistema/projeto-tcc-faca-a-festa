-- =========================================================
-- Configuração padrão (opcional)
-- =========================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- Tabela: estado
-- =========================================================
CREATE TABLE IF NOT EXISTS estado (
    uf CHAR(2) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: cidade
-- =========================================================
CREATE TABLE IF NOT EXISTS cidade (
    id_cidade INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    uf CHAR(2) NOT NULL,
    CONSTRAINT fk_cidade_estado FOREIGN KEY (uf) REFERENCES estado(uf)
      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_cidade UNIQUE (nome, uf)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: usuario
-- =========================================================
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    tipo ENUM('organizador','fornecedor','convidado') NOT NULL,
    cpf VARCHAR(14),
    cnpj VARCHAR(18),
    foto_perfil_url VARCHAR(255),
    ativo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: fornecedor
-- =========================================================
CREATE TABLE IF NOT EXISTS fornecedor (
    id_fornecedor VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    telefone VARCHAR(20),
    email VARCHAR(120),
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    apto_para_operar BOOLEAN DEFAULT FALSE,
    id_usuario VARCHAR(36),
    CONSTRAINT fk_fornecedor_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_fornecedor_usuario ON fornecedor (id_usuario);

-- =========================================================
-- Tabela: fornecedor_endereco
-- =========================================================
CREATE TABLE IF NOT EXISTS fornecedor_endereco (
    id VARCHAR(36) PRIMARY KEY,
    id_fornecedor VARCHAR(36) NOT NULL,
    id_cidade INT NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20),
    bairro VARCHAR(100),
    cep VARCHAR(9),
    complemento VARCHAR(150),
    principal BOOLEAN NOT NULL DEFAULT FALSE,
    entrega BOOLEAN NOT NULL DEFAULT FALSE,
    cobranca BOOLEAN NOT NULL DEFAULT FALSE,
    correspondencia BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_pelo_menos_um_papel
      CHECK (principal OR entrega OR cobranca OR correspondencia),
    CONSTRAINT fk_endereco_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_endereco_cidade FOREIGN KEY (id_cidade) REFERENCES cidade(id_cidade)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_endereco_fornecedor ON fornecedor_endereco (id_fornecedor);

ALTER TABLE fornecedor_endereco
  ADD COLUMN principal_unico VARCHAR(36)
  GENERATED ALWAYS AS (CASE WHEN principal THEN id_fornecedor ELSE NULL END) VIRTUAL;

CREATE UNIQUE INDEX uq_endereco_principal_por_fornecedor
  ON fornecedor_endereco (principal_unico);

-- =========================================================
-- Tabela: categoria_servico
-- =========================================================
CREATE TABLE IF NOT EXISTS categoria_servico (
    id_categoria VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: servico
-- =========================================================
CREATE TABLE IF NOT EXISTS servico (
    id_servico VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    valor DECIMAL(10,2),
    unidade VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    id_fornecedor VARCHAR(36) NOT NULL,
    id_categoria VARCHAR(36) NOT NULL,
    CONSTRAINT fk_servico_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_servico_categoria FOREIGN KEY (id_categoria) REFERENCES categoria_servico(id_categoria)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_servico_fornecedor ON servico (id_fornecedor);
CREATE INDEX idx_servico_categoria ON servico (id_categoria);

-- =========================================================
-- Tabela: fornecedor_foto
-- =========================================================
CREATE TABLE IF NOT EXISTS fornecedor_foto (
    id VARCHAR(36) PRIMARY KEY,
    id_fornecedor VARCHAR(36) NOT NULL,
    url VARCHAR(255) NOT NULL,
    descricao VARCHAR(255),
    ordem INT DEFAULT 0,
    CONSTRAINT fk_fornecedor_foto FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: servico_foto
-- =========================================================
CREATE TABLE IF NOT EXISTS servico_foto (
    id VARCHAR(36) PRIMARY KEY,
    id_servico VARCHAR(36) NOT NULL,
    url VARCHAR(255) NOT NULL,
    descricao VARCHAR(255),
    ordem INT DEFAULT 0,
    CONSTRAINT fk_servico_foto FOREIGN KEY (id_servico) REFERENCES servico(id_servico)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: evento
-- =========================================================
CREATE TABLE IF NOT EXISTS evento (
    id_evento VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    data DATE NOT NULL,
    hora VARCHAR(10),
    local VARCHAR(200),
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    id_organizador VARCHAR(36),
    id_cidade INT,
    CONSTRAINT fk_evento_organizador FOREIGN KEY (id_organizador) REFERENCES usuario(id_usuario)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_evento_cidade FOREIGN KEY (id_cidade) REFERENCES cidade(id_cidade)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: convidado
-- =========================================================
CREATE TABLE IF NOT EXISTS convidado (
    id_convidado VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(120),
    grupo VARCHAR(100),
    status_presenca ENUM('confirmado','pendente','recusado') DEFAULT 'pendente',
    tipo ENUM('adulto','crianca') NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    id_usuario VARCHAR(36),
    id_evento VARCHAR(36) NOT NULL,
    CONSTRAINT fk_convidado_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_convidado_evento FOREIGN KEY (id_evento) REFERENCES evento(id_evento)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: territorio
-- =========================================================
CREATE TABLE IF NOT EXISTS territorio (
    id_territorio VARCHAR(36) PRIMARY KEY,
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    raio_km DECIMAL(6,2),
    descricao VARCHAR(200),
    ativo BOOLEAN DEFAULT TRUE,
    id_fornecedor VARCHAR(36) NOT NULL,
    CONSTRAINT fk_territorio_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: avaliacao
-- =========================================================
CREATE TABLE IF NOT EXISTS avaliacao (
    id_avaliacao VARCHAR(36) PRIMARY KEY,
    nota INT CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE,
    id_servico VARCHAR(36) NOT NULL,
    id_usuario VARCHAR(36) NOT NULL,
    CONSTRAINT fk_avaliacao_servico FOREIGN KEY (id_servico) REFERENCES servico(id_servico)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_avaliacao_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: fornecedor_evento
-- =========================================================
CREATE TABLE IF NOT EXISTS fornecedor_evento (
    id_fornecedor_evento VARCHAR(36) PRIMARY KEY,
    categoria VARCHAR(100),
    status ENUM('contratado','negociacao','aguardando_orcamento') DEFAULT 'aguardando_orcamento',
    observacoes TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    id_evento VARCHAR(36) NOT NULL,
    id_fornecedor VARCHAR(36) NOT NULL,
    CONSTRAINT fk_fornecedor_evento_evento FOREIGN KEY (id_evento) REFERENCES evento(id_evento)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fornecedor_evento_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: orcamento
-- =========================================================
CREATE TABLE IF NOT EXISTS orcamento (
    id_orcamento VARCHAR(36) PRIMARY KEY,
    categoria VARCHAR(100),
    item VARCHAR(150),
    custo_estimado DECIMAL(10,2),
    custo_real DECIMAL(10,2),
    forma_pagamento VARCHAR(50),
    status_pagamento ENUM('pendente','pago','atrasado') DEFAULT 'pendente',
    anotacoes TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    id_evento VARCHAR(36) NOT NULL,
    id_fornecedor VARCHAR(36),
    id_servico VARCHAR(36),
    CONSTRAINT fk_orcamento_evento FOREIGN KEY (id_evento) REFERENCES evento(id_evento)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_orcamento_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_orcamento_servico FOREIGN KEY (id_servico) REFERENCES servico(id_servico)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: pagamento
-- =========================================================
CREATE TABLE IF NOT EXISTS pagamento (
    id_pagamento VARCHAR(36) PRIMARY KEY,
    id_orcamento VARCHAR(36) NOT NULL,
    data_pagamento DATE NOT NULL,
    valor_pago DECIMAL(10,2) NOT NULL,
    forma_pagamento VARCHAR(50) NOT NULL,
	tipo_pagamento ENUM('total','parcial') DEFAULT 'parcial'
    observacoes TEXT,
    CONSTRAINT fk_pagamento_orcamento FOREIGN KEY (id_orcamento) REFERENCES orcamento(id_orcamento)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: tarefa
-- =========================================================
CREATE TABLE IF NOT EXISTS tarefa (
    id_tarefa VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    data_prevista DATE,
    status ENUM('pendente','concluida') DEFAULT 'pendente',
    ativo BOOLEAN DEFAULT TRUE,
    id_evento VARCHAR(36) NOT NULL,
    id_responsavel VARCHAR(36),
    CONSTRAINT fk_tarefa_evento FOREIGN KEY (id_evento) REFERENCES evento(id_evento)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_tarefa_responsavel FOREIGN KEY (id_responsavel) REFERENCES usuario(id_usuario)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabela: referencia
-- =========================================================
CREATE TABLE IF NOT EXISTS referencia (
    id_referencia VARCHAR(36) PRIMARY KEY,
    imagem_url VARCHAR(255),
    categoria VARCHAR(100),
    favorito BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    id_evento VARCHAR(36) NOT NULL,
    CONSTRAINT fk_referencia_evento FOREIGN KEY (id_evento) REFERENCES evento(id_evento)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================================
-- Tabelas de Cotações
-- =========================================================
CREATE TABLE IF NOT EXISTS cotacao (
    id_cotacao INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    data_cotacao DATE,
    descricao VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fornecedor (
    id_fornecedor VARCHAR(36) PRIMARY KEY,
    nome VARCHAR(150) NOT NULL
    -- outros campos do fornecedor...
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS fornecedor_cotacao (
    id_cotacao INT UNSIGNED NOT NULL,
    id_fornecedor VARCHAR(36) NOT NULL,
    prazo_entrega VARCHAR(50),
    venda_condicoes_pagamento VARCHAR(50),
    PRIMARY KEY (id_cotacao, id_fornecedor), -- chave composta
    CONSTRAINT fk_fornecedor_cotacao_cabecalho FOREIGN KEY (id_cotacao) REFERENCES cotacao(id_cotacao)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fornecedor_cotacao_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cotacao_detalhe (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_cotacao INT UNSIGNED NOT NULL,
    id_fornecedor VARCHAR(36) NOT NULL,
    id_produto INT NOT NULL,
    quantidade DECIMAL(15,2),
    valor_unitario DECIMAL(15,2),
    valor_subtotal DECIMAL(15,2),
    taxa_desconto DECIMAL(5,2),
    valor_desconto DECIMAL(15,2),
    valor_total DECIMAL(15,2),
    CONSTRAINT fk_cotacao_detalhe_fornecedor FOREIGN KEY (id_cotacao, id_fornecedor) REFERENCES fornecedor_cotacao(id_cotacao, id_fornecedor)
      ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_cotacao_detalhe_produto FOREIGN KEY (id_produto) REFERENCES servico(id_produto)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

