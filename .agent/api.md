# Documentação da API Estok

URL Base: `http://localhost:5000` (padrão Flask)

Esta documentação descreve os endpoints disponíveis para integração com o Frontend.

## Produtos

### 1. Listar / Buscar Produtos
### 1. Listar / Buscar Produtos
Retorna uma lista de produtos cadastrados. Permite filtragem por termo de busca.
*Ideal para PDV/Vendas (Resultados limitados).*

- **Método:** `GET`
- **URL:** `/products`
- **Parâmetros de Query:**
    - `q` (opcional): Termo para busca textual. Pesquisa em: `descricao`, `ean13` e `codigo_auxiliar`.

**Exemplo de Requisição:**
```http
GET /products?q=cocacola
```

**Exemplo de Resposta (200 OK):**
```json
{
  "message": "Search results",
  "count": 2,
  "data": [
    ...
  ]
}
```

---

### 1.1 Listar TODOS os Produtos
Retorna a lista completa de produtos ativos, sem paginação.
*Ideal para telas de gerenciamento e tabelas.*

- **Método:** `GET`
- **URL:** `/products/all`

**Exemplo de Resposta (200 OK):**
```json
{
  "message": "All products retrieved",
  "count": 150,
  "data": [ ... ]
}
```

---

### 2. Cadastrar Produto
Cria um novo registro de produto no sistema.

- **Método:** `POST`
- **URL:** `/products`
- **Body (JSON):**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `descricao` | String | Sim | Nome do produto |
| `ean13` | String | Não | Código de barras (13 dígitos) |
| `codigo_auxiliar` | String | Não | Código curto para venda rápida |
| `quantidade` | Number | Não | Estoque inicial (padrão: 0) |
| `preco_custo` | Number | Não | Preço de custo |
| `preco_venda` | Number | Não | Preço de venda |

**Exemplo de Body:**
```json
{
  "descricao": "Produto Novo",
  "ean13": "1234567890123",
  "codigo_auxiliar": "505",
  "quantidade": 10,
  "preco_custo": 15.00,
  "preco_venda": 30.00
}
```

**Exemplo de Resposta (201 Created):**
```json
{
  "message": "Product created successfully",
  "id": 15,
  "data": { ... } // Objeto do produto criado
}
```

---

### 3. Atualizar Produto
Atualiza dados de um produto existente. Envie apenas os campos que deseja alterar.

- **Método:** `PUT`
- **URL:** `/products/{id}`
- **Parâmetros de URL:**
    - `id`: ID numérico do produto.
- **Body (JSON):** Aceita os mesmos campos do cadastro.

**Exemplo de Body:**
```json
{
  "descricao": "Produto Editado",
  "preco_venda": 35.00
}
```

**Exemplo de Resposta (200 OK):**
```json
{
  "message": "Product 15 updated successfully",
  "data": { ... } // Objeto do produto atualizado
}
```

---

## Estoque

### 4. Movimentação de Estoque
Registra entradas, saídas ou ajustes manuais no estoque.

- **Método:** `POST`
- **URL:** `/estok/movement`
- **Body (JSON):**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `id_produto` | Integer | Sim | ID do produto a movimentar |
| `tipo` | String | Sim | Tipo de operação: `ENTRADA`, `SAIDA` ou `AJUSTE` |
| `quantidade` | Number | Sim | Valor da movimentação |
| `observacao` | String | Não | Nota explicativa sobre a operação |

**Comportamento por Tipo:**
- **ENTRADA:** Acrescenta a quantidade ao estoque atual.
- **SAIDA:** Subtrai a quantidade do estoque atual.
- **AJUSTE:** **Substitui** o estoque atual pela quantidade informada.

**Exemplo de Body:**
```json
{
  "id_produto": 1,
  "tipo": "ENTRADA",
  "quantidade": 50,
  "observacao": "Compra de reposição NF 123"
}
```

**Exemplo de Resposta (201 Created):**
```json
{
  "message": "Stock movement registered successfully",
  "data": {
    "product": {
      "id": 1,
      "quantidade": 100.0,
      ...
    },
    "movement": {
      "id": 10,
      "tipo": "ENTRADA",
      "quantidade_anterior": 50.0,
      "quantidade_movimentada": 50.0,
      "quantidade_nova": 100.0,
      ...
    }
  }
}
```

---

## Vendas

### 5. Registrar Venda
Processa uma venda completa, baixa o estoque de múltiplos itens e gera o histórico.

- **Método:** `POST`
- **URL:** `/sales`
- **Body (JSON):**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `items` | Array | Sim | Lista de itens vendidos |
| `valor_total` | Number | Não | Valor total da venda (opcional, recalculado pelo backend) |

**Estrutura de um Item:**
`{ "id_produto": 1, "quantidade": 2, "valor_unitario": 10.00 }`

**Exemplo de Body:**
```json
{
  "items": [
    {
      "id_produto": 1,
      "quantidade": 10,
      "valor_unitario": 5.50
    },
    {
      "id_produto": 2,
      "quantidade": 1,
      "valor_unitario": 100.00
    }
  ]
}
```

**Exemplo de Resposta (201 Created):**
```json
{
  "message": "Sale registered successfully",
  "sale_id": 55,
  "items_count": 2,
  "total_value": 155.00
}
```
