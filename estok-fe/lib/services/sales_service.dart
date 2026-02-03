
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import '../models/sale_item.dart';
import 'event_service.dart';

class SalesService {
  String get baseUrl => AppConfig.apiUrl;

  Future<Map<String, dynamic>> registerSale(List<SaleItem> items, double totalValue) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sales'),
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': AppConfig.apiKey,
      },
      body: jsonEncode({
        'items': items.map((e) => e.toJson()).toList(),
        'valor_total': totalValue,
      }),
    );

    if (response.statusCode == 201) {
      EventService().notifyProductUpdate();
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register sale: ${response.statusCode}');
    }
  }
}
