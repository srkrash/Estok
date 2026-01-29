from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# --- Product Routes ---

@app.route('/products', methods=['GET'])
def get_products():
    """
    Search products.
    Query Params:
        q: Search term (name, ean, or aux code)
    """
    query = request.args.get('q', '')
    # Mock response
    return jsonify({
        "message": "Search products",
        "query": query,
        "data": [
            {"id": 1, "description": "Produto Teste 1", "ean13": "7891234567890", "qtd": 10},
            {"id": 2, "description": "Produto Teste 2", "ean13": "7890987654321", "qtd": 5}
        ]
    })

@app.route('/products', methods=['POST'])
def create_product():
    """
    Create a new product.
    Body: JSON with product details.
    """
    data = request.json
    # Mock response
    return jsonify({
        "message": "Product created successfully",
        "data": data,
        "id": 123  # Mock ID
    }), 201

@app.route('/products/<int:id>', methods=['PUT'])
def update_product(id):
    """
    Update product details.
    """
    data = request.json
    return jsonify({
        "message": f"Product {id} updated successfully",
        "data": data
    })

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
    return jsonify({
        "message": "Stock movement registered",
        "data": data
    }), 201

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
    # Mock processing
    return jsonify({
        "message": "Sale registered successfully",
        "sale_id": 999,
        "items_count": len(data.get('items', []))
    }), 201

@app.route('/')
def hello():
    return "Hello from Estok API!"

if __name__ == '__main__':
    app.run(debug=True)
