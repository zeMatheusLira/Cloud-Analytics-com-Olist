# Cloud-Analytics-com-Olist

# Etapa 1 — Modelagem Dimensional

## 1.1 Modelo Dimensional de Alto Nível

### Contexto

Os dados públicos da Olist (https://github.com/olist/work-at-olist-data) são fornecidos em um
**modelo relacional transacional (OLTP)**, normalizado e otimizado para operações de
escrita do dia a dia do e-commerce. Esse modelo é composto por 9 tabelas principais:

| Tabela de origem (CSV)                  | Conteúdo                                                            |
|------------------------------------------|----------------------------------------------------------------------|
| `olist_orders_dataset`                   | Pedidos: status e datas (compra, aprovação, envio, entrega)          |
| `olist_order_items_dataset`              | Itens de cada pedido: produto, vendedor, preço, frete                |
| `olist_order_payments_dataset`           | Pagamentos: tipo, número de parcelas, valor                          |
| `olist_order_reviews_dataset`            | Avaliações dos clientes sobre o pedido                               |
| `olist_customers_dataset`                | Dados cadastrais do cliente                                          |
| `olist_products_dataset`                 | Dados do produto: categoria, peso, dimensões físicas                 |
| `olist_sellers_dataset`                  | Dados cadastrais do vendedor (lojista parceiro)                      |
| `olist_geolocation_dataset`              | Coordenadas geográficas associadas a CEPs                            |
| `product_category_name_translation`      | Tradução das categorias de produto (PT → EN)                         |

Para fins analíticos, esse modelo apresenta limitações conhecidas: múltiplos `JOINs` são
necessários para responder perguntas simples de negócio, o que penaliza a performance de
consultas analíticas (OLAP) e dificulta o consumo direto por ferramentas de BI como o
Apache Superset/Preset.

A proposta desta etapa é remodelar esses dados em um **Star Schema (esquema estrela)**,
desnormalizando as dimensões e centralizando as métricas de negócio em uma única tabela
de fatos, de forma a otimizar a performance de leitura e simplificar a construção de
dashboards.

### Escopo do projeto

O Data Warehouse construído tem como objetivo dar suporte analítico às seguintes frentes
de negócio da Olist:

- **Vendas e receita**: volume de vendas, ticket médio, sazonalidade e desempenho por
  categoria de produto.
- **Rede de vendedores (sellers)**: identificação de vendedores de destaque, distribuição
  geográfica e possível padronização de preços entre lojistas.
- **Logística**: tempo de entrega, valor de frete por região/cidade e gargalos
  operacionais.
- **Satisfação do cliente**: relação entre review score, tempo de entrega e categoria do
  produto.

O escopo cobre o ciclo de vida completo do pedido — da efetivação da compra até a entrega
e avaliação pelo cliente integrando dados transacionais, de pagamento, geográficos e de
satisfação em um único ambiente analítico hospedado no Supabase (PostgreSQL).

**Fora do escopo desta primeira versão**: dados de geolocalização detalhados a nível de
latitude/longitude (tratados como atributo descritivo dentro das dimensões de cliente e
vendedor, e não como dimensão própria), e modelos preditivos (que poderão ser explorados
em uma etapa futura de Data Science sobre o mesmo DW).

### Granularidade da tabela de fatos

> **Grão escolhido: 1 linha = 1 item de pedido** (chave primária composta por
> `order_id` + `order_item_id` na origem).

Essa decisão foi tomada por ser o **nível mais atômico disponível** nos dados de origem
(tabela `olist_order_items_dataset`). Justificativa:

- Um pedido (`order`) pode conter **múltiplos itens**, de **produtos e vendedores
  diferentes** — se o grão fosse "1 pedido", essa informação seria perdida ou exigiria
  agregações que mascarariam o desempenho individual de produto/vendedor.
- O grão de item de pedido permite **flexibilidade de agregação**: é possível somar para
  o nível de pedido, cliente, vendedor, produto, categoria ou data, sem perda de
  informação (princípio de "menor grão possível" da modelagem dimensional de Kimball).
- Métricas como `price` e `freight_value` são naturalmente medidas no nível do item, e não
  do pedido como um todo.

### Tabela de fatos e dimensões propostas

| Tabela            | Tipo      | Tabelas de origem (CSV)                                                  |
|--------------------|-----------|---------------------------------------------------------------------------|
| `fact_sales`       | Fato      | `order_items` + `orders` + `order_payments` (agregado) + `order_reviews` |
| `dim_customer`     | Dimensão  | `customers`                                                              |
| `dim_seller`       | Dimensão  | `sellers`                                                                |
| `dim_product`      | Dimensão  | `products` + `product_category_name_translation`                        |
| `dim_date`         | Dimensão  | gerada (calendário), derivada das datas de `orders`                     |
| `dim_payment_type` | Dimensão  | `order_payments`                                                         |

**Principais métricas (fatos) na `fact_sales`**: `price`, `freight_value`,
`payment_value`, `payment_installments`, `review_score`.

**Observação sobre pagamentos**: como um pedido pode ter mais de uma forma de pagamento
(ex: cartão + voucher), a granularidade de `order_payments` é mais fina que a de
`order_items`. Essa relação N:N será tratada na Etapa 1.2/ETL optando por uma
agregação (valor total pago por pedido, rateado entre os itens) ou pela criação de uma
dimensão de pagamento simplificada (`tipo de pagamento predominante`), a ser definida e
documentada na modelagem detalhada.

### Diagrama inicial do modelo dimensional

A figura abaixo apresenta a visão de alto nível do Star Schema: a tabela de fatos
`FACT_SALES` no centro, conectada a cada dimensão por meio de chaves substitutas (SK),
sem o detalhamento completo de todos os atributos (que será apresentado na Etapa 1.2).

![Diagrama do Star Schema - Olist](./olist_star_schema_alto_nivel.png)

**Leitura do diagrama**: cada relacionamento é do tipo 1:N entre dimensão e fato — uma
linha de dimensão (ex: um cliente) pode estar associada a N linhas na fato (N itens de
pedidos diferentes), nunca o inverso. Essa é a característica estrutural que define o
esquema estrela e garante performance de leitura via `JOINs` simples e diretos.
