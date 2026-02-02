# Schema do Banco de Dados - Estok

**Banco de Dados**: `estok`

## Tabelas

### `produtos`
Armazena o cadastro dos itens.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | SERIAL (PK) | Identificador único |
| `descricao` | VARCHAR(255) | Nome/Descrição do produto |
| `ean13` | VARCHAR(13) | Código de barras (GTIN) |
| `codigo_auxiliar` | VARCHAR(6) | Código curto (3-6 d) para digitação manual |
| `quantidade` | DECIMAL(10,3) | Saldo atual de estoque |
| `preco_custo` | DECIMAL(10,2) | Preço de custo unitário |
| `preco_venda` | DECIMAL(10,2) | Preço unitário de venda |
| `data_cadastro` | TIMESTAMP | Data/Hora de criação do registro |
| `ativo` | BOOLEAN | Flag para soft delete (Default: `true`) |

**Índices Sugeridos:**
- index_ean13 (`ean13`)
- index_codigo_auxiliar (`codigo_auxiliar`)
- index_descricao_trigram (para busca textual eficiente - pg_trgm)

---

### `vendas`
Cabeçalho das vendas realizadas.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | SERIAL (PK) | Identificador da venda |
| `data_venda` | TIMESTAMP | Data e hora da venda |
| `valor_total` | DECIMAL(10,2) | Soma dos itens |

---

### `itens_venda`
Itens individuais de cada venda.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | SERIAL (PK) | ID do item |
| `id_venda` | INTEGER (FK) | Referência à tabela `vendas` |
| `id_produto` | INTEGER (FK) | Referência à tabela `produtos` |
| `quantidade` | DECIMAL(10,3) | Quantidade vendida |
| `preco_custo` | DECIMAL(10,2) | Custo unitário no momento da venda |
| `valor_unitario` | DECIMAL(10,2) | Preço no momento da venda |
| `valor_total` | DECIMAL(10,2) | `quantidade * valor_unitario` |

---

### `movimentacoes_estoque`
Registra todo histórico de giro de estoque (Kardex).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | SERIAL (PK) | Identificador da movimentação |
| `id_produto` | INTEGER (FK) | Referência à tabela `produtos` |
| `tipo` | VARCHAR(20) | Tipo: 'ENTRADA', 'SAIDA', 'AJUSTE', 'VENDA' |
| `quantidade_anterior` | DECIMAL(10,3) | Saldo antes da mov. |
| `quantidade_movimentada` | DECIMAL(10,3) | Qtd adicionada/removida |
| `quantidade_nova` | DECIMAL(10,3) | Saldo final |
| `data_movimentacao` | TIMESTAMP | Data/Hora do registro |
| `id_venda` | INTEGER (FK, NULL) | Link para venda se `tipo='VENDA'` |
| `observacao` | TEXT | Detalhes adicionais |

## Notas
- O campo `quantidade` em `produtos` deve ser decrementado via trigger ou pela aplicação ao registrar uma venda.
- O código auxiliar não deve colidir com códigos de barras.
