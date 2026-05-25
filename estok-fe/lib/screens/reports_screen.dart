import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/app_config.dart';
import '../services/event_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  String? _error;

  double _totalFaturamento = 0.0;
  List<dynamic> _paymentSummary = [];
  List<dynamic> _salesDetails = [];
  
  // Filter state
  int? _selectedPaymentMethodId;
  bool _filterNoPayment = false; // For sales without payment method (null)

  @override
  void initState() {
    super.initState();
    _setPeriodMonth(); // Default to current month on start
    
    // Listen to sales updates to reload reports automatically
    EventService().productUpdatedStream.listen((_) {
      if (mounted) {
        _fetchReportData();
      }
    });
  }

  void _setPeriodToday() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = now;
      _selectedPaymentMethodId = null;
      _filterNoPayment = false;
    });
    _fetchReportData();
  }

  void _setPeriodWeek() {
    final now = DateTime.now();
    setState(() {
      _startDate = now.subtract(const Duration(days: 7));
      _endDate = now;
      _selectedPaymentMethodId = null;
      _filterNoPayment = false;
    });
    _fetchReportData();
  }

  void _setPeriodMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = now;
      _selectedPaymentMethodId = null;
      _filterNoPayment = false;
    });
    _fetchReportData();
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _selectedPaymentMethodId = null;
        _filterNoPayment = false;
      });
      _fetchReportData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _selectedPaymentMethodId = null;
        _filterNoPayment = false;
      });
      _fetchReportData();
    }
  }

  Future<void> _fetchReportData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final fmt = DateFormat('yyyy-MM-dd');
    final startStr = fmt.format(_startDate);
    final endStr = fmt.format(_endDate);
    final baseUrl = AppConfig.apiUrl;

    try {
      final summaryRes = await http.get(Uri.parse('$baseUrl/reports/sales-by-payment?start_date=$startStr&end_date=$endStr'));
      final detailsRes = await http.get(Uri.parse('$baseUrl/reports/sales-details?start_date=$startStr&end_date=$endStr'));

      if (summaryRes.statusCode == 200 && detailsRes.statusCode == 200) {
        final summaryData = jsonDecode(utf8.decode(summaryRes.bodyBytes));
        final detailsData = jsonDecode(utf8.decode(detailsRes.bodyBytes));

        setState(() {
          _totalFaturamento = (summaryData['total_faturamento'] as num).toDouble();
          _paymentSummary = summaryData['data'] ?? [];
          _salesDetails = detailsData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao conectar com o servidor: Código ${summaryRes.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _togglePaymentMethodFilter(dynamic method) {
    setState(() {
      final methodId = method['id'];
      if (methodId == null) {
        // "Sem Forma de Pagamento"
        if (_filterNoPayment) {
          _filterNoPayment = false;
        } else {
          _filterNoPayment = true;
          _selectedPaymentMethodId = null;
        }
      } else {
        _filterNoPayment = false;
        if (_selectedPaymentMethodId == methodId) {
          _selectedPaymentMethodId = null;
        } else {
          _selectedPaymentMethodId = methodId;
        }
      }
    });
  }

  List<dynamic> _getFilteredSales() {
    if (_selectedPaymentMethodId != null) {
      return _salesDetails.where((s) => s['id_forma_pagamento'] == _selectedPaymentMethodId).toList();
    }
    if (_filterNoPayment) {
      return _salesDetails.where((s) => s['id_forma_pagamento'] == null).toList();
    }
    return _salesDetails;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFmt = DateFormat('dd/MM/yyyy');
    
    final filteredSales = _getFilteredSales();
    final totalTransactions = filteredSales.length;
    final totalSalesVal = filteredSales.fold<double>(0.0, (sum, s) => sum + (s['valor_total'] as num).toDouble());
    final avgTicket = totalTransactions > 0 ? totalSalesVal / totalTransactions : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading && _paymentSummary.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar relatórios: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchReportData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchReportData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Filters
                        _buildFilterHeader(context, dateFmt),
                        
                        const SizedBox(height: 24),

                        // KPI Cards Row
                        _buildKpisRow(currency, totalTransactions, totalSalesVal, avgTicket),

                        const SizedBox(height: 32),

                        // Main Content (Split view on Desktop)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 1000) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildPaymentMethodsShare(currency),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 6,
                                    child: _buildDetailedSalesList(filteredSales, currency),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildPaymentMethodsShare(currency),
                                  const SizedBox(height: 32),
                                  _buildDetailedSalesList(filteredSales, currency),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterHeader(BuildContext context, DateFormat dateFmt) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios de Vendas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Analise a distribuição de suas vendas no período', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const Spacer(),
            // Predefined Quick Selectors
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _QuickPeriodButton(label: 'Hoje', onTap: _setPeriodToday),
                  _QuickPeriodButton(label: '7 Dias', onTap: _setPeriodWeek),
                  _QuickPeriodButton(label: 'Mês Atual', onTap: _setPeriodMonth),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Custom Date Selectors
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _selectStartDate,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(dateFmt.format(_startDate)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('até', style: TextStyle(color: Colors.grey)),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _selectEndDate,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(dateFmt.format(_endDate)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpisRow(NumberFormat currency, int totalTransactions, double totalSalesVal, double avgTicket) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            'Faturamento Período',
            currency.format(_totalFaturamento),
            Icons.trending_up,
            [Colors.purple.shade700, Colors.purple.shade900],
            _selectedPaymentMethodId != null || _filterNoPayment
                ? 'Filtro Ativo: ${currency.format(totalSalesVal)}'
                : 'Faturamento total',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            'Quantidade Vendas',
            '$totalTransactions vendas',
            Icons.receipt_long,
            [Colors.blue.shade700, Colors.blue.shade900],
            'No período selecionado',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            'Ticket Médio',
            currency.format(avgTicket),
            Icons.analytics,
            [Colors.teal.shade700, Colors.teal.shade900],
            'Valor médio por venda',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, List<Color> gradient, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Icon(icon, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsShare(NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Participação por Forma de Pagamento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Clique em um card para filtrar a tabela de vendas abaixo:', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 32),
          _paymentSummary.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: Text('Nenhuma venda no período.')),
                )
              : Column(
                  children: _paymentSummary.map((method) {
                    final percent = (method['percentual'] as num).toDouble();
                    final totalVal = (method['total_vendas'] as num).toDouble();
                    
                    final isSelected = (_selectedPaymentMethodId == method['id'] && method['id'] != null) || 
                                       (_filterNoPayment && method['id'] == null);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isSelected ? 4 : 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.purple.shade400 : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      color: isSelected ? Colors.purple.shade50.withValues(alpha: 0.3) : Colors.white,
                      child: InkWell(
                        onTap: () => _togglePaymentMethodFilter(method),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.purple.shade50,
                                    foregroundColor: Colors.purple.shade800,
                                    child: Text(
                                      method['atalho'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      method['nome'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  Text(
                                    '${percent.toStringAsFixed(1)}%',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.purple.shade700, fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${method['qtd_vendas']} vendas', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  Text(currency.format(totalVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent / 100.0,
                                  backgroundColor: Colors.grey.shade200,
                                  color: Colors.purple.shade600,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildDetailedSalesList(List<dynamic> sales, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Lista Detalhada de Vendas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_selectedPaymentMethodId != null || _filterNoPayment) ...[
                Chip(
                  label: const Text('Filtro por Forma Ativo', style: TextStyle(fontSize: 11, color: Colors.purple)),
                  backgroundColor: Colors.purple.shade50,
                  side: BorderSide(color: Colors.purple.shade100),
                  onDeleted: () {
                    setState(() {
                      _selectedPaymentMethodId = null;
                      _filterNoPayment = false;
                    });
                  },
                )
              ]
            ],
          ),
          const Divider(height: 32),
          sales.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64.0),
                  child: Center(child: Text('Nenhuma venda encontrada para os critérios selecionados.')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final date = DateTime.tryParse(sale['data_venda'] ?? '') ?? DateTime.now();
                    final totalVal = (sale['valor_total'] as num).toDouble();
                    final itemsCount = (sale['items_count'] as num).toInt();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      title: Row(
                        children: [
                          Text(
                            'Venda #${sale['id']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sale['forma_pagamento_nome'],
                              style: TextStyle(color: Colors.blueGrey.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal())} • $itemsCount itens',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      trailing: Text(
                        currency.format(totalVal),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class _QuickPeriodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPeriodButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ),
    );
  }
}
