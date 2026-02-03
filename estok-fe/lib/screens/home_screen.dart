import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'product_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';
import 'config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const DashboardTab(),
    const ProductScreen(),
    const StockScreen(),
    const SalesScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Logo / Title on the left
              Row(
                children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 48,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estok',
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 28,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Gestão Inteligente',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              
              const Spacer(),
              
              // Centered Navigation Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavigationTab(
                      label: 'Início',
                      icon: Icons.dashboard,
                      isSelected: _selectedIndex == 0,
                      onTap: () => _onTabTapped(0),
                      color: Colors.grey.shade100,
                      selectedColor: Colors.deepPurple.shade100,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Produtos',
                      icon: Icons.inventory_2,
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onTabTapped(1),
                      color: Colors.blue.shade50,
                      selectedColor: Colors.blue.shade100,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Estoque',
                      icon: Icons.edit_note,
                      isSelected: _selectedIndex == 2,
                      onTap: () => _onTabTapped(2),
                      color: Colors.orange.shade50,
                      selectedColor: Colors.orange.shade100,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Vendas',
                      icon: Icons.point_of_sale,
                      isSelected: _selectedIndex == 3,
                      onTap: () => _onTabTapped(3),
                      color: Colors.green.shade50,
                      selectedColor: Colors.green.shade100,
                    ),
                  ],
                ),
              ),

              const Spacer(),
              
              // Balancing widget or Actions (e.g. User Profile or Settings placeholder)
              // For now, just a SizedBox to balance the Logo width roughly, keeping tabs centered
               // Balancing widget or Actions
              IconButton( // Replace SizedBox logic with actual button
                icon: const Icon(Icons.settings, color: Colors.grey),
                tooltip: 'Configurações',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfigScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
        centerTitle: false,
        elevation: 1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(), // Optional: adds bounce effect on ends
        children: _screens,
      ),
    );
  }
}

class _NavigationTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final Color selectedColor;

  const _NavigationTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
    required this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : color,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.black12) : Border.all(color: Colors.transparent),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 300),
              tween: ColorTween(
                begin: Colors.black54,
                end: isSelected ? Colors.black87 : Colors.black54,
              ),
              builder: (context, color, _) {
                return Icon(
                  icon,
                  size: 20,
                  color: color,
                );
              },
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, // Reduced weight difference to minimize shift
                color: isSelected ? Colors.black87 : Colors.black54,
                fontSize: 14,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _inventorySummary;
  List<dynamic> _recentSales = [];
  List<dynamic> _topProducts = [];
  List<dynamic> _smartAlerts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summaryRes = await http.get(Uri.parse('http://localhost:5000/dashboard/summary'));
      final inventoryRes = await http.get(Uri.parse('http://localhost:5000/dashboard/inventory-summary'));
      final alertRes = await http.get(Uri.parse('http://localhost:5000/dashboard/smart-alerts'));
      final recentRes = await http.get(Uri.parse('http://localhost:5000/dashboard/recent-sales'));
      final topRes = await http.get(Uri.parse('http://localhost:5000/dashboard/top-products'));

      if (summaryRes.statusCode == 200 && inventoryRes.statusCode == 200) {
        setState(() {
          _summary = jsonDecode(utf8.decode(summaryRes.bodyBytes));
          _inventorySummary = jsonDecode(utf8.decode(inventoryRes.bodyBytes));
          _smartAlerts = jsonDecode(utf8.decode(alertRes.bodyBytes));
          _recentSales = jsonDecode(utf8.decode(recentRes.bodyBytes));
          _topProducts = jsonDecode(utf8.decode(topRes.bodyBytes));
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar dados do servidor');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro ao carregar dashboard: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    final sales = _summary?['sales'] ?? {};
    final profit = _summary?['profit'] ?? {};
    final ticket = _summary?['average_ticket'] ?? {};
    final inv = _inventorySummary ?? {};
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Inventory Summary
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visão Geral',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Acompanhe o desempenho do seu negócio', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                _buildInventoryValueCard(context, inv, currency),
              ],
            ),
            
            const SizedBox(height: 32),

            // Smart Alerts Section (Conditional)
            if (_smartAlerts.isNotEmpty) ...[
               _buildSectionTitle(context, 'Atenção Necessária (Estoque Baixo)'),
               const SizedBox(height: 16),
               _buildSmartAlertsList(context),
               const SizedBox(height: 32),
            ],
            
            // KPI Section
            _buildSectionTitle(context, 'Vendas & Lucro'),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildKpiCard(context, 'Vendas Hoje', sales['today'], ticket['today'], Icons.today, Colors.blue),
                    _buildKpiCard(context, 'Vendas Semana', sales['week'], ticket['week'], Icons.calendar_view_week, Colors.blueAccent),
                    _buildKpiCard(context, 'Vendas Mês', sales['month'], ticket['month'], Icons.calendar_month, Colors.indigo),
                    _buildKpiCard(context, 'Lucro Hoje', profit['today'], null, Icons.monetization_on, Colors.green),
                    _buildKpiCard(context, 'Lucro Semana', profit['week'], null, Icons.monetization_on_outlined, Colors.lightGreen),
                    _buildKpiCard(context, 'Lucro Mês', profit['month'], null, Icons.savings, Colors.teal),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Lists Section
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRecentSalesList(context, currency)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTopProductsList(context)),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildRecentSalesList(context, currency),
                      const SizedBox(height: 24),
                      _buildTopProductsList(context),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(BuildContext context, Map<String, dynamic> inv, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.purple.shade900]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text('Valor em Estoque (Custo)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            currency.format(inv['total_cost_value'] ?? 0),
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Potencial de Venda: ${currency.format(inv['total_sale_potential'] ?? 0)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartAlertsList(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        scrollDirection: Axis.horizontal,
        itemCount: _smartAlerts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final alert = _smartAlerts[index];
          final days = (alert['days_supply'] as num).toDouble();
          
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Estoque atual: ${alert['current_stock']}'),
                const SizedBox(height: 4),
                Text(
                  'Dura ~${days.toStringAsFixed(1)} dias',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Colors.grey[700], 
        fontWeight: FontWeight.w600
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, dynamic value, dynamic ticketValue, IconData icon, Color color) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final doubleVal = value is num ? value.toDouble() : 0.0;
    
    return Container(
      width: 200, // Min width for wrap
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currency.format(doubleVal),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          if (ticketValue != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ticket Médio: ${currency.format(ticketValue)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRecentSalesList(BuildContext context, NumberFormat currency) {
    return _buildListContainer(
      context,
      title: 'Últimas Vendas',
      icon: Icons.history,
      child: _recentSales.isEmpty 
        ? const Padding(padding: EdgeInsets.all(16), child: Text('Nenhuma venda recente.'))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSales.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final sale = _recentSales[index];
              final date = DateTime.tryParse(sale['data_venda'] ?? '') ?? DateTime.now();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  child: const Icon(Icons.receipt_long, size: 20),
                ),
                title: Text('Venda #${sale['id']}'),
                subtitle: Text(DateFormat('dd/MM HH:mm').format(date.toLocal())),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(sale['valor_total']),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      '${sale['items_count']} itens',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildTopProductsList(BuildContext context) {
    return _buildListContainer(
      context,
      title: 'Top 5 Produtos (Semana)',
      icon: Icons.trending_up,
      child: _topProducts.isEmpty
        ? const Padding(padding: EdgeInsets.all(16), child: Text('Nenhum dado disponível.'))
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final prod = _topProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange,
                  child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(prod['name'] ?? 'Produto', overflow: TextOverflow.ellipsis),
                trailing: Chip(
                  label: Text('${prod['quantity_sold']} un'),
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide.none,
                ),
              );
            },
          ),
    );
  }

  Widget _buildListContainer(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
