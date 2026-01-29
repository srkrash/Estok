import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_get_products():
    print("Testing GET /products...")
    response = requests.get(f"{BASE_URL}/products?q=test")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 200

def test_create_product():
    print("\nTesting POST /products...")
    payload = {"description": "New Prod", "ean13": "123", "qtd": 100}
    response = requests.post(f"{BASE_URL}/products", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 201

def test_update_product():
    print("\nTesting PUT /products/1...")
    payload = {"description": "Updated Prod"}
    response = requests.put(f"{BASE_URL}/products/1", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 200

def test_stock_movement():
    print("\nTesting POST /stock/movement...")
    payload = {"id_produto": 1, "tipo": "ENTRADA", "quantidade": 10}
    response = requests.post(f"{BASE_URL}/stock/movement", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 201

def test_create_sale():
    print("\nTesting POST /sales...")
    payload = {"items": [{"id_produto": 1, "qty": 1}], "valor_total": 50}
    response = requests.post(f"{BASE_URL}/sales", json=payload)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    assert response.status_code == 201

if __name__ == "__main__":
    try:
        test_get_products()
        test_create_product()
        test_update_product()
        test_stock_movement()
        test_create_sale()
        print("\nAll tests passed!")
    except Exception as e:
        print(f"\nTest failed: {e}")
