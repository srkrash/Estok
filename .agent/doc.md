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
    - **F1**: Busca (Foca no campo de pesquisa).
    - **F6**: Finalizar Venda.
    - **F8**: Cancelar Venda.
    - **ENTER**:
        - No campo de busca: Se houver apenas 1 resultado, adiciona direto (Modo Scanner). Se houver lista, seleciona o item.
        - Na tela de venda finalizada: Inicia uma nova venda.
    - **ESC**: Fecha overlay de busca ou cancela ações.
- **Persistência de Estado (Cart)**: O carrinho é mantido ao navegar entre abas (ex: ir ao estoque e voltar), permitindo consultas rápidas sem perder a venda atual.
- **Feedback Visual**: Overlay de busca posicionado com precisão, loading indicators, e tela de sucesso ao finalizar.

### 5. Sincronização em Tempo Real (Event-Driven)
Sistema de notificação global (`EventService`) que mantém todas as telas atualizadas automaticamente.
- **Fluxo de Atualização**:
    - **Venda Realizada**: Ao finalizar uma venda na tela de PDV, um sinal é enviado para recarregar a lista de produtos e a tela de estoque.
    - **Ajuste de Estoque**: Alterações na tela de Estoque ou Cadastro atualizam imediatamente as outras telas.
- **Gestão de Conflitos (Tela de Estoque)**:
    - Se a tela de Estoque receber um sinal de atualização (ex: venda realizada em outra aba) enquanto o usuário estiver editando quantidades (com alterações não salvas), a atualização automática é pausada.
    - Um alerta (Snackbar) informa o usuário: *"Atenção: Movimentações de estoque ocorreram..."*.
    - Isso previne que o trabalho de digitação do usuário seja sobrescrito inesperadamente.


## Regras de Negócio e Detalhes
- **Código Auxiliar**: Facilitador de venda. Deve ser único e curto (3-6 dígitos).
- **Banco de Dados**: Persiste produtos, movimentações e vendas.

### 6. Configuração e Persistência
O sistema permite configuração dinâmica de conexões. 
- **Server Manager**: 
    - Interface: Host, Porta, Usuário, Senha, DB Name, **API Key**.
    - **Lógica de Persistência (Ordem de Prioridade)**:
        1. **`%LOCALAPPDATA%\Estok\db_config.json`**: Configuração personalizada do usuário (criada via GUI).
        2. **`Pasta da Aplicação\db_config.json`**: "Padrão de Fábrica" distribuído com o instalador (editável pelo admin).
        3. **Hardcoded Defaults**: `localhost:5432` / `postgres` / `estok`.
    - **API Key**: Gerada automaticamente na primeira execução se não existir. Necessária para todas as requisições do Client.
    - Codificação: `UTF-8` forçado para suportar senhas com caracteres especiais.
- **Frontend App**:
    - Tela de Configurações (ícone de engrenagem na Home).
    - Permite definir Host, Porta e **API Key** da API Flask.
    - Persiste via `SharedPreferences` (armazenamento nativo do SO).

### 7. Segurança
- **Autenticação**: Todas as chamadas API (exceto OPTIONS e /) exigem o header `X-API-KEY`.
- A chave deve ser copiada do Server Manager e inserida nas configurações do Client.

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
