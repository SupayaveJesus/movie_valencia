import 'package:flutter/material.dart';

class DetalleScreen extends StatelessWidget {
  final int idPelicula;

  const DetalleScreen({
    super.key,
    required this.idPelicula,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de película'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Detalle de la película con ID: $idPelicula',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}