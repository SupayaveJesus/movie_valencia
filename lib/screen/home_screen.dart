import 'package:flutter/material.dart';
import 'buscar_screen.dart';
import 'historial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void irABuscar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuscarScreen(),
      ),
    );
  }

  void irAHistorial(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistorialScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Movie Database'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.movie_creation_outlined,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cliente de películas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Busca películas por título o año y guarda tu historial localmente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => irABuscar(context),
              icon: const Icon(Icons.search),
              label: const Text('Buscar película'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => irAHistorial(context),
              icon: const Icon(Icons.history),
              label: const Text('Historial de búsqueda'),
            ),
          ],
        ),
      ),
    );
  }
}