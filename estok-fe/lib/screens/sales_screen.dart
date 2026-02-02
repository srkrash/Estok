import 'package:flutter/material.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendas (PDV)'),
      ),
      body: const Center(
        child: Text(
          'Tela de Vendas (Em Breve)',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
