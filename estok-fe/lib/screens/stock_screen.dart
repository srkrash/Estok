import 'package:flutter/material.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualização de Estoque'),
      ),
      body: const Center(
        child: Text(
          'Tela de Atualização de Estoque (Em Breve)',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
