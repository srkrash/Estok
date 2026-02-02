import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_form_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isFormVisible = false;
  Product? _editingProduct;
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  // Search Controllers
  final TextEditingController _descSearchController = TextEditingController();
  final TextEditingController _eanSearchController = TextEditingController();
  final TextEditingController _auxSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    
    _descSearchController.addListener(_filterProducts);
    _eanSearchController.addListener(_filterProducts);
    _auxSearchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _descSearchController.dispose();
    _eanSearchController.dispose();
    _auxSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _allProducts = products;
        _filterProducts(); // Apply existing filters if any, or reset to all
        _isLoading = false;
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

  void _openForm({Product? product}) {
    setState(() {
      _editingProduct = product;
      _isFormVisible = true;
    });
  }

  void _closeForm() {
    setState(() {
      _isFormVisible = false;
      _editingProduct = null;
    });
  }

  void _onFormSaved() {
    _closeForm();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFormVisible) {
      return ProductFormScreen(
        product: _editingProduct,
        onSaveSuccess: _onFormSaved,
        onCancel: _closeForm,
      );
    }

    final double widthFactor = MediaQuery.of(context).size.width < 1200 ? 1.0 : 0.8;

    return Column(
      children: [
        // Search Section with Full Width Background
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                                headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
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
                                rows: _filteredProducts.map((product) {
                                  return DataRow(
                                    onSelectChanged: (_) => _openForm(product: product),
                                    cells: [
                                      DataCell(Text(product.id.toString())),
                                      DataCell(Text(product.description)),
                                      DataCell(Text(product.ean13 ?? '-')),
                                      DataCell(Text(product.auxCode ?? '-')),
                                      DataCell(Text(product.quantity.toStringAsFixed(3).replaceAll('.', ','))),
                                      DataCell(Text('R\$ ${product.salePrice?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}')),
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
    );
  }
}
