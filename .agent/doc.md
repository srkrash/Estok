# Documentação do Projeto Estok

## Visão Geral
Aplicação de controle de estoque e vendas focado em desktop Windows (com futuro suporte a mobile). O sistema opera localmente, com um servidor Flask e banco de dados PostgreSQL rodando na máquina do cliente, e uma interface desenvolvida em Flutter.

## Stack Tecnológico
- **Frontend**: Flutter (Windows Desktop)
- **Backend**: Python (Flask)
- **Banco de Dados**: PostgreSQL (Nome do banco: `estok`). Script de criação em `estok-db/schema.sql`.

## Arquitetura
- Aplicação Desktop Standalone.
- **Server Manager**: Aplicação de bandeja (Tray App) para gerenciamento do servidor Flask e Banco de Dados.
- Servidor Flask será compilado para executável (`estok-server.exe`).
- Client Frontend: Flutter (Windows Desktop), gera executável principal (ex: `stock_fe.exe`), acessível via atalhos "Estok Client".
- Comunicação via HTTP REST API (localhost).

## Build & Deploy
Para gerar os executáveis e o instalador:
1. **Backend**: `pyinstaller --noconsole --onefile --name estok-server --add-data "logo_green.ico;." --add-data "logo_green_tray.png;." server_gui.py` (dentro do `venv`).
2. **Frontend**: `flutter build windows --release`.
3. **Instalador**: Compilar `estok_installer.iss` usando Inno Setup. O instalador configura idioma PT-BR e cria atalhos na Área de Trabalho para Server e Client.

## Funcionalidades Principais

### 0. Tela Inicial (Navegação por Abas)
Estrutura principal da aplicação com persistência de estado.
- **Menu Superior**: Header unificado com Logo à esquerda e Navegação centralizada com abas coloridas.
- **Dashboard**: Aba inicial com KPIs de Vendas e Lucro (Dia, Semana, Mês), Lista de Últimas Vendas e Top Produtos.
- **Multitarefa**: Permite alternar entre telas sem perder dados não salvos.
- **Transições**: Animação suave de deslizamento entre as abas e transições visuais nos botões.

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

### 2. Atualização de Estoque (Em Massa)
- **Visualização Tabular**: Exibe todos os produtos com colunas editáveis.
- **Edição em Lote**:
    - Permite alterar a quantidade de múltiplos produtos diretamente na tabela.
    - Linhas editadas são destacadas (Laranja) para indicar alterações pendentes.
    - **Proteção de Dados**:
        - Botão "Salvar" envia todas as alterações de uma vez (chamadas individuais API).
        - Botão "Cancelar" descarta edições e recarrega dados originais.
        - Botão "Atualizar" (Refresh) alerta se houver dados não salvos antes de recarregar.
- **Interface**: Segue o mesmo padrão visual da tela de produtos (animações, responsividade) para consistência.

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
- **Atalhos de Teclado**:
    - **F1**: Busca (Foca no campo de pesquisa e exibe a lista com todos os produtos cadastrados).
    - **F6**: Finalizar Venda.
    - **F8**: Cancelar Venda.
    - **ENTER**:
        - No campo de busca: Se houver apenas 1 resultado, adiciona direto (Modo Scanner). Se houver lista, seleciona o item.
        - Na tela de venda finalizada: Inicia uma nova venda.
    - **ESC**: Fecha overlay de busca ou cancela ações.
    - **Seta Para Cima/Para Baixo (↑/↓)**: Navega pelos itens da lista com rolagem automática inteligente para manter o produto selecionado sempre visível.
- **Persistência de Estado (Cart)**: O carrinho é mantido ao navegar entre abas (ex: ir ao estoque e voltar), permitindo consultas rápidas sem perder a venda atual.
- **Feedback Visual**: Overlay de busca posicionado com precisão (reutilizado dinamicamente para preservar posição de rolagem), loading indicators, e tela de sucesso ao finalizar.

### 5. Sincronização em Tempo Real (Event-Driven)
Sistema de notificação global (`EventService`) que mantém todas as telas atualizadas automaticamente.
- **Fluxo de Atualização**:
    - **Venda Realizada**: Ao finalizar uma venda na tela de PDV, um sinal é enviado para recarregar a lista de produtos e a tela de estoque.
    - **Ajuste de Estoque**: Alterações na tela de Estoque ou Cadastro atualizam imediatamente as outras telas.
- **Gestão de Conflitos (Tela de Estoque)**:
    - Se a tela de Estoque receber um sinal de atualização (ex: venda realizada em outra aba) enquanto o usuário estiver editando quantidades (com alterações não salvas), a atualização automática é pausada.
    - Um alerta (Snackbar) informa o usuário: *"Atenção: Movimentações de estoque ocorreram..."*.
    - Isso previne que o trabalho de digitação do usuário seja sobrescrito inesperadamente.


### 5.1. Formas de Pagamento
Funcionalidade integrada de controle e finalização de vendas:
- **Gestão (CRUD)**: Acessível na aba "Formas de Pagamento" dentro de Configurações, permitindo adicionar, editar, ativar/desativar e excluir opções de pagamento.
- **Atalhos do Teclado no PDV**: Cada forma possui um atalho de uma única letra (ex: 'D' para Dinheiro, 'P' para Pix). Ao clicar em Finalizar (F6), abre-se um modal. Pressionar a letra de atalho no teclado confirma a venda com aquela forma de pagamento instantaneamente.
- **Soft-Delete Automatizado**: Caso uma forma de pagamento possua vendas associadas no banco, o sistema impede a exclusão física e realiza soft-delete (marcando `ativo=false`), garantindo a integridade dos dados históricos.

### 5.2. Relatórios de Vendas
Módulo dedicado a relatórios analíticos de faturamento:
- **Aba de Navegação dedicada**: Separada do Dashboard para flexibilidade de consultas por período.
- **Filtro de Período**: Seleção personalizada de data inicial e final, com atalhos rápidos ("Hoje", "7 Dias", "Mês Atual").
- **Participação por Forma de Pagamento**: Visualização com barras de progresso que mostram o percentual de faturamento de cada forma de pagamento.
- **Lista Detalhada**: Exibe o log detalhado de todas as vendas do período, permitindo filtrar por uma forma de pagamento específica ao clicar em seu card de resumo.

## Regras de Negócio e Detalhes
- **Código Auxiliar**: Facilitador de venda. Deve ser único e curto (3-6 dígitos).
- **Banco de Dados**: Persiste produtos, movimentações e vendas.

### 6. Configuração e Persistência
O sistema permite configuração dinâmica de conexões. 
- **Server Manager**: 
    - Interface: Host, Porta, Usuário, Senha, DB Name.
    - **Lógica de Persistência (Ordem de Prioridade)**:
        1. **`%LOCALAPPDATA%\Estok\db_config.json`**: Configuração personalizada do usuário (criada via GUI).
        2. **`Pasta da Aplicação\db_config.json`**: "Padrão de Fábrica" distribuído com o instalador (editável pelo admin).
        3. **Hardcoded Defaults**: `localhost:5432` / `postgres` / `estok`.
    - Codificação: `UTF-8` forçado para suportar senhas com caracteres especiais.
- **Frontend App**:
    - Tela de Configurações (ícone de engrenagem na Home).
    - Permite definir Host e Porta da API Flask.
    - Persiste via `SharedPreferences` (armazenamento nativo do SO).
    - **Arquivo `.env`**: Requer a existência de um arquivo `.env` na raiz do diretório `estok-fe` (mesmo vazio ou apenas com comentários) para inicializar a biblioteca `flutter_dotenv` e satisfazer a declaração de assets no `pubspec.yaml`.


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
    - `id_forma_pagamento`: ID da forma de pagamento selecionada (opcional).
  - **Retorno**: ID da venda gerada e confirmação de total.

### Formas de Pagamento
- `GET /payment-methods`
  - **Query Params**: `active_only` (bool, padrão `false`)
  - **Retorno**: Lista de formas de pagamento cadastradas `[{id, nome, atalho, ativo}]`.
- `POST /payment-methods`
  - **Body**: `{id (opcional), nome, atalho (única letra), ativo}`.
  - **Retorno**: Confirmação de cadastro/atualização e a forma de pagamento gerada.
- `DELETE /payment-methods/<id>`
  - **Retorno**: Sucesso na exclusão. Se a forma de pagamento já tiver vendas associadas, realiza soft-delete (apenas desativa, definindo `ativo=false`).

### Dashboard
- `GET /dashboard/summary`
    - **Retorno**: 
      ```json
      {
        "sales": {"today": float, "week": float, "month": float},
        "profit": {"today": float, "week": float, "month": float}
      }
      ```
- `GET /dashboard/recent-sales`
    - **Retorno**: Lista das 5 últimas vendas.
- `GET /dashboard/top-products`
    - **Retorno**: Lista dos 5 produtos mais vendidos na semana.
- `GET /dashboard/inventory-summary`
    - **Retorno**: `{ "total_cost_value": float, "total_sale_potential": float, "total_items": float }`
- `GET /dashboard/smart-alerts`
    - **Lógica**: Identifica produtos com cobertura de estoque < 7 dias (baseado na média de vendas dos últimos 30 dias).
    - **Retorno**: Lista de produtos críticos.

### Relatórios
- `GET /reports/sales-by-payment`
  - **Query Params**: `start_date` (YYYY-MM-DD), `end_date` (YYYY-MM-DD).
  - **Retorno**: `{ "start_date": str, "end_date": str, "total_faturamento": float, "data": [{ "id": int, "nome": str, "atalho": str, "qtd_vendas": int, "total_vendas": float, "percentual": float }] }`.
- `GET /reports/sales-details`
  - **Query Params**: `start_date` (YYYY-MM-DD), `end_date` (YYYY-MM-DD), `id_forma_pagamento` (int, opcional).
  - **Retorno**: `{ "start_date": str, "end_date": str, "count": int, "data": [{ "id": int, "data_venda": str, "valor_total": float, "id_forma_pagamento": int, "forma_pagamento_nome": str, "items_count": float }] }`.
