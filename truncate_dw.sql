-- ============================================================
-- Truncate completo para reprocessamento (ordem importa por FK)
-- ============================================================
TRUNCATE TABLE fato_reviews    RESTART IDENTITY CASCADE;
TRUNCATE TABLE fato_pagamentos RESTART IDENTITY CASCADE;
TRUNCATE TABLE fato_vendas     RESTART IDENTITY CASCADE;
TRUNCATE TABLE dim_geolocalizacao RESTART IDENTITY CASCADE;
TRUNCATE TABLE dim_categoria   RESTART IDENTITY CASCADE;
TRUNCATE TABLE dim_vendedores  RESTART IDENTITY CASCADE;
TRUNCATE TABLE dim_produtos    RESTART IDENTITY CASCADE;
TRUNCATE TABLE dim_clientes    RESTART IDENTITY CASCADE;
-- dim_tempo NÃO é truncada (dados estáticos)
