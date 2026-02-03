# Estok

Sistema de controle de estoque e vendas desenvolvido para desktop Windows, com foco em simplicidade e performance. O projeto utiliza uma arquitetura híbrida com **Flutter** no frontend e **Python (Flask)** no backend.

## Funcionalidades

- **Gestão de Produtos**: Cadastro detalhado com suporte a código de barras (EAN13) e códigos auxiliares.
- **Movimentação de Estoque**: Registros automáticos de entrada, saída e ajustes.
- **Interface Responsiva**: Design adaptável que flui entre 80% e 100% da largura da tela.
- **Navegação em Abas**: Multitarefa eficiente permitindo alternar entre módulos sem perder o contexto.
- **Busca Inteligente**: Pesquisa de produtos otimizada ("type-ahead") por nome ou código.

## Tecnologias

- **Frontend**: [Flutter](https://flutter.dev) (Windows Desktop)
- **Backend**: [Python Flask](https://flask.palletsprojects.com)
- **Banco de Dados**: [PostgreSQL](https://www.postgresql.org)

## Estrutura do Projeto

- `estok-fe/`: Código fonte do frontend em Flutter.
- `estok-py/`: API RESTful em Python/Flask.
- `estok-db/`: Scripts de inicialização e schema do banco de dados.

## Como Rodar

### Pré-requisitos
- Python 3.x
- Flutter SDK
- PostgreSQL instalado e rodando

### 1. Configurar Banco de Dados
Crie um banco de dados chamado `estok` e execute o script de schema:
```bash
psql -U postgres -d estok -f estok-db/schema.sql
```

### 2. Executar Backend
```bash
cd estok-py
# Crie e ative um ambiente virtual (opcional mas recomendado)
python -m venv venv
# Windows:
.\venv\Scripts\activate
# Instale as dependências
pip install -r requirements.txt
# Execute o servidor
python main.py
```

### 3. Executar Frontend
```bash
cd estok-fe
flutter pub get
flutter run -d windows
```

## Configuração

O sistema permite a configuração dinâmica das conexões, sem necessidade de alterar código:

### Backend (Server Manager)
- Ao iniciar o servidor (`estok-server.exe`), utilize a interface gráfica para definir:
  - **Host, Porta, Usuário, Senha e Nome do Banco**: Credenciais do PostgreSQL.
- As configurações são salvas automaticamente em:
  - `%LOCALAPPDATA%\Estok\db_config.json` (Prioritário - Usuário)
  - `Pasta de Instalação\db_config.json` (Padrão de Fábrica)

### Frontend (Client)
- No aplicativo (`stock_fe.exe`), acesse o ícone de engrenagem no canto superior direito.
- Defina o **IP do Servidor** e a **Porta** (padrão 5000).
- As configurações são persistidas localmente no dispositivo.

## Roadmap

Os próximos passos do desenvolvimento incluem:
- **Atualização em Lote**: Interface estilo planilha para ajustes rápidos de estoque.
- **PDV (Ponto de Venda)**: Frente de caixa com atalhos de teclado e fluxo de venda ágil.
- **Distribuição**: Empacotamento em executáveis (.exe) já implementado.
