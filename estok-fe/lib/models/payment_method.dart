class PaymentMethod {
  final int? id;
  final String nome;
  final String atalho;
  final bool ativo;

  PaymentMethod({
    this.id,
    required this.nome,
    required this.atalho,
    this.ativo = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int?,
      nome: json['nome'] as String,
      atalho: json['atalho'] as String,
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'atalho': atalho.toUpperCase(),
      'ativo': ativo,
    };
  }
}
