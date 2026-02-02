import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';

class ProductService {
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000';

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products/all'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/products?q=$query'));

    if (response.statusCode == 200) {
       final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search products');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Product.fromJson(body['data']);
    } else {
      throw Exception('Failed to create product');
    }
  }

  Future<Product> updateProduct(Product product) async {
    if (product.id == null) throw Exception('Product ID is required for update');

    final response = await http.put(
      Uri.parse('$baseUrl/products/${product.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      return Product.fromJson(body['data']);
    } else {
      throw Exception('Failed to update product');
    }
  }

  Future<void> adjustStock(int productId, double newQuantity, {String? observation}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/estok/movement'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_produto': productId,
        'tipo': 'AJUSTE',
        'quantidade': newQuantity,
        'observacao': observation ?? 'Ajuste manual via cadastro',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to adjust stock');
    }
  }
}
