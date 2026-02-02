import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/decimal_input_formatter.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaveSuccess;
  final VoidCallback onCancel;

  const ProductFormScreen({
    super.key, 
    this.product,
    required this.onSaveSuccess,
    required this.onCancel,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  
  late TextEditingController _descriptionController;
  late TextEditingController _ean13Controller;
  late TextEditingController _auxCodeController;
  late TextEditingController _quantityController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _ean13Controller = TextEditingController(text: widget.product?.ean13 ?? '');
    _auxCodeController = TextEditingController(text: widget.product?.auxCode ?? '');
    _quantityController = TextEditingController(text: widget.product?.quantity.toString().replaceAll('.', ',') ?? '0,0');
    
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    _costPriceController = TextEditingController(
      text: widget.product?.costPrice != null 
          ? currencyFormatter.format(widget.product!.costPrice) 
          : 'R\$ 0,00'
    );
    _salePriceController = TextEditingController(
      text: widget.product?.salePrice != null 
          ? currencyFormatter.format(widget.product!.salePrice) 
          : 'R\$ 0,00'
    );
  }

  double? _parseCurrency(String text) {
     String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');
     if (cleanText.isEmpty) return null;
     return double.parse(cleanText) / 100;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ean13Controller.dispose();
    _auxCodeController.dispose();
    _quantityController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final currentQuantity = double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 0.0;
      
      final product = Product(
        id: widget.product?.id,
        description: _descriptionController.text,
        ean13: _ean13Controller.text.isNotEmpty ? _ean13Controller.text : null,
        auxCode: _auxCodeController.text.isNotEmpty ? _auxCodeController.text : null,
        quantity: widget.product == null ? currentQuantity : (widget.product!.quantity), 
        // If creating, send quantity as initial. If updating, keep original in payload 
        // (though backend might ignore it if we use movement, but let's be safe and not overwrite with new value here if we plan to use movement)
        // Actually, if we use adjustStock, we don't need to send quantity in updateProduct at all IF the backend supports partial updates.
        // Assuming backend handles full object update. 
        // Let's send the OLD quantity to updateProduct so it doesn't change it directly, 
        // OR better: send the NEW quantity to updateProduct AND call adjustStock?
        // No, that would double count if we aren't careful.
        // The requirement is "call the correct endpoint".
        // If I update the product with new quantity via PUT, the history is lost.
        // So I should probably NOT change quantity in PUT.
        // Let's send `widget.product!.quantity` (old value) to PUT, and then call adjustStock.
        
        costPrice: _parseCurrency(_costPriceController.text),
        salePrice: _parseCurrency(_salePriceController.text),
      );

      try {
        if (widget.product == null) {
          // Creating: Quantity is set in the product object
          await _productService.createProduct(product);
        } else {
          // Updating
          await _productService.updateProduct(product);
          
          // Check if quantity changed
          if (currentQuantity != widget.product!.quantity) {
             await _productService.adjustStock(widget.product!.id!, currentQuantity);
          }
        }
        if (mounted) {
          widget.onSaveSuccess();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving product: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double widthFactor = MediaQuery.of(context).size.width < 1200 ? 1.0 : 0.8;

    return Center(
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.product == null ? 'Novo Produto' : 'Editar Produto',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descrição *', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a descrição';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ean13Controller,
                            decoration: const InputDecoration(labelText: 'EAN13', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length != 13) {
                                 return 'EAN13 deve ter 13 dígitos';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _auxCodeController,
                            decoration: const InputDecoration(labelText: 'Código Auxiliar', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(labelText: 'Estoque Atual', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              DecimalInputFormatter(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: const InputDecoration(labelText: 'Preço Custo', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatterNumeric(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceController,
                            decoration: const InputDecoration(labelText: 'Preço Venda', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatterNumeric(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : widget.onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          child: _isLoading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Text('Salvar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
