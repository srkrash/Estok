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

### 0. Tela Inicial (Navegação por Abas)
Estrutura principal da aplicação com persistência de estado.
- **Menu Superior**: Abas para troca rápida entre módulos (Início, Produtos, Estoque, Vendas).
- **Dashboard**: Aba inicial com resumo de vendas (Placeholder).
- **Multitarefa**: Permite alternar entre telas sem perder dados não salvos.

### 1. Cadastro de Produtos
Tela para inserção de novos itens no inventário.
- **Modo Integrado**: O formulário é exibido dentro da tela de listagem, mantendo o menu superior acessível.
- **Responsividade**: Adapta-se automaticamente à largura da janela (80% em telas grandes, 100% em telas < 1200px).
**Campos:**
- Descrição
- Quantidade (Estoque Atual - permite ajuste direto que gera movimentação de estoque)
- Código de Barras (EAN13/GTIN)
- Código Auxiliar (Numérico, 3 a 6 dígitos, para produtos sem código de barras)
- Data de Cadastro
- Preço de Custo
- Preço de Venda (Sugerido)

### 2. Atualização de Estoque
- Ajustes de quantidade realizados na edição de produtos geram automaticamente registros de movimentação (`AJUSTE`) via API.

### 3. Melhorias de Interface (UI/UX)
- **Layout Responsivo**:
    - **Desktop (>1200px)**: Conteúdo centralizado ocupando 80% da tela para melhor leitura.
    - **Telas Menores (<1200px)**: Conteúdo expande para 100% da largura.
- **Visual Refinado**:
    - Cabeçalhos de tabela e barras de busca com fundos "full-width" para consistência visual.
    - Tabela de produtos com colunas otimizadas (ID reduzido, Descrição expandida) para evitar cortes de texto.
    - Formatação numérica e monetária padronizada (vírgula como separador decimal).

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
