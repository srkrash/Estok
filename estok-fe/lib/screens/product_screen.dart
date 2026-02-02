import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/event_service.dart';
import 'product_form_screen.dart';
import 'dart:async';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  Product? _editingProduct;
  int _sortColumnIndex = 0;
  bool _isAscending = true;
  late AnimationController _animationController;
  StreamSubscription? _updateSubscription;

  // Search Controllers
  final TextEditingController _descSearchController = TextEditingController();
  final TextEditingController _eanSearchController = TextEditingController();
  final TextEditingController _auxSearchController = TextEditingController();

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
    
    _descSearchController.addListener(_filterProducts);
    _eanSearchController.addListener(_filterProducts);
    _auxSearchController.addListener(_filterProducts);

    _updateSubscription = EventService().productUpdatedStream.listen((_) {
      if (mounted) {
        _loadProducts();
      }
    });
  }



  Future<void> _loadProducts() async {
    // Only show loading if it's the first load or explicit refresh. 
    // For background updates, maybe we want to be less intrusive?
    // User asked for "update", usually implies showing fresh data.
    // If I set _isLoading = true, it will flash the loading spinner.
    // Maybe better to keep current view and just swap data?
    // But `_loadProducts` logic builds animations etc.
    // Let's stick to simple reload for now.
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filterProducts(); // Apply existing filters if any, or reset to all
        _isLoading = false;
        
        // Calculate duration based on number of items to ensure smooth staggered effect
        final int totalMs = (_filteredProducts.length * 50) + 500;
        _animationController.duration = Duration(milliseconds: totalMs.clamp(1000, 5000));
        _animationController.forward(from: 0);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  void _refreshProducts() {
    _descSearchController.clear();
    _eanSearchController.clear();
    _auxSearchController.clear();
    _loadProducts();
  }

  void _filterProducts() {
    final descQuery = _descSearchController.text.toLowerCase();
    final eanQuery = _eanSearchController.text.toLowerCase();
    final auxQuery = _auxSearchController.text.toLowerCase();

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesDesc = product.description.toLowerCase().contains(descQuery);
        final matchesEan = product.ean13?.toLowerCase().contains(eanQuery) ?? (eanQuery.isEmpty);
        final matchesAux = product.auxCode?.toLowerCase().contains(auxQuery) ?? (auxQuery.isEmpty);
        
        return matchesDesc && matchesEan && matchesAux;
      }).toList();
      
      // Re-apply sort
      _sortProducts(_sortColumnIndex, _isAscending);
    });
  }

  void _sortProducts(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _isAscending = ascending;

    _filteredProducts.sort((a, b) {
      int cmp = 0;
      switch (columnIndex) {
        case 0: // ID
          cmp = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case 1: // Descricao
          cmp = a.description.compareTo(b.description);
          break;
        case 2: // EAN
          cmp = (a.ean13 ?? '').compareTo(b.ean13 ?? '');
          break;
        case 3: // Aux
          cmp = (a.auxCode ?? '').compareTo(b.auxCode ?? '');
          break;
        case 4: // Qtd
          cmp = a.quantity.compareTo(b.quantity);
          break;
        case 5: // Preco Venda
          cmp = (a.salePrice ?? 0).compareTo(b.salePrice ?? 0);
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortProducts(columnIndex, ascending);
    });
  }

  // Page Controller
  final PageController _pageController = PageController();

  /* ... */

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _animationController.dispose();
    _pageController.dispose();
    _descSearchController.dispose();
    _eanSearchController.dispose();
    _auxSearchController.dispose();
    super.dispose();
  }

  /* ... */

  void _openForm({Product? product}) {
    setState(() {
      _editingProduct = product;
    });
    // Animate to Form Page (Index 1) - Viewport moves down, content moves up
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _closeForm() {
    // Animate back to List Page (Index 0) - Viewport moves up, content moves down
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ).then((_) {
      // Clear editing product after animation completes
      if (mounted) {
        setState(() {
          _editingProduct = null;
        });
      }
    });
  }

  void _onFormSaved() {
    _closeForm();
    // Wait for animation to finish before reloading? Or reload immediately? 
    // Reloading might cause lag during animation. Let's wait slightly or reload after.
    // Actually, reloading updates the list on Page 0. If we are on Page 1, it's fine.
    // If we reload while animating, it might stutter.
    // Let's reload after a short delay or just let it happen.
    Future.delayed(const Duration(milliseconds: 500), _loadProducts);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final double widthFactor = MediaQuery.of(context).size.width < 1200 ? 1.0 : 0.8;

    return PageView(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(), // Disable user scrolling
      children: [
        // Page 0: Product List
        Column(
          children: [
            // Search Section with Full Width Background
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _descSearchController,
                          decoration: const InputDecoration(
                            labelText: 'Pesquisar Descrição',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _auxSearchController,
                          decoration: const InputDecoration(
                            labelText: 'Cód. Aux',
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _eanSearchController,
                          decoration: const InputDecoration(
                            labelText: 'EAN13',
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _refreshProducts,
                        icon: const Icon(Icons.refresh, color: Colors.blue), // Or use Theme accent color
                        tooltip: 'Atualizar e Limpar Filtros',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withAlpha(26), // approx 0.1 opacity
                          padding: const EdgeInsets.all(12)
                        )
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 28),
                        label: const Text('NOVO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Data Table with Full Width Header Background
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        // Visual background for the header
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 56, // Standard DataTable header height
                          child: Container(color: Colors.grey[200]),
                        ),
                        // Content
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
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _isAscending,
                                    showCheckboxColumn: false,
                                    columnSpacing: 16, // Reduced spacing
                                    headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                                    columns: [
                                      DataColumn(
                                        label: const SizedBox(width: 50, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                                        onSort: _onSort
                                      ),
                                      DataColumn(
                                        label: const SizedBox(width: 300, child: Text('Descrição', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                        onSort: _onSort
                                      ),
                                      DataColumn(label: const Text('EAN13', style: TextStyle(fontWeight: FontWeight.bold)), onSort: _onSort),
                                      DataColumn(
                                        label: const SizedBox(width: 80, child: Text('Auxiliar', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                                        onSort: _onSort
                                      ),
                                      DataColumn(
                                        label: const SizedBox(width: 110, child: Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), 
                                        onSort: _onSort, 
                                        numeric: true
                                      ),
                                      DataColumn(
                                        label: const Text('Valor Venda', style: TextStyle(fontWeight: FontWeight.bold)), 
                                        onSort: _onSort, 
                                        numeric: true
                                      ),
                                    ],
                                    rows: _filteredProducts.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final product = entry.value;
                                      
                                      // Calculate staggered animation interval
                                      final totalDurationMs = _animationController.duration?.inMilliseconds ?? 1000;
                                      final double startMs = (index * 50).toDouble();
                                      final double endMs = startMs + 500; // Each item takes 500ms to fade in
                                      
                                      final double begin = (startMs / totalDurationMs).clamp(0.0, 1.0);
                                      final double end = (endMs / totalDurationMs).clamp(0.0, 1.0);
                                      
                                      // Ensure valid interval
                                      final interval = begin < end ? Interval(begin, end, curve: Curves.easeIn) : const Interval(1.0, 1.0);

                                      final animation = CurvedAnimation(
                                        parent: _animationController,
                                        curve: interval,
                                      );

                                      return DataRow(
                                        onSelectChanged: (_) => _openForm(product: product),
                                        cells: [
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.id.toString()))),
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.description))),
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.ean13 ?? '-'))),
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.auxCode ?? '-'))),
                                          DataCell(FadeTransition(opacity: animation, child: Text(product.quantity.toStringAsFixed(3).replaceAll('.', ',')))),
                                          DataCell(FadeTransition(opacity: animation, child: Text('R\$ ${product.salePrice?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}'))),
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

        // Page 1: Product Form
        ProductFormScreen(
          product: _editingProduct,
          onSaveSuccess: _onFormSaved,
          onCancel: _closeForm,
        ),
      ],
    );
  }
}
