-- ============================================================
-- DDL - Data Warehouse Olist (Star Schema COMPLETO)
-- Versão 3: todos os 9 CSVs, sem FK problemáticas
-- ============================================================

-- ============================================================
-- DIMENSÕES
-- ============================================================

CREATE TABLE dim_clientes (
    sk_cliente SERIAL PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    cidade_cliente VARCHAR(100),
    estado_cliente CHAR(2)
);

CREATE TABLE dim_produtos (
    sk_produto SERIAL PRIMARY KEY,
    product_id VARCHAR(50) NOT NULL,
    categoria_produto VARCHAR(100),
    peso_gramas INT,
    altura_cm INT,
    largura_cm INT,
    comprimento_cm INT
);

CREATE TABLE dim_vendedores (
    sk_vendedor SERIAL PRIMARY KEY,
    seller_id VARCHAR(50) NOT NULL,
    cidade_vendedor VARCHAR(100),
    estado_vendedor CHAR(2)
);

CREATE TABLE dim_geolocalizacao (
    sk_geo SERIAL PRIMARY KEY,
    cep_prefixo INT NOT NULL,
    latitude NUMERIC(10,6),
    longitude NUMERIC(10,6),
    cidade VARCHAR(100),
    estado CHAR(2)
);

CREATE TABLE dim_categoria (
    sk_categoria SERIAL PRIMARY KEY,
    nome_categoria_pt VARCHAR(100) NOT NULL,
    nome_categoria_en VARCHAR(100)
);

CREATE TABLE dim_tempo (
    sk_tempo INT PRIMARY KEY,
    data DATE NOT NULL,
    ano INT NOT NULL,
    mes INT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL
);

-- ============================================================
-- FATOS
-- ============================================================

CREATE TABLE fato_vendas (
    sk_venda SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    sk_cliente INT REFERENCES dim_clientes(sk_cliente),
    sk_produto INT REFERENCES dim_produtos(sk_produto),
    sk_vendedor INT REFERENCES dim_vendedores(sk_vendedor),
    -- sem FK em sk_tempo_pedido e sk_tempo_entrega
    -- pois pedidos não entregues geram sk=-1 (não presente em dim_tempo)
    sk_tempo_pedido INT,
    sk_tempo_entrega INT,
    preco_item NUMERIC(10,2) NOT NULL,
    valor_frete NUMERIC(10,2) NOT NULL,
    status_pedido VARCHAR(30),
    dias_atraso_entrega INT
);

CREATE TABLE fato_pagamentos (
    sk_pagamento SERIAL PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    sequencial_pagamento INT NOT NULL,
    tipo_pagamento VARCHAR(30),
    parcelas INT,
    valor_pagamento NUMERIC(10,2) NOT NULL
    -- sem sk_cliente: pagamentos se ligam ao cliente via order_id -> fato_vendas
);

CREATE TABLE fato_reviews (
    sk_review SERIAL PRIMARY KEY,
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    nota_review INT CHECK (nota_review BETWEEN 1 AND 5),
    titulo_comentario VARCHAR(100),
    mensagem_comentario TEXT,
    sk_tempo_review INT
    -- sem FK em sk_tempo_review pelo mesmo motivo do sk_tempo_entrega
);

-- ============================================================
-- Dimensão de tempo (2016 a 2020)
-- ============================================================
INSERT INTO dim_tempo (sk_tempo, data, ano, mes, nome_mes)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INT AS sk_tempo,
    d::DATE AS data,
    EXTRACT(YEAR FROM d)::INT AS ano,
    EXTRACT(MONTH FROM d)::INT AS mes,
    TO_CHAR(d, 'TMMonth') AS nome_mes
FROM generate_series('2016-01-01'::TIMESTAMP, '2020-12-31'::TIMESTAMP, '1 day'::INTERVAL) d;

-- ============================================================
-- Índices de performance
-- ============================================================
CREATE INDEX idx_fato_sk_cliente        ON fato_vendas (sk_cliente);
CREATE INDEX idx_fato_sk_produto        ON fato_vendas (sk_produto);
CREATE INDEX idx_fato_sk_vendedor       ON fato_vendas (sk_vendedor);
CREATE INDEX idx_fato_sk_tempo_pedido   ON fato_vendas (sk_tempo_pedido);
CREATE INDEX idx_fato_sk_tempo_entrega  ON fato_vendas (sk_tempo_entrega);
CREATE INDEX idx_fato_order_id          ON fato_vendas (order_id);

CREATE INDEX idx_pag_order_id           ON fato_pagamentos (order_id);
CREATE INDEX idx_pag_tipo               ON fato_pagamentos (tipo_pagamento);

CREATE INDEX idx_rev_order_id           ON fato_reviews (order_id);
CREATE INDEX idx_rev_sk_tempo           ON fato_reviews (sk_tempo_review);
CREATE INDEX idx_rev_nota               ON fato_reviews (nota_review);

CREATE INDEX idx_geo_cep                ON dim_geolocalizacao (cep_prefixo);
