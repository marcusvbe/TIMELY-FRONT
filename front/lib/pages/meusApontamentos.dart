import 'package:flutter/material.dart';
import '../components/drawer.dart';

class meusApontamentos extends StatelessWidget {
  const meusApontamentos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apontamentos'),
        backgroundColor: const Color(0xFF006699),
      ),
      drawer: MeuDrawer(), // insere o menu lateral
      body: const Center(
        child: Text('Página de Apontamentos'),
      ),
    );
  }
}
