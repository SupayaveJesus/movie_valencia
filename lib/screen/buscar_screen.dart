import 'package:flutter/material.dart';

import '../models/pelicula.dart';
import '../repository/pelicula_repository.dart';
import '../services/tmdb_services.dart';
import 'detalle_screen.dart';
import 'historial_screen.dart';

/// Pantalla de entrada del flujo principal.
///
/// La responsabilidad de esta pantalla es muy concreta: recibir la intención
/// del usuario, pedir resultados a TMDB y representar claramente los estados de
/// la búsqueda (idle, loading, error, empty y success).
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final TextEditingController tituloController = TextEditingController();
  final TextEditingController anioController = TextEditingController();
  final TmdbService _tmdbService = TmdbService();
  final PeliculaRepository _peliculaRepository = PeliculaRepository();

  String _tipoMediaSeleccionado = TipoMedia.pelicula;
  List<PeliculaResumen> peliculas = [];
  bool cargando = false;
  bool busquedaRealizada = false;
  String? mensajeError;
  String? peliculaAbriendoClave;

  @override
  void dispose() {
    tituloController.dispose();
    anioController.dispose();
    super.dispose();
  }

  Future<void> buscarPeliculas() async {
    final titulo = tituloController.text.trim();
    final anio = anioController.text.trim();

    if (titulo.isEmpty && anio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un título, un año o ambos antes de buscar.'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
      busquedaRealizada = true;
      mensajeError = null;
    });

    try {
      final resultados = await _tmdbService.buscarPeliculas(
        titulo,
        anio,
        _tipoMediaSeleccionado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        peliculas = resultados;
        cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        peliculas = [];
        mensajeError = error.toString().replaceFirst('Exception: ', '');
        cargando = false;
      });
    }
  }

  Future<void> irADetalle(PeliculaResumen resumen) async {
    setState(() {
      peliculaAbriendoClave = resumen.claveUnica;
    });

    try {
      final detalleRemoto = await _tmdbService.obtenerDetallePelicula(
        resumen.id,
        resumen.tipoMedia,
      );

      // Guardamos en ESTE punto porque acá la intención del usuario ya dejó de
      // ser una búsqueda genérica y pasó a ser la selección concreta de una
      // película. Así el historial refleja qué quiso consultar realmente y el
      // detalle siguiente puede trabajar sobre un snapshot ya persistido.
      final peliculaLocal = Pelicula(
        tmdbId: resumen.id,
        tipoMedia: resumen.tipoMedia,
        titulo: detalleRemoto.titulo,
        anio: detalleRemoto.anio,
        duracion: detalleRemoto.duracion,
        genero: detalleRemoto.genero,
        director: detalleRemoto.director,
        sinopsis: detalleRemoto.sinopsis,
        imagen: detalleRemoto.imagen,
        rating: detalleRemoto.rating,
        consultadoEn: DateTime.now(),
      );

      await _peliculaRepository.guardarEnHistorial(peliculaLocal);

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          // Ya tenemos el detalle completo y persistido. Navegar con el snapshot
          // local evita una segunda consulta inmediata y mantiene alineado el
          // flujo con la idea del historial basado en SQLite.
          builder: (context) => DetalleScreen(peliculaInicial: peliculaLocal),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final mensaje = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) {
        setState(() {
          peliculaAbriendoClave = null;
        });
      }
    }
  }

  void irAHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistorialScreen()),
    );
  }

  Widget _buildContenidoResultados() {
    // Esta rama hace explícito el contrato visual del flujo. Eso evita que el
    // lector tenga que inferir estados mezclados dentro del ListView.
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mensajeError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(mensajeError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: buscarPeliculas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!busquedaRealizada) {
      return const Center(
        child: Text(
          'Escribe un título, un año o ambos para consultar películas o series en TMDB.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (peliculas.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron resultados con esos filtros.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: peliculas.length,
      itemBuilder: (context, index) {
        final pelicula = peliculas[index];

        return Card(
          child: ListTile(
            leading: pelicula.imagen.isEmpty
                ? const Icon(Icons.movie)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      pelicula.imagen,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.movie),
                    ),
                  ),
            title: Text(pelicula.titulo),
            subtitle: Text(
              pelicula.fechaEstreno.isEmpty
                  ? pelicula.etiquetaTipo
                  : '${pelicula.etiquetaTipo} · ${pelicula.fechaEstreno}',
            ),
            trailing: peliculaAbriendoClave == pelicula.claveUnica
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: peliculaAbriendoClave == null
                ? () => irADetalle(pelicula)
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador de TMDB'),
        actions: [
          IconButton(onPressed: irAHistorial, icon: const Icon(Icons.history)),
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
                hintText: 'Opcional si completas el año',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: anioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Año',
                hintText: 'Opcional si completas el título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _tipoMediaSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de contenido',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TipoMedia.pelicula,
                  child: Text('Películas'),
                ),
                DropdownMenuItem(value: TipoMedia.serie, child: Text('Series')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _tipoMediaSeleccionado = value;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: buscarPeliculas,
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 15),
            Expanded(child: _buildContenidoResultados()),
          ],
        ),
      ),
    );
  }
}
