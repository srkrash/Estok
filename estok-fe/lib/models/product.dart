class Product {
  final int? id;
  final String description;
  final String? ean13;
  final String? auxCode;
  final double quantity;
  final double? costPrice;
  final double? salePrice;

  Product({
    this.id,
    required this.description,
    this.ean13,
    this.auxCode,
    this.quantity = 0.0,
    this.costPrice,
    this.salePrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      description: json['descricao'],
      ean13: json['ean13'],
      auxCode: json['codigo_auxiliar'],
      quantity: (json['quantidade'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['preco_custo'] as num?)?.toDouble(),
      salePrice: (json['preco_venda'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'descricao': description,
      'ean13': ean13,
      'codigo_auxiliar': auxCode,
      'quantidade': quantity,
      'preco_custo': costPrice,
      'preco_venda': salePrice,
    };
  }
}
