import 'package:dio/dio.dart';

import '../models/pelicula.dart';

/// Encapsula el acceso a TMDB.
///
/// Este servicio concentra tres decisiones para mantener el resto de la UI
/// simple:
/// 1. conoce los endpoints y parámetros de TMDB,
/// 2. transforma JSON dinámico en modelos tipados del proyecto,
/// 3. traduce errores de red a mensajes comprensibles para la interfaz.
class TmdbService {
  TmdbService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  // Limitación temporal del proyecto: la API key ya venía hardcodeada y se
  // conserva así para no romper la ejecución actual. Idealmente debería vivir
  // en una configuración segura por ambiente.
  static const String _apiKey = 'da66d27dce142448651778917bf514a7';
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _imagenUrl = 'https://image.tmdb.org/t/p/w500';

  /// Busca películas por título y opcionalmente filtra por año.
  ///
  /// Devuelve modelos livianos porque la pantalla de búsqueda solo necesita
  /// renderizar lista + navegación. El detalle completo se resuelve después,
  /// recién cuando el usuario entra a una película específica.
  Future<List<PeliculaResumen>> buscarPeliculas(
    String titulo,
    String anio,
  ) async {
    final tituloNormalizado = titulo.trim();
    final anioNormalizado = anio.trim();

    if (tituloNormalizado.isEmpty) {
      throw ArgumentError('Debes ingresar un título para buscar.');
    }

    try {
      final respuesta = await _dio.get(
        '$_baseUrl/search/movie',
        queryParameters: {
          'api_key': _apiKey,
          'query': tituloNormalizado,
          'language': 'es-ES',
          if (anioNormalizado.isNotEmpty) 'year': anioNormalizado,
        },
      );

      final data = Map<String, dynamic>.from(respuesta.data as Map);
      final resultados = List<Map<String, dynamic>>.from(
        (data['results'] as List<dynamic>? ?? <dynamic>[]).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );

      return resultados
          .map(
            (item) => PeliculaResumen(
              id: item['id'] as int? ?? 0,
              titulo: _leerTexto(item['title'], fallback: 'Sin título'),
              fechaEstreno: _leerTexto(item['release_date']),
              imagen: _construirUrlImagen(item['poster_path']),
            ),
          )
          .where((pelicula) => pelicula.id != 0)
          .toList();
    } on DioException catch (error) {
      throw Exception(_traducirErrorDeRed(error));
    }
  }

  Future<Pelicula> obtenerDetallePelicula(int idPelicula) async {
    try {
      final respuestas = await Future.wait([
        _dio.get(
          '$_baseUrl/movie/$idPelicula',
          queryParameters: {'api_key': _apiKey, 'language': 'es-ES'},
        ),
        _dio.get(
          '$_baseUrl/movie/$idPelicula/credits',
          queryParameters: {'api_key': _apiKey, 'language': 'es-ES'},
        ),
      ]);

      final detalle = Map<String, dynamic>.from(respuestas[0].data as Map);
      final creditos = Map<String, dynamic>.from(respuestas[1].data as Map);

      return Pelicula(
        titulo: _leerTexto(detalle['title'], fallback: 'Sin título'),
        anio: _extraerAnio(detalle['release_date']),
        duracion: _extraerDuracion(detalle['runtime']),
        genero: _extraerGeneros(detalle['genres']),
        director: _extraerDirector(creditos['crew']),
        sinopsis: _leerTexto(detalle['overview'], fallback: 'Sin sinopsis.'),
        imagen: _construirUrlImagen(detalle['poster_path']),
        rating: _leerDouble(detalle['vote_average']),
      );
    } on DioException catch (error) {
      throw Exception(_traducirErrorDeRed(error));
    }
  }

  String _extraerDirector(Object? crewRaw) {
    final crew = List<Map<String, dynamic>>.from(
      (crewRaw as List<dynamic>? ?? <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    for (final persona in crew) {
      if (persona['job'] == 'Director') {
        return _leerTexto(persona['name'], fallback: 'No disponible');
      }
    }

    return 'No disponible';
  }

  String _extraerGeneros(Object? genresRaw) {
    final generos = List<Map<String, dynamic>>.from(
      (genresRaw as List<dynamic>? ?? <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    if (generos.isEmpty) {
      return 'No disponible';
    }

    return generos
        .map((genero) => _leerTexto(genero['name']))
        .where((nombre) => nombre.isNotEmpty)
        .join(', ');
  }

  String _extraerAnio(Object? releaseDate) {
    final fecha = _leerTexto(releaseDate);
    if (fecha.isEmpty) {
      return 'No disponible';
    }

    return fecha.split('-').first;
  }

  String _extraerDuracion(Object? runtime) {
    final minutos = runtime is int ? runtime : int.tryParse('$runtime') ?? 0;
    if (minutos <= 0) {
      return 'No disponible';
    }

    return '$minutos min';
  }

  double _leerDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse('$value') ?? 0;
  }

  String _leerTexto(Object? value, {String fallback = ''}) {
    final texto = value?.toString().trim() ?? '';
    return texto.isEmpty ? fallback : texto;
  }

  String _construirUrlImagen(Object? posterPath) {
    final path = _leerTexto(posterPath);
    if (path.isEmpty) {
      return '';
    }

    return '$_imagenUrl$path';
  }

  String _traducirErrorDeRed(DioException error) {
    if (error.response?.statusCode == 401) {
      return 'TMDB rechazó la autenticación. Revisa la API key configurada.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'La conexión con TMDB tardó demasiado. Intenta nuevamente.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No se pudo conectar con TMDB. Verifica tu red e inténtalo otra vez.';
    }

    return 'Ocurrió un error al consultar TMDB.';
  }
}
