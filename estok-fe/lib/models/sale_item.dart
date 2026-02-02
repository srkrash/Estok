
import 'product.dart';

class SaleItem {
  final Product product;
  double quantity;
  double unitPrice;

  SaleItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'id_produto': product.id,
      'quantidade': quantity,
      'valor_unitario': unitPrice,
    };
  }
}
