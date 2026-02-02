# Lista de Tarefas - Projeto Estok

## Configuração Inicial
- [x] Configurar ambiente Python (Flask)
- [x] Configurar ambiente Flutter
- [x] Configurar banco de dados PostgreSQL (criar banco 'estok')

## Banco de Dados
- [x] Criar script de criação das tabelas (Schema)
- [x] Implementar conexão no Flask

## Backend (Flask)
- [x] Criar estrutura básica da API
- [x] Endpoint: Cadastro de Produtos (POST)
- [x] Endpoint: Consulta de Produtos (GET - Busca dinâmica, por ID, EAN)
- [x] Endpoint: Consulta de Todos os Produtos (GET /products/all)
- [x] Endpoint: Atualização de Estoque (PUT/PATCH) - (Via PUT /products/<id> para edição básica, movimentação via /estok/movement implementada)
- [x] Endpoint: Registro de Venda (POST - Movimentação de saída)
- [x] Criar lógica de busca "Consultar a cada letra" (Prioridade: Exato > Inicio > Contém)

## Frontend (Flutter Desktop)
- [x] Criar projeto Flutter para Windows
- [x] **Tela Inicial (Home)**
    - [x] Implementar Dashboard (Placeholder)
    - [x] Navegação para outras telas
- [x] **Tela: Cadastro de Produtos**
    - [x] Campos: Descrição, EAN13/GTIN, Código Auxiliar, Qtd Inicial, Preço, etc.
- [x] **Tela: Atualização de Estoque**
    - [x] Interface estilo planilha (DataGrid) para edição rápida
    - [x] Funcionalidade de salvar alterações em lote
- [x] **Tela: Venda (PDV)**
    - [x] Input inteligente (reconhecer padrão `5*PRODUTO`)
    - [x] Pesquisa dinâmica ao digitar (Dropdown/Overlay)
    - [x] Processamento de input de Código de Barras direto
    - [x] Lista de itens na venda atual
    - [x] Finalização da venda

## Build & Deploy
- [ ] Criar executável do servidor Flask
- [ ] Criar instalador/executável do cliente Flutter Windows
