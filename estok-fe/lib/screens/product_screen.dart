import 'package:flutter/material.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Produtos'),
      ),
      body: const Center(
        child: Text(
          'Tela de Cadastro de Produtos (Em Breve)',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
