import 'package:flutter/material.dart';
import 'product_screen.dart';
import 'stock_screen.dart';
import 'sales_screen.dart';

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
                      color: Colors.transparent,
                      selectedColor: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Produtos',
                      icon: Icons.inventory_2,
                      isSelected: _selectedIndex == 1,
                      onTap: () => _onTabTapped(1),
                      color: Colors.transparent,
                      selectedColor: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Estoque',
                      icon: Icons.edit_note,
                      isSelected: _selectedIndex == 2,
                      onTap: () => _onTabTapped(2),
                      color: Colors.transparent,
                      selectedColor: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    _NavigationTab(
                      label: 'Vendas',
                      icon: Icons.point_of_sale,
                      isSelected: _selectedIndex == 3,
                      onTap: () => _onTabTapped(3),
                      color: Colors.transparent,
                      selectedColor: Colors.white,
                    ),
                  ],
                ),
              ),

              const Spacer(),
              
              // Balancing widget or Actions (e.g. User Profile or Settings placeholder)
              // For now, just a SizedBox to balance the Logo width roughly, keeping tabs centered
              const SizedBox(width: 100), 
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
              color: Colors.black.withAlpha(13),
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

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(32),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vendas do Dia',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'R\$ --,--',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 8),
              const Text('(Funcionalidade em breve)'),
            ],
          ),
        ),
      ),
    );
  }
}
