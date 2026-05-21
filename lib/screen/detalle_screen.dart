import 'package:flutter/material.dart';

import '../models/pelicula.dart';
import '../repository/pelicula_repository.dart';
import '../services/tmdb_services.dart';

/// Pantalla de detalle.
///
/// Puede renderizar un snapshot local ya persistido o, si hace falta,
/// resolverlo por `idPelicula` contra TMDB.
///
/// Ese fallback mantiene compatibilidad con el flujo viejo sin obligar al
/// historial a depender de red para mostrar algo que YA existe en SQLite.
class DetalleScreen extends StatefulWidget {
  final int? idPelicula;
  final Pelicula? peliculaInicial;

  const DetalleScreen({super.key, this.idPelicula, this.peliculaInicial})
    : assert(
        idPelicula != null || peliculaInicial != null,
        'DetalleScreen requiere un id o una película local.',
      );

  @override
  State<DetalleScreen> createState() => _DetalleScreenState();
}

class _DetalleScreenState extends State<DetalleScreen> {
  final TmdbService _tmdbService = TmdbService();
  final PeliculaRepository _peliculaRepository = PeliculaRepository();
  late Future<Pelicula> _detalleFuture;

  @override
  void initState() {
    super.initState();
    // Si ya traemos snapshot local, renderizamos inmediato. Solo caemos a TMDB
    // cuando este screen fue abierto en modo compatibilidad por `idPelicula`.
    _detalleFuture = widget.peliculaInicial != null
        ? Future.value(widget.peliculaInicial)
        : _cargarDetalleDesdeTmdb();
  }

  Future<Pelicula> _cargarDetalleDesdeTmdb() async {
    final detalle = await _tmdbService.obtenerDetallePelicula(
      widget.idPelicula!,
    );

    final peliculaParaHistorial = Pelicula(
      tmdbId: widget.idPelicula,
      titulo: detalle.titulo,
      anio: detalle.anio,
      duracion: detalle.duracion,
      genero: detalle.genero,
      director: detalle.director,
      sinopsis: detalle.sinopsis,
      imagen: detalle.imagen,
      rating: detalle.rating,
      consultadoEn: DateTime.now(),
    );

    // Este guardado es el fallback de compatibilidad. El flujo principal nuevo
    // guarda ANTES de navegar desde búsqueda, pero si otro caller entra solo con
    // `idPelicula`, seguimos garantizando que el historial quede consistente.
    await _peliculaRepository.guardarEnHistorial(peliculaParaHistorial);

    return peliculaParaHistorial;
  }

  String _describirOrigenDetalle(Pelicula pelicula) {
    if (widget.peliculaInicial != null) {
      return 'Detalle cargado desde el snapshot guardado en SQLite';
    }

    if (pelicula.tmdbId != null) {
      return 'Detalle consultado desde TMDB y persistido en SQLite';
    }

    return 'Detalle de película';
  }

  Widget _buildPoster(String imagenUrl) {
    if (imagenUrl.isEmpty) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.movie_creation_outlined, size: 72),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imagenUrl,
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 260,
          alignment: Alignment.center,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, size: 72),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(Pelicula pelicula) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ficha técnica', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetadataItem(etiqueta: 'Año', valor: pelicula.anio),
                _MetadataItem(etiqueta: 'Duración', valor: pelicula.duracion),
                _MetadataItem(etiqueta: 'Género', valor: pelicula.genero),
                _MetadataItem(etiqueta: 'Director', valor: pelicula.director),
                _MetadataItem(
                  etiqueta: 'Rating TMDB',
                  valor: pelicula.rating.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynopsisCard(Pelicula pelicula) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sinopsis', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(pelicula.sinopsis, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de película')),
      body: FutureBuilder<Pelicula>(
        future: _detalleFuture,
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
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(mensaje, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _detalleFuture = _cargarDetalleDesdeTmdb();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pelicula = snapshot.data;
          if (pelicula == null) {
            return const Center(
              child: Text('No se pudo cargar el detalle de la película.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPoster(pelicula.imagen),
                const SizedBox(height: 16),
                Text(
                  pelicula.titulo,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _describirOrigenDetalle(pelicula),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _buildMetadataCard(pelicula),
                const SizedBox(height: 16),
                _buildSynopsisCard(pelicula),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetadataItem extends StatelessWidget {
  const _MetadataItem({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(valor, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
