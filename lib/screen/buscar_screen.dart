import 'package:flutter/material.dart';
import 'detalle_screen.dart';
import 'historial_screen.dart';

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController anioController = TextEditingController();

  List<dynamic> peliculas = [];
  bool cargando = false;

  Future<void> buscarPeliculas() async {
    setState(() {
      cargando = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      peliculas = [
        {
          'id': 1,
          'title': 'Avengers: Endgame',
          'release_date': '2019-04-26',
          'poster_path': null,
        },
        {
          'id': 2,
          'title': 'Interstellar',
          'release_date': '2014-11-07',
          'poster_path': null,
        },
        {
          'id': 3,
          'title': 'Batman Begins',
          'release_date': '2005-06-15',
          'poster_path': null,
        },
      ];

      cargando = false;
    });
  }

  void irADetalle(int idPelicula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleScreen(idPelicula: idPelicula),
      ),
    );
  }

  void irAHistorial() {
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
        title: const Text('Buscador de películas'),
        actions: [
          IconButton(
            onPressed: irAHistorial,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: anioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Año',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: buscarPeliculas,
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 15),
            cargando
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: peliculas.length,
                      itemBuilder: (context, index) {
                        final pelicula = peliculas[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.movie),
                            title: Text(pelicula['title']),
                            subtitle: Text(
                              pelicula['release_date'],
                            ),
                            onTap: () {
                              irADetalle(pelicula['id']);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}