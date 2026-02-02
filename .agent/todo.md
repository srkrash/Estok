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
- [x] Endpoint: Atualização de Estoque (PUT/PATCH) - (Via PUT /products/<id> para edição básica, movimentação via /estok/movement implementada)
- [x] Endpoint: Registro de Venda (POST - Movimentação de saída)
- [x] Criar lógica de busca "Consultar a cada letra" (Prioridade: Exato > Inicio > Contém)

## Frontend (Flutter Desktop)
- [x] Criar projeto Flutter para Windows
- [ ] **Tela: Cadastro de Produtos**
    - [ ] Campos: Descrição, EAN13/GTIN, Código Auxiliar, Qtd Inicial, Preço, etc.
- [ ] **Tela: Atualização de Estoque**
    - [ ] Interface estilo planilha (DataGrid) para edição rápida
    - [ ] Funcionalidade de salvar alterações em lote
- [ ] **Tela: Venda (PDV)**
    - [ ] Input inteligente (reconhecer padrão `5*PRODUTO`)
    - [ ] Pesquisa dinâmica ao digitar (Dropdown/Overlay)
    - [ ] Processamento de input de Código de Barras direto
    - [ ] Lista de itens na venda atual
    - [ ] Finalização da venda

## Build & Deploy
- [ ] Criar executável do servidor Flask
- [ ] Criar instalador/executável do cliente Flutter Windows
