import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_config.dart';
import '../models/payment_method.dart';
import '../services/payment_method_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final PaymentMethodService _paymentService = PaymentMethodService();

  bool _isLoadingConnection = false;
  bool _isLoadingPayments = true;
  List<PaymentMethod> _paymentMethods = [];
  String? _paymentsError;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
    _fetchPaymentMethods();
  }

  void _loadCurrentConfig() {
    _hostController.text = AppConfig.host;
    _portController.text = AppConfig.port;
  }

  Future<void> _fetchPaymentMethods() async {
    setState(() {
      _isLoadingPayments = true;
      _paymentsError = null;
    });
    try {
      final list = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = list;
        _isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        _paymentsError = e.toString();
        _isLoadingPayments = false;
      });
    }
  }

  Future<void> _saveConnectionConfig() async {
    setState(() {
      _isLoadingConnection = true;
    });

    try {
      await AppConfig.save(_hostController.text, _portController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuração de conexão salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh payments list in case IP changed
        _fetchPaymentMethods();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingConnection = false;
        });
      }
    }
  }

  void _openPaymentMethodDialog([PaymentMethod? existing]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing?.nome);
    final shortcutController = TextEditingController(text: existing?.atalho);
    bool active = existing?.ativo ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Nova Forma de Pagamento' : 'Editar Forma de Pagamento'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Dinheiro, Pix, Cartão de Crédito',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Informe o nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: shortcutController,
                      maxLength: 1,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Atalho de Teclado (Tecla)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: D, C, P',
                        counterText: '',
                      ),
                      onChanged: (val) {
                        shortcutController.text = val.toUpperCase();
                        shortcutController.selection = TextSelection.fromPosition(
                          TextPosition(offset: shortcutController.text.length),
                        );
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Informe uma tecla de atalho';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Ativo'),
                      value: active,
                      onChanged: (val) {
                        setDialogState(() {
                          active = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final method = PaymentMethod(
                          id: existing?.id,
                          nome: nameController.text.trim(),
                          atalho: shortcutController.text.trim().toUpperCase(),
                          ativo: active,
                        );
                        await _paymentService.savePaymentMethod(method);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forma de pagamento salva com sucesso!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _fetchPaymentMethods();
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Forma de Pagamento?'),
        content: Text('Deseja excluir "${method.nome}"? Se já houver vendas associadas, ela será apenas desativada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Exclusão'),
          ),
        ],
      ),
    );

    if (confirmed == true && method.id != null) {
      try {
        await _paymentService.deletePaymentMethod(method.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Forma de pagamento excluída/desativada com sucesso.'), backgroundColor: Colors.green),
          );
          _fetchPaymentMethods();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Configurações'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dns), text: 'Conexão com Servidor'),
              Tab(icon: Icon(Icons.payment), text: 'Formas de Pagamento'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Server Connection
            _buildConnectionTab(),
            
            // Tab 2: Payment Methods List
            _buildPaymentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns, size: 28, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'Conexão com API Flask',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure o endereço e a porta do servidor local do backend.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _hostController,
                    decoration: const InputDecoration(
                      labelText: 'Host (IP ou Endereço)',
                      border: OutlineInputBorder(),
                      hintText: 'ex: localhost ou 192.168.1.10',
                      prefixIcon: Icon(Icons.computer),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Porta',
                      border: OutlineInputBorder(),
                      hintText: 'ex: 5000',
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingConnection ? null : _saveConnectionConfig,
                      icon: const Icon(Icons.save),
                      label: _isLoadingConnection 
                        ? const SizedBox(
                            width: 24, 
                            height: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          ) 
                        : const Text('Salvar Conexão', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paymentsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar formas de pagamento:\n$_paymentsError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPaymentMethods,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formas de Pagamento',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure as formas aceitas e seus respectivos atalhos de teclado no PDV.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openPaymentMethodDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nova Forma de Pagamento'),
              ),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: _paymentMethods.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma forma de pagamento cadastrada.',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = _paymentMethods[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: method.ativo ? Colors.grey.shade200 : Colors.red.shade100,
                          ),
                        ),
                        color: method.ativo ? Colors.white : Colors.red.shade50.withValues(alpha: 0.3),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: method.ativo ? Colors.blue.shade50 : Colors.grey.shade200,
                            foregroundColor: method.ativo ? Colors.blue.shade700 : Colors.grey.shade600,
                            child: Text(
                              method.atalho,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                method.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: method.ativo ? Colors.black87 : Colors.black54,
                                  decoration: method.ativo ? null : TextDecoration.lineThrough,
                                ),
                              ),
                              if (!method.ativo) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'INATIVO',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            'Atalho de Teclado: Tecla "${method.atalho}"',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar',
                                onPressed: () => _openPaymentMethodDialog(method),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Excluir',
                                onPressed: () => _deletePaymentMethod(method),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
