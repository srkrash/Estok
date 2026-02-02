# Documentação do Projeto Estok

## Visão Geral
Aplicação de controle de estoque e vendas focado em desktop Windows (com futuro suporte a mobile). O sistema opera localmente, com um servidor Flask e banco de dados PostgreSQL rodando na máquina do cliente, e uma interface desenvolvida em Flutter.

## Stack Tecnológico
- **Frontend**: Flutter (Windows Desktop)
- **Backend**: Python (Flask)
- **Banco de Dados**: PostgreSQL (Nome do banco: `estok`). Script de criação em `estok-db/schema.sql`.

## Arquitetura
- Aplicação Desktop Standalone.
- Servidor Flask será compilado para executável.
- Comunicação via HTTP REST API (localhost).

## Funcionalidades Principais

### 0. Tela Inicial (Dashboard)
Ponto de entrada da aplicação.
- **Dashboard**: Exibe resumo de vendas do dia (Placeholder implementado).
- **Navegação**: Acesso rápido às telas de Cadastro, Estoque e Vendas.

### 1. Cadastro de Produtos
Tela para inserção de novos itens no inventário.
**Campos:**
- Descrição
- Quantidade (Estoque Atual)
- Código de Barras (EAN13/GTIN)
- Código Auxiliar (Numérico, 3 a 6 dígitos, para produtos sem código de barras)
- Data de Cadastro
- Preço de Custo
- Preço de Venda (Sugerido)

### 2. Atualização de Estoque em Massa
Tela otimizada para produtividade.
- Visualização em grade/planilha.
- Permite editar a quantidade de múltiplos produtos rapidamente.
- Ideal para ajustes de balanço ou entrada de mercadoria simples.

### 3. Histórico de Movimentações (Kardex)
Registro detalhado de todas as operações de estoque (entradas, saídas, ajustes). Permite rastreabilidade completa do giro de produtos.

### 4. Tela de Venda (PDV)
Interface ágil para registro de saídas.
**Lógica de Input:**
- Entrada Única: Usuário digita código ou descrição.
- Multiplicador: Suporte a formato `Quantidade * Item` (ex: `5*AGUA`).
- **Busca Dinâmica (Consultar a cada letra)**:
    - Otimizada para retorno rápido (máx. 20 resultados).
    - **Prioridade de Exibição**:
        1. Código exato (Barras ou Auxiliar).
        2. Início da descrição (Prefix match).
        3. Contém na descrição param.

## Regras de Negócio e Detalhes
- **Código Auxiliar**: Facilitador de venda. Deve ser único e curto (3-6 dígitos).
- **Banco de Dados**: Deve persistir dados de produtos e histórico de vendas? (A princípio focado em controle de estoque e registro de saída).

## Endpoints API (Flask)

### Produtos
- `GET /products`
    - **Query Params**: `q` (termo de busca: nome, EAN, ou código auxiliar)
    - **Retorno**: Lista de produtos encontrados.
- `POST /products`
    - **Body**: JSON com dados do produto (`description`, `ean13`, `qtd`, etc.)
    - **Retorno**: Confirmação de criação e ID do novo produto.
- `PUT /products/<id>`
    - **Body**: JSON com campos a atualizar.
    - **Retorno**: Confirmação de atualização.

### Estoque
- `POST /estok/movement`
    - **Body**:
        - `id_produto`: ID do produto.
        - `tipo`: 'ENTRADA' | 'SAIDA' | 'AJUSTE'.
        - `quantidade`: 
            - Se ENTRADA/SAIDA: Quantidade a adicionar/subtrair.
            - Se AJUSTE: Nova quantidade total (substitui o estoque atual).
        - `observacao`: Texto opcional.
    - **Retorno**: Confirmação da movimentação e dados atualizados.

### Vendas
- `POST /sales`
    - **Body**:
        - `items`: Lista de objetos `{id_produto, quantidade, valor_unitario}`.
        - `valor_total`: Valor total da venda.
    - **Retorno**: ID da venda gerada.
