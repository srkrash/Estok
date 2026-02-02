from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import or_, case, func, desc, extract
import os
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
# Fallback to a default for development if not set
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/estok')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    "connect_args": {"client_encoding": "utf8"}
}

db = SQLAlchemy(app)

# --- Models ---

class Produto(db.Model):
    __tablename__ = 'produtos'

    id = db.Column(db.Integer, primary_key=True)
    descricao = db.Column(db.String(255), nullable=False)
    ean13 = db.Column(db.String(13))
    codigo_auxiliar = db.Column(db.String(6))
    quantidade = db.Column(db.Numeric(10, 3), default=0)
    preco_custo = db.Column(db.Numeric(10, 2))
    preco_venda = db.Column(db.Numeric(10, 2))
    data_cadastro = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    ativo = db.Column(db.Boolean, default=True)

    def to_dict(self):
        return {
            'id': self.id,
            'descricao': self.descricao,
            'ean13': self.ean13,
            'codigo_auxiliar': self.codigo_auxiliar,
            'quantidade': float(self.quantidade) if self.quantidade is not None else 0.0,
            'preco_custo': float(self.preco_custo) if self.preco_custo is not None else 0.0,
            'preco_venda': float(self.preco_venda) if self.preco_venda is not None else 0.0,
            'data_cadastro': self.data_cadastro.isoformat() if self.data_cadastro else None,
            'ativo': self.ativo
        }

class MovimentacaoEstoque(db.Model):
    __tablename__ = 'movimentacoes_estoque'

    id = db.Column(db.Integer, primary_key=True)
    id_produto = db.Column(db.Integer, db.ForeignKey('produtos.id'), nullable=False)
    tipo = db.Column(db.String(20), nullable=False) # 'ENTRADA', 'SAIDA', 'AJUSTE', 'VENDA'
    quantidade_anterior = db.Column(db.Numeric(10, 3))
    quantidade_movimentada = db.Column(db.Numeric(10, 3))
    quantidade_nova = db.Column(db.Numeric(10, 3))
    data_movimentacao = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    id_venda = db.Column(db.Integer, nullable=True) # Optional FK to sales if we implement it later
    observacao = db.Column(db.Text, nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'id_produto': self.id_produto,
            'tipo': self.tipo,
            'quantidade_anterior': float(self.quantidade_anterior) if self.quantidade_anterior is not None else 0.0,
            'quantidade_movimentada': float(self.quantidade_movimentada) if self.quantidade_movimentada is not None else 0.0,
            'quantidade_nova': float(self.quantidade_nova) if self.quantidade_nova is not None else 0.0,
            'data_movimentacao': self.data_movimentacao.isoformat() if self.data_movimentacao else None,
            'observacao': self.observacao
        }

class Venda(db.Model):
    __tablename__ = 'vendas'

    id = db.Column(db.Integer, primary_key=True)
    data_venda = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    valor_total = db.Column(db.Numeric(10, 2))

    # Relationship to Items
    items = db.relationship('ItemVenda', backref='venda', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'data_venda': self.data_venda.isoformat() if self.data_venda else None,
            'valor_total': float(self.valor_total) if self.valor_total is not None else 0.0,
            'items': [item.to_dict() for item in self.items]
        }

class ItemVenda(db.Model):
    __tablename__ = 'itens_venda'

    id = db.Column(db.Integer, primary_key=True)
    id_venda = db.Column(db.Integer, db.ForeignKey('vendas.id'), nullable=False)
    id_produto = db.Column(db.Integer, db.ForeignKey('produtos.id'), nullable=False)
    quantidade = db.Column(db.Numeric(10, 3), nullable=False)
    preco_custo = db.Column(db.Numeric(10, 2))
    valor_unitario = db.Column(db.Numeric(10, 2), nullable=False)
    valor_total = db.Column(db.Numeric(10, 2), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'id_venda': self.id_venda,
            'id_produto': self.id_produto,
            'quantidade': float(self.quantidade),
            'preco_custo': float(self.preco_custo) if self.preco_custo else 0.0,
            'valor_unitario': float(self.valor_unitario),
            'valor_total': float(self.valor_total)
        }

# --- Product Routes ---

@app.route('/products/all', methods=['GET'])
def get_all_products():
    """
    Get ALL products without pagination or strict limits.
    Designed for management screens (Product Registration/Stock Management).
    """
    try:
        products = Produto.query.filter(Produto.ativo == True).order_by(Produto.descricao).all()
        return jsonify({
            "message": "All products retrieved",
            "count": len(products),
            "data": [p.to_dict() for p in products]
        })
    except Exception as e:
        return jsonify({"message": f"Error retrieving products: {str(e)}"}), 500

@app.route('/products', methods=['GET'])
def get_products():
    """
    Search products with optimized 'search-as-you-type' logic.
    Query Params:
        q: Search term (name, ean, or aux code)
    Returns:
        Max 20 results ordered by relevance:
        1. Exact match (EAN13 or Aux Code)
        2. Description starts with term
        3. Description contains term
    """
    query_term = request.args.get('q', '').strip()
    
    query = Produto.query.filter(Produto.ativo == True)

    if query_term:
        search_pattern = f"%{query_term}%"
        prefix_pattern = f"{query_term}%"

        # Filter: Matches one of the fields
        query = query.filter(
            or_(
                Produto.descricao.ilike(search_pattern),
                Produto.ean13 == query_term,
                Produto.codigo_auxiliar == query_term
            )
        )
        
        # Ordering Priorities
        # 1. Exact Match on Code (EAN or Aux)
        # 2. Description Starts With (Prefix)
        # 3. Description Contains (implied by previous filter, but we push it to end)
        query = query.order_by(
            case(
                (Produto.ean13 == query_term, 1),
                (Produto.codigo_auxiliar == query_term, 1),
                (Produto.descricao.ilike(prefix_pattern), 2),
                else_=3
            ),
            Produto.descricao # Secondary sort alpha
        )
    else:
        query = query.order_by(Produto.descricao)
    
    # Limit results for performance (Sales Screen Optimization)
    products = query.limit(20).all()
    
    return jsonify({
        "message": "Search results",
        "count": len(products),
        "data": [p.to_dict() for p in products]
    })

@app.route('/products', methods=['POST'])
def create_product():
    """
    Create a new product.
    Body: JSON with product details.
    """
    data = request.json
    if not data:
        return jsonify({"message": "No input data provided"}), 400

    try:
        new_product = Produto(
            descricao=data.get('descricao'),
            ean13=data.get('ean13'),
            codigo_auxiliar=data.get('codigo_auxiliar'),
            quantidade=data.get('quantidade', 0),
            preco_custo=data.get('preco_custo'),
            preco_venda=data.get('preco_venda')
        )
        
        db.session.add(new_product)
        db.session.commit()

        return jsonify({
            "message": "Product created successfully",
            "data": new_product.to_dict(),
            "id": new_product.id
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": f"Error creating product: {str(e)}"}), 500

@app.route('/products/<int:id>', methods=['PUT'])
def update_product(id):
    """
    Update product details.
    """
    product = db.session.get(Produto, id)
    if not product:
         return jsonify({"message": "Product not found"}), 404

    data = request.json

    if not data:
        return jsonify({"message": "No input data provided"}), 400

    try:
        if 'descricao' in data:
            product.descricao = data['descricao']
        if 'ean13' in data:
            product.ean13 = data['ean13']
        if 'codigo_auxiliar' in data:
            product.codigo_auxiliar = data['codigo_auxiliar']
        if 'quantidade' in data:
            product.quantidade = data['quantidade']
        if 'preco_custo' in data:
            product.preco_custo = data['preco_custo']
        if 'preco_venda' in data:
            product.preco_venda = data['preco_venda']
        if 'ativo' in data:
            product.ativo = data['ativo']

        db.session.commit()

        return jsonify({
            "message": f"Product {id} updated successfully",
            "data": product.to_dict()
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": f"Error updating product: {str(e)}"}), 500

# --- Stock Routes ---

@app.route('/estok/movement', methods=['POST'])
def stock_movement():
    """
    Register a stock movement (entry, exit, adjustment).
    Body:
        id_produto: int
        tipo: 'ENTRADA' | 'SAIDA' | 'AJUSTE'
        quantidade: float
        observacao: str (optional)
    """
    data = request.json
    if not data:
        return jsonify({"message": "No input data provided"}), 400

    id_produto = data.get('id_produto')
    tipo = data.get('tipo', '').upper()
    try:
        quantidade = float(data.get('quantidade', 0))
    except (ValueError, TypeError):
         return jsonify({"message": "Invalid quantity"}), 400

    observacao = data.get('observacao')

    if not id_produto or tipo not in ['ENTRADA', 'SAIDA', 'AJUSTE']:
        return jsonify({"message": "Invalid input: id_produto and valid tipo required"}), 400

    try:
        product = db.session.get(Produto, id_produto)
        if not product:
            return jsonify({"message": "Product not found"}), 404

        qtd_anterior = float(product.quantidade) if product.quantidade is not None else 0.0
        qtd_movimentada = 0.0
        qtd_nova = 0.0

        if tipo == 'ENTRADA':
            qtd_movimentada = abs(quantidade)
            qtd_nova = qtd_anterior + qtd_movimentada
        elif tipo == 'SAIDA':
            qtd_movimentada = -abs(quantidade)
            qtd_nova = qtd_anterior + qtd_movimentada # Adding a negative number
        elif tipo == 'AJUSTE':
            # AJUSTE: The input quantity is the NEW target quantity (Replacement)
            qtd_nova = quantidade
            qtd_movimentada = qtd_nova - qtd_anterior

        # Update Product
        product.quantidade = qtd_nova

        # Create Movement Record
        mov = MovimentacaoEstoque(
            id_produto=id_produto,
            tipo=tipo,
            quantidade_anterior=qtd_anterior,
            quantidade_movimentada=qtd_movimentada,
            quantidade_nova=qtd_nova,
            observacao=observacao
        )

        db.session.add(mov)
        db.session.commit()

        return jsonify({
            "message": "Stock movement registered successfully",
            "data": {
                "product": product.to_dict(),
                "movement": mov.to_dict()
            }
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"message": f"Error registering movement: {str(e)}"}), 500

# --- Dashboard Routes ---

@app.route('/dashboard/summary', methods=['GET'])
def get_dashboard_summary():
    """
    Get Sales and Profit summary for Day, Week, and Month.
    """
    try:
        now = datetime.now(timezone.utc)
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        week_start = today_start - timedelta(days=7) # Last 7 days
        month_start = today_start.replace(day=1) # Current Month

        def calculate_metrics(start_date):
            # Sales Total and Count
            sales_data = db.session.query(
                func.sum(Venda.valor_total),
                func.count(Venda.id)
            ).filter(Venda.data_venda >= start_date).first()
            
            sales_sum = sales_data[0] or 0.0
            sales_count = sales_data[1] or 0.0
            
            # Profit Total: Sum((price - cost) * qty)
            profit_sum = db.session.query(
                func.sum((ItemVenda.valor_unitario - ItemVenda.preco_custo) * ItemVenda.quantidade)
            ).join(Venda).filter(Venda.data_venda >= start_date).scalar() or 0.0

            return float(sales_sum), float(profit_sum), int(sales_count)

        day_sales, day_profit, day_count = calculate_metrics(today_start)
        week_sales, week_profit, week_count = calculate_metrics(week_start)
        month_sales, month_profit, month_count = calculate_metrics(month_start)

        return jsonify({
            "sales": {
                "today": day_sales,
                "week": week_sales,
                "month": month_sales
            },
            "profit": {
                "today": day_profit,
                "week": week_profit,
                "month": month_profit
            },
            "average_ticket": {
                "today": day_sales / day_count if day_count > 0 else 0,
                "week": week_sales / week_count if week_count > 0 else 0,
                "month": month_sales / month_count if month_count > 0 else 0
            }
        })

    except Exception as e:
        return jsonify({"message": f"Error loading dashboard summary: {str(e)}"}), 500

@app.route('/dashboard/recent-sales', methods=['GET'])
def get_recent_sales():
    """
    Get last 5 sales.
    """
    try:
        recent_sales = Venda.query.order_by(Venda.data_venda.desc()).limit(5).all()
        # Enrich with item count
        result = []
        for sale in recent_sales:
             s_dict = sale.to_dict()
             s_dict['items_count'] = len(sale.items)
             # Simplify items for payload size if needed, but keeping full obj is fine for 5 items
             result.append(s_dict)
        
        return jsonify(result)
    except Exception as e:
         return jsonify({"message": f"Error loading recent sales: {str(e)}"}), 500

@app.route('/dashboard/top-products', methods=['GET'])
def get_top_products():
    """
    Get top 5 best selling products in the last 7 days.
    """
    try:
        now = datetime.now(timezone.utc)
        week_start = now - timedelta(days=7)

        # Query: Sum quantity grouped by Product, ordered by Sum Desc
        results = db.session.query(
            Produto.id,
            Produto.descricao,
            func.sum(ItemVenda.quantidade).label('total_qty')
        ).join(ItemVenda, Produto.id == ItemVenda.id_produto)\
         .join(Venda, ItemVenda.id_venda == Venda.id)\
         .filter(Venda.data_venda >= week_start)\
         .group_by(Produto.id)\
         .order_by(desc('total_qty'))\
         .limit(5).all()

        data = []
        for pid, name, qty in results:
            data.append({
                "id": pid,
                "name": name,
                "quantity_sold": float(qty)
            })
            
        return jsonify(data)

    except Exception as e:
        return jsonify({"message": f"Error loading top products: {str(e)}"}), 500

@app.route('/dashboard/inventory-summary', methods=['GET'])
def get_inventory_summary():
    """
    Get Total Inventory Value (Cost) and Sale Potential.
    """
    try:
        # Sum(qty * cost) and Sum(qty * price) for active products
        metrics = db.session.query(
            func.sum(Produto.quantidade * Produto.preco_custo),
            func.sum(Produto.quantidade * Produto.preco_venda),
            func.sum(Produto.quantidade)
        ).filter(Produto.ativo == True).first()

        total_cost = metrics[0] or 0.0
        total_price = metrics[1] or 0.0
        total_items = metrics[2] or 0.0

        return jsonify({
            "total_cost_value": float(total_cost),
            "total_sale_potential": float(total_price),
            "total_items": float(total_items)
        })
    except Exception as e:
        return jsonify({"message": f"Error loading inventory summary: {str(e)}"}), 500

@app.route('/dashboard/smart-alerts', methods=['GET'])
def get_smart_alerts():
    """
    Get products with low stock based on sales velocity (last 30 days coverage < 7 days).
    """
    try:
        now = datetime.now(timezone.utc)
        start_30d = now - timedelta(days=30)
        
        # 1. Get Sales Volume per Product (Last 30 days)
        # We need a subquery for this Aggregation
        sales_subquery = db.session.query(
            ItemVenda.id_produto,
            func.sum(ItemVenda.quantidade).label('sold_30d')
        ).join(Venda).filter(Venda.data_venda >= start_30d)\
         .group_by(ItemVenda.id_produto).subquery()

        # 2. Join with Products and Filter
        # Select products where: stock / (sold_30d / 30) < 7
        # Equivalent to: stock * 30 / sold_30d < 7
        # Or more simply: sold/30 = daily_rate. days_coverage = stock / daily_rate.
        
        products = db.session.query(
            Produto,
            sales_subquery.c.sold_30d
        ).outerjoin(sales_subquery, Produto.id == sales_subquery.c.id_produto)\
         .filter(Produto.ativo == True)\
         .filter(Produto.quantidade > 0).all() # Only care about items we actually have or are tracking? 
         # Actually we care about items that are Running Out. If qty=0, coverage is 0. 
        
        alerts = []
        for product, sold_30d in products:
            qty = float(product.quantidade or 0)
            sold = float(sold_30d or 0)
            
            if sold <= 0:
                continue # No sales, infinite coverage (or stagnant stock, different problem)

            daily_avg = sold / 30.0
            days_coverage = qty / daily_avg
            
            if days_coverage < 7.0:
                alerts.append({
                    "id": product.id,
                    "name": product.descricao,
                    "current_stock": qty,
                    "daily_average": daily_avg,
                    "days_supply": days_coverage
                })
        
        # Sort by most critical (lowest days supply)
        alerts.sort(key=lambda x: x['days_supply'])
        
        return jsonify(alerts)

    except Exception as e:
        return jsonify({"message": f"Error loading smart alerts: {str(e)}"}), 500

# --- Sales Routes ---

@app.route('/sales', methods=['POST'])
def create_sale():
    """
    Register a finalized sale.
    Body:
        items: List of objects {id_produto, quantidade, valor_unitario}
        valor_total: float
    """
    data = request.json
    if not data or 'items' not in data:
        return jsonify({"message": "Invalid data: 'items' list is required"}), 400

    items_data = data.get('items', [])
    if not items_data:
         return jsonify({"message": "Items list cannot be empty"}), 400

    try:
        # 1. Create Sale Header
        # We can calculate total from items or trust the frontend. 
        # Usually safer to calculate or validate. For now, we accept what comes or calc sum.
        # Let's verify the total provided matches the sum (optional but good).
        # For simplicity, let's sum up the items' totals.
        
        calculated_total = 0.0
        
        # We need to process items first to check validity, but we need Sale ID for FK.
        # So we add Sale first, flush to get ID, then items.
        
        new_sale = Venda(
            data_venda=datetime.now(timezone.utc),
            valor_total=0 # Will update after summing items
        )
        db.session.add(new_sale)
        db.session.flush() # Get ID

        sale_items = []

        for item in items_data:
            prod_id = item.get('id_produto')
            qtd = float(item.get('quantidade', 0))
            val_unit = float(item.get('valor_unitario', 0))
            
            if qtd <= 0:
                raise ValueError(f"Quantity for product {prod_id} must be positive")

            product = db.session.get(Produto, prod_id)
            if not product:
                 raise ValueError(f"Product ID {prod_id} not found")
            
            # Cost at moment of sale
            cost_price = float(product.preco_custo) if product.preco_custo else 0.0
            
            item_total = qtd * val_unit
            calculated_total += item_total

            # 2. Create Item Record
            new_item = ItemVenda(
                id_venda=new_sale.id,
                id_produto=product.id,
                quantidade=qtd,
                preco_custo=cost_price,
                valor_unitario=val_unit,
                valor_total=item_total
            )
            db.session.add(new_item)
            sale_items.append(new_item)

            # 3. Update Stock (Decrement)
            old_qty = float(product.quantidade) if product.quantidade else 0.0
            new_qty = old_qty - qtd
            product.quantidade = new_qty
            
            # 4. Create Movement Record (Kardex)
            mov = MovimentacaoEstoque(
                id_produto=product.id,
                tipo='VENDA',
                quantidade_anterior=old_qty,
                quantidade_movimentada=-qtd, # Negative for exit
                quantidade_nova=new_qty,
                data_movimentacao=datetime.now(timezone.utc),
                id_venda=new_sale.id,
                observacao=f"Venda #{new_sale.id}"
            )
            db.session.add(mov)

        # Update Sale with final total
        given_total = float(data.get('valor_total', 0))
        # Optional: Compare given_total vs calculated_total logic? 
        # For now, let's use the calculated one to ensure consistency or the given one if we trust frontend.
        # Let's trust logic:
        new_sale.valor_total = calculated_total

        db.session.commit()

        return jsonify({
            "message": "Sale registered successfully",
            "sale_id": new_sale.id,
            "items_count": len(sale_items),
            "total_value": calculated_total
        }), 201

    except ValueError as ve:
        db.session.rollback()
        return jsonify({"message": str(ve)}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": f"Error registering sale: {str(e)}"}), 500

@app.route('/')
def hello():
    return "Hello from Estok API!"

if __name__ == '__main__':
    app.run(debug=True)
