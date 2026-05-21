import 'package:flutter/material.dart';

import '../models/pelicula.dart';
import '../repository/pelicula_repository.dart';
import 'detalle_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final PeliculaRepository _peliculaRepository = PeliculaRepository();
  late Future<List<Pelicula>> _historialFuture;

  @override
  void initState() {
    super.initState();
    _historialFuture = _peliculaRepository.listar();
  }

  Future<void> _recargarHistorial() async {
    setState(() {
      _historialFuture = _peliculaRepository.listar();
    });

    await _historialFuture;
  }

  Future<void> _abrirDetalle(Pelicula pelicula) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // El historial navega con snapshot local porque su valor pedagógico es
        // demostrar persistencia: si la película quedó guardada, el detalle debe
        // poder reconstruirse desde esa foto sin depender primero de la API.
        builder: (context) => DetalleScreen(peliculaInicial: pelicula),
      ),
    );

    if (!mounted) {
      return;
    }

    await _recargarHistorial();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Consulta reciente';
    }

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio · $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de búsqueda')),
      body: FutureBuilder<List<Pelicula>>(
        future: _historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final mensaje = snapshot.error.toString().replaceFirst(
              'Exception: ',
              '',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(mensaje, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _recargarHistorial,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final peliculas = snapshot.data ?? const <Pelicula>[];

          if (peliculas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Todavía no consultaste ningún resultado.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando abras un detalle desde la búsqueda, quedará guardado acá.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargarHistorial,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: peliculas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pelicula = peliculas[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: pelicula.imagen.isEmpty
                        ? const SizedBox(
                            width: 50,
                            child: Icon(Icons.movie_creation_outlined),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              pelicula.imagen,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                    width: 50,
                                    child: Icon(Icons.broken_image_outlined),
                                  ),
                            ),
                          ),
                    title: Text(pelicula.titulo),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${pelicula.esSerie ? 'Serie' : 'Película'} · ${pelicula.anio} · ${pelicula.duracion}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearFecha(pelicula.consultadoEn),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirDetalle(pelicula),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
