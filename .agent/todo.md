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
- [x] Endpoint: Dashboard Summary (Vendas/Lucro Dia, Sem, Mês)
- [x] Endpoint: Dashboard Recent Sales
- [x] Endpoint: Dashboard Top Products

- [x] Endpoint: Dashboard Inventory Summary (Patrimônio)
- [x] Endpoint: Dashboard Smart Alerts (Estoque < Média Vendas)
- [x] Endpoint: Update Dashboard Summary with Average Ticket

## Frontend (Flutter Desktop)
- [x] Criar projeto Flutter para Windows
- [x] **Tela Inicial (Home)**
    - [x] Implementar Dashboard Real (Vendas, Lucro, Top Produtos, Últimas Vendas)
    - [x] Implementar Widget Smart Alerts (Estoque Baixo)
    - [x] Implementar Widget Patrimônio & Potencial de Venda
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

## Server Manager (GUI/Tray)
- [x] Criar interface gráfica (Tkinter) para controle do servidor
- [x] Implementar teste de conexão com o banco de dados
- [x] Implementar botão para inicializar o banco de dados (Executar schema.sql)
- [x] Implementar System Tray (Ícone na bandeja)
    - [x] Servidor continua rodando ao fechar a janela (Minimizar para bandeja)
    - [x] Duplo clique no ícone restaura a janela
    - [x] Indicativo visual de servidor rodando (Status Label/Icon)

## Build & Deploy
- [x] Criar executável do servidor Flask
- [x] Criar instalador/executável do cliente Flutter Windows

## Configuração Dinâmica
- [x] **Backend**: Criar UI em `server_gui.py` para definir Host, Porta, User, Pass, DB do PostgreSQL.
- [x] **Backend**: Persistir configurações em `db_config.json`.
- [x] **Frontend**: Criar tela de configurações de API (Host/Porta).
- [x] **Frontend**: Persistir URL da API via SharedPreferences.

## Formas de Pagamento
- [x] Criar tabela 'formas_pagamento' no banco de dados e alterar tabela 'vendas' no PostgreSQL
- [x] Implementar modelo SQLAlchemy e endpoints CRUD no Flask (`/payment-methods`)
- [x] Modificar endpoint de registro de venda (`/sales`) para persistir a forma de pagamento
- [x] Criar interface de gerenciamento (CRUD) de Formas de Pagamento em `config_screen.dart`
- [x] Integrar seleção de forma de pagamento na Tela de Vendas (PDV) com suporte a atalhos de teclado rápidos (ex: pressionar 'D' para Dinheiro)

## Relatórios de Vendas
- [x] Criar endpoints de relatório de vendas por forma de pagamento e detalhes no Flask (`/reports/sales-by-payment` e `/reports/sales-details`)
- [x] Adicionar aba de navegação dedicada para Relatórios em `home_screen.dart`
- [x] Criar a tela `reports_screen.dart` para filtros de data, estatísticas de vendas, ticket médio, participação das formas com barras de progresso, e listagem detalhada filtrável
