<div align="center">
  <img src="https://i.imgur.com/S4ZKxkx.png" alt="Estok Logo" width="150"/>
  <h1>Estok</h1>
</div>

Estok - Sistema de Controle de Estoque e Vendas


![Status](https://img.shields.io/badge/Status-Desenvolvimento-green)
![Version](https://img.shields.io/badge/Versão-0.1.0-blue)
![Stack](https://img.shields.io/badge/Stack-Flutter%20%7C%20Flask%20%7C%20PostgreSQL-orange)

**Estok** é uma solução robusta e moderna para controle de estoque e vendas, projetada para desktop Windows. Combinando a agilidade do **Flutter** no frontend e a flexibilidade do **Python (Flask)** no backend, o sistema oferece uma experiência de usuário fluida, responsiva e focada em performance.

## 🚀 Visão Geral

O sistema opera em uma arquitetura híbrida standalone:
*   **Servidor Local**: Uma API RESTful em Flask e banco de dados PostgreSQL rodam localmente na máquina do cliente, gerenciados por um *Server Manager* com ícone na bandeja do sistema.
*   **Cliente Desktop**: Interface desenvolvida em Flutter, comunicando-se via HTTP com o servidor local.

## ✨ Funcionalidades Principais

### 📊 Dashboard Inteligente
*   **KPIs em Tempo Real**: Vendas do dia, semana e mês, lucro estimado e ticket médio.
*   **Smart Alerts**: Monitoramento de saldo de estoque, alertando para produtos com cobertura menor que 7 dias (baseado na média de vendas dos últimos 30 dias).
*   **Top Produtos**: Visualização rápida dos itens mais vendidos.

![Dashboard](https://i.imgur.com/LXYG9JF.png)


### 📦 Gestão de Produtos
*   **Cadastro Completo**: Suporte a código de barras (EAN13) e código auxiliar curto (3-6 dígitos).
*   **Edição em Massa**: Interface tabular ("Excel-like") para ajustes rápidos de estoque, com proteção contra perda de dados não salvos.
*   **Design Responsivo**: Formulários que se adaptam a diferentes tamanhos de janela (80% a 100% de largura).

![Lista de Produtos](https://i.imgur.com/MgfprAC.png)
![Formulário de Produto](https://i.imgur.com/9VWJkNg.png)
![Atualização em Lote](https://i.imgur.com/0aV9vD0.png)


### 🛒 Ponto de Venda (PDV)
*   **Foco na Agilidade**: Projetado para operação rápida com atalhos de teclado (`F1` Busca, `F6` Finalizar, `F8` Cancelar).
*   **Busca "Type-Ahead"**: Pesquisa instantânea por nome ou código a cada letra digitada.
*   **Entrada Inteligente**: Reconhece comandos multiplicadores (ex: `5*AGUA`) para adicionar múltiplos itens.
*   **Multitarefa**: O carrinho de vendas persiste ao navegar entre outras abas do sistema.

![Ponto de Venda](https://i.imgur.com/DuLX7ow.png)


### 🔄 Sincronização em Tempo Real
*   Sistema orientado a eventos que mantém todas as telas sincronizadas.
*   Uma venda realizada no PDV atualiza imediatamente a listagem de estoque e o dashboard, sem necessidade de refresh manual.

### ⚙️ Server Manager & Configuração
*   Aplicativo de bandeja para gerenciar o servidor Flask.
*   Configuração dinâmica de conexão com o banco de dados via interface gráfica, persistindo preferências em JSON.

![Server Manager](https://i.imgur.com/zhG0RBj.png)


## 🛠️ Stack Tecnológico

| Componente | Tecnologia | Detalhes |
| :--- | :--- | :--- |
| **Frontend** | [Flutter](https://flutter.dev) | Windows Desktop, Design Material 3 |
| **Backend** | [Python Flask](https://flask.palletsprojects.com) | REST API, SQLAlchemy |
| **Banco de Dados** | [PostgreSQL](https://www.postgresql.org) | Relacional, robusto e escalável |
| **Instalador** | Inno Setup | Empacotamento profissional para Windows |

## 💻 Instalação e Execução (Desenvolvimento)

Para rodar o projeto em ambiente de desenvolvimento:

### Pré-requisitos
*   [Python 3.10+](https://www.python.org/)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   [PostgreSQL](https://www.postgresql.org/download/)

### 1. Banco de Dados
Crie um banco de dados chamado `estok` e execute o script de inicialização:
```bash
psql -U postgres -d estok -f estok-db/schema.sql
```

### 2. Backend (Flask)
```bash
cd estok-py
# Criar e ativar virtualenv
python -m venv venv
.\venv\Scripts\activate

# Instalar dependências
pip install -r requirements.txt

# Rodar servidor
python main.py
```
> O servidor rodará em `http://127.0.0.1:5000`

### 3. Frontend (Flutter)
```bash
cd estok-fe
flutter pub get
flutter run -d windows
```

## 📦 Build & Deploy

Instruções para gerar os executáveis de produção.

### Backend
Dentro do ambiente virtual:
```bash
cd estok-py
pyinstaller --noconsole --onefile --name estok-server --add-data "logo_green.ico;." --add-data "logo_green_tray.png;." server_gui.py
```

### Frontend
```bash
cd estok-fe
flutter build windows --release
```

### Instalador
Utilize o script `estok_installer.iss` com o **Inno Setup** para compilar o instalador único que configura o ambiente e cria os atalhos.

## 📂 Estrutura do Projeto

*   `estok-fe/`: Código fonte Flutter (Interface).
*   `estok-py/`: Código fonte Python (API e Tray App).
*   `estok-db/`: Scripts SQL e migracoes.
*   `.agent/`: Documentação interna e logs de desenvolvimento.

---
*Desenvolvido com foco em eficiência e usabilidade.*
