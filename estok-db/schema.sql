-- Extension: pg_trgm
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Table: produtos
CREATE TABLE IF NOT EXISTS public.produtos (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(255),
    ean13 VARCHAR(13),
    codigo_auxiliar VARCHAR(6),
    quantidade NUMERIC(10,3),
    preco_custo NUMERIC(10,2),
    preco_venda NUMERIC(10,2),
    data_cadastro TIMESTAMP WITHOUT TIME ZONE,
    ativo BOOLEAN DEFAULT true
);

-- Table: vendas
CREATE TABLE IF NOT EXISTS public.vendas (
    id SERIAL PRIMARY KEY,
    data_venda TIMESTAMP WITHOUT TIME ZONE,
    valor_total NUMERIC(10,2)
);

-- Table: itens_venda
CREATE TABLE IF NOT EXISTS public.itens_venda (
    id SERIAL PRIMARY KEY,
    id_venda INTEGER REFERENCES public.vendas(id),
    id_produto INTEGER REFERENCES public.produtos(id),
    quantidade NUMERIC(10,3),
    preco_custo NUMERIC(10,2),
    valor_unitario NUMERIC(10,2),
    valor_total NUMERIC(10,2)
);

-- Table: movimentacoes_estoque
CREATE TABLE IF NOT EXISTS public.movimentacoes_estoque (
    id SERIAL PRIMARY KEY,
    id_produto INTEGER REFERENCES public.produtos(id),
    tipo VARCHAR(20),
    quantidade_anterior NUMERIC(10,3),
    quantidade_movimentada NUMERIC(10,3),
    quantidade_nova NUMERIC(10,3),
    data_movimentacao TIMESTAMP WITHOUT TIME ZONE,
    id_venda INTEGER REFERENCES public.vendas(id),
    observacao TEXT
);

-- Indexes for produtos
CREATE INDEX IF NOT EXISTS index_codigo_auxiliar ON public.produtos (codigo_auxiliar);
CREATE INDEX IF NOT EXISTS index_ean13 ON public.produtos (ean13);
CREATE INDEX IF NOT EXISTS index_descricao_trigram ON public.produtos USING gin (descricao gin_trgm_ops);

-- Indexes for itens_venda (Primary Key index is implicit, but good to have explicit FK indexes for performance if needed, though not strictly in original schema observation. I will stick to observed indexes only + implicit PKs)
-- Observed indexes were mainly PKs and the specific ones on produtos.

