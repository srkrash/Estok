import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with AutomaticKeepAliveClientMixin {
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  bool _isLoading = true;
  
  // Map to track edited quantities: ProductID -> NewQuantity
  final Map<int, double> _editedQuantities = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      // Sort by ID naturally
      products.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      
      if (mounted) {
        setState(() {
          _allProducts = products;
          _editedQuantities.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  void _onQuantityChanged(Product product, String value) {
    if (value.isEmpty) return;
    
    // Parse input, allowing comma or dot as decimal separator
    final double? newQty = double.tryParse(value.replaceAll(',', '.'));
    if (newQty == null) return;

    final int productId = product.id!;
    final bool wasEdited = _editedQuantities.containsKey(productId);
    
    // If value matches original, remove from map (not edited)
    if (newQty == product.quantity) {
      _editedQuantities.remove(productId);
    } else {
      _editedQuantities[productId] = newQty;
    }

    final bool isEdited = _editedQuantities.containsKey(productId);

    // Only rebuild if the "edited status" changed (to toggle row color)
    // or if we reverting to original state
    if (wasEdited != isEdited) {
      setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (_editedQuantities.isEmpty) return;

    setState(() => _isLoading = true);
    
    int successCount = 0;
    int errorCount = 0;

    // Iterate through a copy of keys to avoid modification issues if we were removing
    final List<int> idsToProcess = _editedQuantities.keys.toList();

    for (final id in idsToProcess) {
      try {
        final newQty = _editedQuantities[id]!;
        await _productService.adjustStock(
          id, 
          newQty, 
          observation: 'Ajuste em massa (Tela de Estoque)'
        );
        successCount++;
      } catch (e) {
        errorCount++;
        debugPrint('Erro ao atualizar produto $id: $e');
      }
    }

    if (mounted) {
      // Reload everything to get fresh data
      await _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Atualização finalizada. Sucesso: $successCount. Erros: $errorCount',
            ),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    }
  }

  void _cancelChanges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Todas as alterações não salvas serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _editedQuantities.clear();
                // To force fields to reset to original values, we might need to 
                // trigger a deeper rebuild. Since we use `initialValue` in keys,
                // re-creating the table rows creates new keys if we are smart,
                // or we rely on the map being empty. 
                // Actually, since `initialValue` is set once, we need to force
                // the widgets to rebuild.
                
                // A simple way is re-fetching data, but that's expensive.
                // Or just setState is enough because TextField with same key 
                // keeps state? No, we WANT to reset state.
                
                // If we give unique Keys based on "mod count" or something?
                // Or just clear map and setState. The TextFields reading 
                // `initialValue` might stick to their current controller text 
                // if they are not disposed. 
                
                // To fix this: we can just reload products. It's safe and robust.
              });
              _loadProducts(); // Reload ensures clean state
            },
            child: const Text('Sim, descartar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin
    
    final bool hasChanges = _editedQuantities.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualização de Estoque'),
        actions: [
          if (hasChanges) ...[
            TextButton.icon(
              onPressed: _cancelChanges,
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Salvar Alterações'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
          ]
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info Banner
                Container(
                  width: double.infinity,
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Edite as quantidades diretamente na tabela e clique em Salvar.'),
                      const Spacer(),
                      Text('${_allProducts.length} produtos carregados'),
                    ],
                  ),
                ),
                
                // Table
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('EAN / Cód. Aux', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Quantidade Atual', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        ],
                        rows: _allProducts.map((product) {
                          final isEdited = _editedQuantities.containsKey(product.id);
                          final currentVal = _editedQuantities[product.id] ?? product.quantity;
                          
                          return DataRow(
                            color: isEdited ? WidgetStateProperty.all(Colors.orange.shade50) : null,
                            cells: [
                              DataCell(Text(product.id.toString())),
                              DataCell(
                                SizedBox(
                                  width: 300,
                                  child: Text(
                                    product.description, 
                                    overflow: TextOverflow.ellipsis
                                  )
                                )
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (product.ean13 != null && product.ean13!.isNotEmpty)
                                      Text(product.ean13!, style: const TextStyle(fontSize: 12)),
                                    if (product.auxCode != null && product.auxCode!.isNotEmpty)
                                      Text('Aux: ${product.auxCode!}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                )
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    key: ValueKey('qty_${product.id}'), // Helper to keep identifying the field
                                    initialValue: currentVal.toStringAsFixed(0), // No decimals for qty usually? or do we need decimals? Schema says DECIMAL(10,3). App usually uses double. Let's use clean string.
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      border: isEdited ? const OutlineInputBorder() : InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                      fillColor: Colors.white,
                                      filled: isEdited,
                                    ),
                                    style: TextStyle(
                                      fontWeight: isEdited ? FontWeight.bold : FontWeight.normal,
                                      color: isEdited ? Colors.deepOrange : Colors.black,
                                    ),
                                    onChanged: (val) => _onQuantityChanged(product, val),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
