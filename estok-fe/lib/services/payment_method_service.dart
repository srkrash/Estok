import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/payment_method.dart';

class PaymentMethodService {
  String get baseUrl => AppConfig.apiUrl;

  Future<List<PaymentMethod>> getPaymentMethods({bool activeOnly = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payment-methods?active_only=$activeOnly'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => PaymentMethod.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payment methods: ${response.statusCode}');
    }
  }

  Future<PaymentMethod> savePaymentMethod(PaymentMethod method) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment-methods'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(method.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return PaymentMethod.fromJson(data['data']);
    } else {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['message'] ?? 'Failed to save payment method');
    }
  }

  Future<bool> deletePaymentMethod(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/payment-methods/$id'),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(data['message'] ?? 'Failed to delete payment method');
    }
  }
}
