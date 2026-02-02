import requests
import json
import sys

BASE_URL = "http://127.0.0.1:5000"

def log(msg):
    print(f"[TEST] {msg}")

def check_status(response, expected_code):
    if response.status_code != expected_code:
        print(f"FAILED: Expected {expected_code}, got {response.status_code}")
        print(f"Response: {response.text}")
        sys.exit(1)

def test_flow():
    # 1. Create Product
    log("Creating Product...")
    prod_payload = {
        "descricao": "Produto Teste Auto",
        "ean13": "7890000000001",
        "codigo_auxiliar": "TST01",
        "quantidade": 100,
        "preco_custo": 50.00,
        "preco_venda": 100.00
    }
    resp = requests.post(f"{BASE_URL}/products", json=prod_payload)
    check_status(resp, 201)
    data = resp.json()
    product_id = data['id']
    log(f"Product Created: ID={product_id}")

    # 2. Get Products (Search)
    log("Searching Product...")
    resp = requests.get(f"{BASE_URL}/products?q=TST01")
    check_status(resp, 200)
    results = resp.json()['data']
    assert any(p['id'] == product_id for p in results), "Created product not found in search"
    log("Search OK")

    # 3. Update Product
    log("Updating Product...")
    update_payload = {"descricao": "Produto Teste Modificado", "preco_venda": 110.00}
    resp = requests.put(f"{BASE_URL}/products/{product_id}", json=update_payload)
    check_status(resp, 200)
    log("Update OK")

    # 4. Stock Movement (Entry)
    log("Registering Stock Entry...")
    move_payload = {
        "id_produto": product_id,
        "tipo": "ENTRADA",
        "quantidade": 50,
        "observacao": "Reforço de Estoque"
    }
    resp = requests.post(f"{BASE_URL}/estok/movement", json=move_payload)
    check_status(resp, 201)
    new_qty = resp.json()['data']['product']['quantidade']
    log(f"Stock Entry OK. New Qty: {new_qty} (Expected ~150)")

    # 5. Create Sale
    log("Registering Sale...")
    sale_payload = {
        "items": [
            {
                "id_produto": product_id,
                "quantidade": 10,
                "valor_unitario": 110.00
            }
        ],
        "valor_total": 1100.00
    }
    resp = requests.post(f"{BASE_URL}/sales", json=sale_payload)
    check_status(resp, 201)
    sale_id = resp.json()['sale_id']
    log(f"Sale Created OK. Sale ID: {sale_id}")

    log("\nALL TESTS PASSED SUCCESSFULLY!")

if __name__ == "__main__":
    try:
        test_flow()
    except Exception as e:
        print(f"\nEXCEPTION: {e}")
        sys.exit(1)
