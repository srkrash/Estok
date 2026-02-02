import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/event_service.dart';
import 'dart:async';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  bool _isLoading = true;
  
  // Map to track edited quantities: ProductID -> NewQuantity
  final Map<int, double> _editedQuantities = {};
  StreamSubscription? _updateSubscription;
  late AnimationController _animationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadProducts();
    
    _updateSubscription = EventService().productUpdatedStream.listen((_) {
      if (!mounted) return;
      
      if (_editedQuantities.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atenção: Movimentações de estoque ocorreram, mas sua tela não foi atualizada devido a edições pendentes.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        _loadProducts();
      }
    });
  }
  
  @override
  void dispose() {
    _updateSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
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
          // Note: we do NOT clear edited quantities here if this was triggered by background update
          // But _loadProducts clears it in original code?
          // Let's check original code.
          // Original: _editedQuantities.clear();
          // We must ONLY clear it if we are sure. 
          // If we are here, it's either Init, Save (which clears), Refresh (user action), or Background Event (only if empty).
          // So it is safe to clear.
          _editedQuantities.clear();
          _isLoading = false;
        
          // Calculate duration based on number of items to ensure smooth staggered effect
          final int totalMs = (_allProducts.length * 50) + 500;
          _animationController.duration = Duration(milliseconds: totalMs.clamp(1000, 5000));
          _animationController.forward(from: 0);
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
              });
              _loadProducts(); // Reload ensures clean state
            },
            child: const Text('Sim, descartar'),
          ),
        ],
      ),
    );
  }

  void _onRefresh() {
    if (_editedQuantities.isEmpty) {
      _loadProducts();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Existem alterações pendentes. Atualizar a lista descartará essas mudanças.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('Atualizar mesmo assim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin
    
    final bool hasChanges = _editedQuantities.isNotEmpty;
    final double widthFactor = MediaQuery.of(context).size.width < 1200 ? 1.0 : 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualização de Estoque'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Lista',
          ),
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
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Edite as quantidades diretamente na tabela e clique em Salvar.',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${_allProducts.length} produtos carregados'),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Table
                Expanded(
                  child: Stack(
                      children: [
                        // Visual background for the header
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 56, // Standard DataTable header height
                          child: Container(color: Colors.grey[200]),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: widthFactor,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * widthFactor),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                                    columnSpacing: 16,
                                    columns: const [
                                      DataColumn(label: SizedBox(width: 50, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      DataColumn(label: SizedBox(width: 300, child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      DataColumn(label: Text('EAN / Cód. Aux', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: SizedBox(width: 150, child: Text('Quantidade Atual', style: TextStyle(fontWeight: FontWeight.bold))), numeric: true),
                                    ],
                                    rows: _allProducts.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final product = entry.value;
                                      final isEdited = _editedQuantities.containsKey(product.id);
                                      final currentVal = _editedQuantities[product.id] ?? product.quantity;
                                      
                                      // Animation Logic
                                      final totalDurationMs = _animationController.duration?.inMilliseconds ?? 1000;
                                      final double startMs = (index * 50).toDouble();
                                      final double endMs = startMs + 500;
                                      
                                      final double begin = (startMs / totalDurationMs).clamp(0.0, 1.0);
                                      final double end = (endMs / totalDurationMs).clamp(0.0, 1.0);
                                      
                                      final interval = begin < end ? Interval(begin, end, curve: Curves.easeIn) : const Interval(1.0, 1.0);

                                      final animation = CurvedAnimation(
                                        parent: _animationController,
                                        curve: interval,
                                      );

                                      return DataRow(
                                        color: isEdited ? WidgetStateProperty.all(Colors.orange.shade50) : null,
                                        cells: [
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.id.toString()))),
                                          DataCell(
                                            FadeTransition(
                                              opacity: animation,
                                              child: SizedBox(
                                                width: 300,
                                                child: Text(
                                                  product.description, 
                                                  overflow: TextOverflow.ellipsis
                                                )
                                              ),
                                            )
                                          ),
                                          DataCell(
                                            FadeTransition(
                                              opacity: animation,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  if (product.ean13 != null && product.ean13!.isNotEmpty)
                                                    Text(product.ean13!, style: const TextStyle(fontSize: 12)),
                                                  if (product.auxCode != null && product.auxCode!.isNotEmpty)
                                                    Text('Aux: ${product.auxCode!}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                ],
                                              ),
                                            )
                                          ),
                                          DataCell(
                                            FadeTransition(
                                              opacity: animation,
                                              child: SizedBox(
                                                width: 150,
                                                child: TextFormField(
                                                  key: ValueKey('qty_${product.id}'),
                                                  initialValue: currentVal.toStringAsFixed(0),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  decoration: InputDecoration(
                                                    // Always show a border to indicate editability
                                                    border: const OutlineInputBorder(),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                                    ),
                                                    focusedBorder: const OutlineInputBorder(
                                                      borderSide: BorderSide(color: Colors.blue, width: 2),
                                                    ),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    isDense: true,
                                                    fillColor: isEdited ? Colors.orange.shade50 : Colors.white,
                                                    filled: true,
                                                    suffixIcon: isEdited 
                                                        ? const Icon(Icons.edit, size: 14, color: Colors.deepOrange)
                                                        : const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: isEdited ? FontWeight.bold : FontWeight.normal,
                                                    color: isEdited ? Colors.deepOrange : Colors.black,
                                                  ),
                                                  onChanged: (val) => _onQuantityChanged(product, val),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            )
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ),
              ],
            ),
    );
  }
}
