# Plano de Implementação - Métricas Avançadas do Dashboard

## Objetivo
Adicionar métricas estratégicas ao Dashboard: Valor Total em Estoque (Patrimônio), Ticket Médio e Alertas de Estoque baseados na média de vendas (Smart Alerts).

## Backend (Python - Flask)

### 1. Atualizar `/dashboard/summary` (Ticket Médio)
Adicionar o cálculo de Ticket Médio (`total_vendas / numero_vendas`) para os períodos Hoje, Semana e Mês.
**Novo Retorno:**
```json
{
  "sales": { "today": 1200, "week": 5000, "month": 20000 },
  "profit": { ... },
  "ticket_counts": { "today": 12, "week": 45, "month": 180 }, 
  "average_ticket": { "today": 100, "week": 111, "month": 111 } // Novo
}
```

### 2. Novo Endpoint `/dashboard/inventory-summary`
Retorna o valor financeiro do estoque.
**Retorno:**
```json
{
  "total_cost_value": 50500.00, // Patrimônio (Qtd * Preço Custo)
  "total_sale_potential": 95000.00, // Potencial Bruto (Qtd * Preço Venda)
  "total_items": 1500 // Qtd total de itens físicos
}
```

### 3. Novo Endpoint `/dashboard/smart-alerts`
Identifica produtos com estoque baixo baseado na velocidade de vendas dos últimos 30 dias.
**Lógica:**
1. Calcular `vendas_total_30d` para cada produto.
2. `media_diaria` = `vendas_total_30d / 30`.
3. `dias_cobertura` = `estoque_atual / media_diaria`.
4. Se `dias_cobertura < 7` (menos de uma semana de estoque) E `media_diaria > 0`: Adiciona ao alerta.
**Retorno:**
```json
[
  {
    "id": 10,
    "name": "Cerveja Lata",
    "current_stock": 12,
    "daily_average": 5.0,
    "days_supply": 2.4 // Dura só mais 2 dias!
  }
]
```

## Frontend (Flutter)

### Componentes UI
1.  **Card de Patrimônio**: Exibe "Valor em Estoque" (Custo) e "Potencial de Venda".
2.  **Ticket Médio**: Adicionar essa informação nos cards de Vendas já existentes (ex: uma linha extra "Ticket Médio: R$ 50,00").
3.  **Lista de Alertas Inteligentes**:
    *   Nova seção "Atenção Necessária" ou "Reposição Sugerida".
    *   Lista produtos com baixo `days_supply`, ordenado pela urgência (menor cobertura primeiro).
    *   Visual de alerta (ícone vermelho/laranja).

## Atualização de Documentação
*   Atualizar endpoints em `doc.md` e tarefas em `todo.md`.
