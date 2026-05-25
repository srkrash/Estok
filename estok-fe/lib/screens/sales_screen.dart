import 'dart:async';
import 'package:estok_fe/models/product.dart';
import 'package:estok_fe/models/sale_item.dart';
import 'package:estok_fe/models/payment_method.dart';
import 'package:estok_fe/services/product_service.dart';
import 'package:estok_fe/services/sales_service.dart';
import 'package:estok_fe/services/payment_method_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with AutomaticKeepAliveClientMixin {
  final ProductService _productService = ProductService();
  final SalesService _salesService = SalesService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  
  final TextEditingController _searchController = TextEditingController();
  late FocusNode _searchFocusNode;
  late FocusNode _finalizedFocusNode;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _overlayScrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();

  final List<SaleItem> _cartItems = [];
  List<Product> _searchResults = [];
  List<PaymentMethod> _paymentMethods = [];
  Timer? _debounce;
  OverlayEntry? _overlayEntry;
  int _selectedIndex = 0;
  double _overlayQty = 1.0;
  bool _isLoading = false;
  
  // Sale Finalized State
  bool _showFinalizedScreen = false;
  double _lastSaleTotal = 0.0;

  @override
  bool get wantKeepAlive => true;

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    
    // Initialize FocusNode with key handling for navigation
    _searchFocusNode = FocusNode(onKeyEvent: (node, event) {
      if (event is KeyDownEvent) {
        if (_overlayEntry != null) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _navigateSelection(1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _navigateSelection(-1);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            _selectResult();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
             _removeOverlay();
             return KeyEventResult.handled;
          }
        }
      }
      return KeyEventResult.ignored;
    });

    // Ensure focus returns to input when starting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    _finalizedFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _finalizedFocusNode.dispose();
    _scrollController.dispose();
    _overlayScrollController.dispose();
    _removeOverlay();
    _debounce?.cancel();
    super.dispose();
  }

  void _navigateSelection(int direction) {
    if (_searchResults.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + direction + _searchResults.length) % _searchResults.length;
      
      // Update overlay to reflect selection change
       double qty = 1.0;
       final regex = RegExp(r'^(\d+(?:[.,]\d+)?)\*');
       final match = regex.firstMatch(_searchController.text);
       if (match != null) {
         final qtyString = match.group(1)!.replaceAll(',', '.');
         qty = double.tryParse(qtyString) ?? 1.0;
       }
       _showOverlay(qty);
    });
  }

  void _scrollToSelected() {
    if (!_overlayScrollController.hasClients) return;
    
    const double itemHeight = 64.0; // Fixed ListTile container height
    double viewportHeight = _overlayScrollController.position.viewportDimension;
    if (viewportHeight <= 0) {
      viewportHeight = 200.0;
    }
    
    final double targetOffset = _selectedIndex * itemHeight;
    final double currentOffset = _overlayScrollController.offset;
    
    if (targetOffset + itemHeight > currentOffset + viewportHeight) {
      final double newOffset = (targetOffset + itemHeight) - viewportHeight;
      _overlayScrollController.jumpTo(newOffset.clamp(0.0, _overlayScrollController.position.maxScrollExtent));
    } else if (targetOffset < currentOffset) {
      _overlayScrollController.jumpTo(targetOffset.clamp(0.0, _overlayScrollController.position.maxScrollExtent));
    }
  }

  void _selectResult() {
      if (_searchResults.isNotEmpty) {
        double qty = 1.0;
        final regex = RegExp(r'^(\d+(?:[.,]\d+)?)\*');
        final match = regex.firstMatch(_searchController.text);
        if (match != null) {
          final qtyString = match.group(1)!.replaceAll(',', '.');
          qty = double.tryParse(qtyString) ?? 1.0;
        }
       _addToCart(_searchResults[_selectedIndex], qty);
     }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isEmpty) {
        _removeOverlay();
        return;
      }
      _performSearch(value);
    });
  }

  void _onSubmitted(String value) async {
    // Cancel any pending debounce
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (value.isEmpty) return;

    // Check for multiplier pattern: 5*coke
    double qty = 1.0;
    String actualQuery = value;
    final regex = RegExp(r'^(\d+(?:[.,]\d+)?)\*(.*)');
    final match = regex.firstMatch(value);

    if (match != null) {
      final qtyString = match.group(1)!.replaceAll(',', '.');
      qty = double.tryParse(qtyString) ?? 1.0;
      actualQuery = match.group(2) ?? '';
    }

    if (actualQuery.isEmpty) return;

    try {
      final results = await _productService.searchProducts(actualQuery);
      
      if (!mounted) return;

      if (results.length == 1) {
        // Fast checkout path: Single result -> add immediately
        _addToCart(results.first, qty);
      } else {
        // Standard path: Show overlay
        setState(() {
          _searchResults = results;
          _selectedIndex = 0;
        });
        
        if (results.isNotEmpty) {
          _showOverlay(qty);
        } else {
           _removeOverlay();
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto não encontrado.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    // Check for multiplier pattern: 5*coke
    double qty = 1.0;
    String actualQuery = query;
    final regex = RegExp(r'^(\d+(?:[.,]\d+)?)\*(.*)');
    final match = regex.firstMatch(query);

    if (match != null) {
      final qtyString = match.group(1)!.replaceAll(',', '.');
      qty = double.tryParse(qtyString) ?? 1.0;
      actualQuery = match.group(2) ?? '';
    }

    if (actualQuery.isEmpty) return;

    try {
      final results = await _productService.searchProducts(actualQuery);
      setState(() {
        _searchResults = results;
        _selectedIndex = 0;
      });
      
      if (results.isNotEmpty) {
        _showOverlay(qty);
      } else {
        _removeOverlay();
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }
  }

  void _showOverlay(double qty) {
    _overlayQty = qty;

    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    } else {
      final width = _layerLink.leaderSize?.width ?? 400.0;
      
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.blueGrey[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Resultados (Qtd: $_overlayQty)'),
                          const Text('↑ ↓ Navegar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                     Flexible(
                       child: ListView.builder(
                        controller: _overlayScrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final product = _searchResults[index];
                          final isSelected = index == _selectedIndex;
                          return SizedBox(
                            height: 64.0,
                            child: Container(
                              color: isSelected ? Colors.blue[100] : null,
                              child: ListTile(
                                leading: const Icon(Icons.local_offer_outlined),
                                title: Text(
                                  product.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${product.ean13 ?? ""} | R\$ ${product.salePrice?.toStringAsFixed(2) ?? "0.00"}'),
                                trailing: Text('Estoque: ${product.quantity}'),
                                onTap: () => _addToCart(product, _overlayQty),
                                dense: true,
                              ),
                            ),
                          );
                        },
                       ),
                     ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _addToCart(Product product, double qty) {
    if (product.salePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto sem preço de venda cadastrado!')),
      );
      return;
    }

    setState(() {
      _cartItems.add(SaleItem(
        product: product,
        quantity: qty,
        unitPrice: product.salePrice!,
      ));
      _searchController.clear();
      _searchResults = [];
      _removeOverlay();
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      _searchFocusNode.requestFocus();
    });
  }



  void _onF1Pressed() async {
    _searchFocusNode.requestFocus();
    try {
      final results = await _productService.getAllProducts();
      setState(() {
        _searchResults = results;
        _selectedIndex = 0;
      });
      if (results.isNotEmpty) {
        _showOverlay(1.0);
      }
    } catch (e) {
      debugPrint('Error loading all products on F1: $e');
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final list = await _paymentMethodService.getPaymentMethods(activeOnly: true);
      setState(() {
        _paymentMethods = list;
      });
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
    }
  }

  void _finalizeSale() async {
    if (_cartItems.isEmpty) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final list = await _paymentMethodService.getPaymentMethods(activeOnly: true);
      setState(() {
        _paymentMethods = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error refreshing payment methods: $e');
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (_paymentMethods.isEmpty) {
      _processSaleFinalize(null);
    } else {
      _showPaymentMethodsDialog();
    }
  }

  Future<void> _processSaleFinalize(int? paymentMethodId, {BuildContext? dialogContext}) async {
    setState(() => _isLoading = true);

    try {
      final total = _subtotal;
      await _salesService.registerSale(_cartItems, total, paymentMethodId);
      
      if (!mounted) return;

      if (dialogContext != null && Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext); // Close dialog
      }

      setState(() {
        _lastSaleTotal = total;
        _showFinalizedScreen = true;
        _cartItems.clear();
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _finalizedFocusNode.requestFocus();
        });
      });

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao finalizar venda: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.pop(dialogCtx);
                    return KeyEventResult.handled;
                  }
                  
                  final char = event.character?.toUpperCase();
                  if (char != null && char.isNotEmpty) {
                    PaymentMethod? match;
                    for (var m in _paymentMethods) {
                      if (m.atalho.toUpperCase() == char && m.ativo) {
                        match = m;
                        break;
                      }
                    }
                    if (match != null) {
                      _processSaleFinalize(match.id, dialogContext: dialogCtx);
                      return KeyEventResult.handled;
                    }
                  }
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.payment, color: Colors.green.shade700),
                    const SizedBox(width: 12),
                    const Text('Forma de Pagamento'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VALOR TOTAL: ${currencyFormat.format(_subtotal)}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pressione o atalho no teclado ou clique para selecionar:',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        children: _paymentMethods.map((method) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: _isLoading
                                  ? null
                                  : () => _processSaleFinalize(method.id, dialogContext: dialogCtx),
                              borderRadius: BorderRadius.circular(8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade50,
                                  foregroundColor: Colors.green.shade800,
                                  child: Text(
                                    method.atalho,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  method.nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancelar (ESC)'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startNewSale() {
    setState(() {
      _showFinalizedScreen = false;
      _cartItems.clear(); // Ensure cart is clear just in case
    });
    // Request focus on next frame to ensure widget tree is rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _cancelSale() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Venda?'),
        content: const Text('Isso limpará todos os itens da venda atual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _cartItems.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    if (_showFinalizedScreen) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _startNewSale,
          const SingleActivator(LogicalKeyboardKey.escape): _startNewSale,
          const SingleActivator(LogicalKeyboardKey.f1): _startNewSale,
          const SingleActivator(LogicalKeyboardKey.f6): _startNewSale,
        },
        child: Focus(
          focusNode: _finalizedFocusNode,
          autofocus: true,
          child: GestureDetector(
            onTap: _startNewSale,
            child: Container(
              color: Colors.green.shade700,
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.check_circle_outline, size: 120, color: Colors.white),
                   const SizedBox(height: 32),
                   const Text(
                     'Venda Finalizada!',
                     style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 16),
                   Text(
                     'Total: ${currencyFormat.format(_lastSaleTotal)}',
                     style: const TextStyle(color: Colors.white, fontSize: 36),
                   ),
                   const SizedBox(height: 64),
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.white,
                       foregroundColor: Colors.green.shade800,
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                     ),
                     onPressed: _startNewSale,
                     icon: const Icon(Icons.shopping_cart),
                     label: const Text('Nova Venda (ENTER)', style: TextStyle(fontSize: 20)),
                   )
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): _onF1Pressed,
        const SingleActivator(LogicalKeyboardKey.f6): _finalizeSale,
        const SingleActivator(LogicalKeyboardKey.f8): _cancelSale,
      },
      child: Focus(
        autofocus: true,
        child: GestureDetector(
          onTap: () => _searchFocusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
            body: Column(
              children: [
                // Header / Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CompositedTransformTarget(
                        link: _layerLink,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: const InputDecoration(
                            labelText: 'Produto (Digite nome, código ou 5*produto)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                            helperText: 'ENTER seleciona • F1 Busca • ↑↓ Navega • F6 Finaliza • F8 Cancela',
                          ),
                          style: const TextStyle(fontSize: 18),
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSubmitted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
  
              // Product List
              Expanded(
                child: _cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Caixa Livre', style: TextStyle(fontSize: 24, color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey[100],
                              foregroundColor: Colors.blueGrey[800],
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item.product.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text('${item.quantity} x ${currencyFormat.format(item.unitPrice)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyFormat.format(item.total),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _cartItems.removeAt(index);
                                    });
                                    _searchFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
  
              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.blueGrey[900],
                child: SafeArea(
                  child: Row(
                    children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Text(
                             'ITENS: ${_cartItems.length}',
                             style: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'TOTAL',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                           ),
                           Text(
                             currencyFormat.format(_subtotal),
                             style: const TextStyle(
                               color: Colors.greenAccent,
                               fontSize: 36,
                               fontWeight: FontWeight.bold,
                               ),
                           ),
                         ],
                       ),
                       const Spacer(),
                       // Buttons
                       OutlinedButton.icon(
                         onPressed: _cartItems.isEmpty ? null : _cancelSale,
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.redAccent,
                           side: const BorderSide(color: Colors.redAccent),
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                         ),
                         icon: const Icon(Icons.cancel_outlined),
                         label: const Text('CANCELAR (F8)'),
                       ),
                       const SizedBox(width: 16),
                       ElevatedButton.icon(
                         onPressed: _cartItems.isEmpty || _isLoading ? null : _finalizeSale,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.green,
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                         ),
                         icon: _isLoading 
                             ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                             : const Icon(Icons.check),
                         label: Text(_isLoading ? 'PROCESSANDO...' : 'FINALIZAR (F6)', style: const TextStyle(fontSize: 18)),
                       ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
