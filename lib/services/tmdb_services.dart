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

  /// Busca películas o series por título y opcionalmente filtra por año.
  ///
  /// Devuelve modelos livianos porque la pantalla de búsqueda solo necesita
  /// renderizar lista + navegación. El detalle completo se resuelve después,
  /// recién cuando el usuario entra a un resultado específico.
  Future<List<PeliculaResumen>> buscarPeliculas(
    String titulo,
    String anio,
    String tipoMedia,
  ) async {
    final tituloNormalizado = titulo.trim();
    final anioNormalizado = anio.trim();

    if (tituloNormalizado.isEmpty && anioNormalizado.isEmpty) {
      throw ArgumentError('Ingresa un título, un año o ambos para buscar.');
    }

    try {
      final esBusquedaPorTitulo = tituloNormalizado.isNotEmpty;
      final respuesta = await _dio.get(
        esBusquedaPorTitulo
            ? '$_baseUrl/search/$tipoMedia'
            : '$_baseUrl/discover/$tipoMedia',
        queryParameters: _armarParametrosBusqueda(
          titulo: tituloNormalizado,
          anio: anioNormalizado,
          tipoMedia: tipoMedia,
          esBusquedaPorTitulo: esBusquedaPorTitulo,
        ),
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
              tipoMedia: tipoMedia,
              titulo: _leerTexto(
                item['title'] ?? item['name'],
                fallback: 'Sin título',
              ),
              fechaEstreno: _leerTexto(
                item['release_date'] ?? item['first_air_date'],
              ),
              imagen: _construirUrlImagen(item['poster_path']),
            ),
          )
          .where((pelicula) => pelicula.id != 0)
          .toList();
    } on DioException catch (error) {
      throw Exception(_traducirErrorDeRed(error));
    }
  }

  Future<Pelicula> obtenerDetallePelicula(
    int idPelicula,
    String tipoMedia,
  ) async {
    try {
      final respuestas = await Future.wait([
        _dio.get(
          '$_baseUrl/$tipoMedia/$idPelicula',
          queryParameters: {'api_key': _apiKey, 'language': 'es-ES'},
        ),
        _dio.get(
          '$_baseUrl/$tipoMedia/$idPelicula/credits',
          queryParameters: {'api_key': _apiKey, 'language': 'es-ES'},
        ),
      ]);

      final detalle = Map<String, dynamic>.from(respuestas[0].data as Map);
      final creditos = Map<String, dynamic>.from(respuestas[1].data as Map);

      return Pelicula(
        tmdbId: idPelicula,
        tipoMedia: tipoMedia,
        titulo: _leerTexto(
          detalle['title'] ?? detalle['name'],
          fallback: 'Sin título',
        ),
        anio: _extraerAnio(
          detalle['release_date'] ?? detalle['first_air_date'],
        ),
        duracion: _extraerDuracion(
          tipoMedia == TipoMedia.serie
              ? detalle['episode_run_time']
              : detalle['runtime'],
        ),
        genero: _extraerGeneros(detalle['genres']),
        director: _extraerDirector(
          crewRaw: creditos['crew'],
          createdByRaw: detalle['created_by'],
        ),
        sinopsis: _leerTexto(detalle['overview'], fallback: 'Sin sinopsis.'),
        imagen: _construirUrlImagen(detalle['poster_path']),
        rating: _leerDouble(detalle['vote_average']),
      );
    } on DioException catch (error) {
      throw Exception(_traducirErrorDeRed(error));
    }
  }

  Map<String, Object> _armarParametrosBusqueda({
    required String titulo,
    required String anio,
    required String tipoMedia,
    required bool esBusquedaPorTitulo,
  }) {
    final parametros = <String, Object>{
      'api_key': _apiKey,
      'language': 'es-ES',
      'include_adult': false,
    };

    if (esBusquedaPorTitulo) {
      parametros['query'] = titulo;

      if (anio.isNotEmpty) {
        parametros[_parametroAnioBusqueda(tipoMedia)] = anio;
      }

      return parametros;
    }

    parametros['sort_by'] = 'popularity.desc';
    parametros[_parametroAnioDiscover(tipoMedia)] = anio;
    return parametros;
  }

  String _parametroAnioBusqueda(String tipoMedia) {
    return tipoMedia == TipoMedia.serie ? 'first_air_date_year' : 'year';
  }

  String _parametroAnioDiscover(String tipoMedia) {
    return tipoMedia == TipoMedia.serie
        ? 'first_air_date_year'
        : 'primary_release_year';
  }

  String _extraerDirector({Object? crewRaw, Object? createdByRaw}) {
    final crew = List<Map<String, dynamic>>.from(
      (crewRaw as List<dynamic>? ?? <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    for (final persona in crew) {
      if (persona['job'] == 'Director' ||
          persona['known_for_department'] == 'Directing') {
        return _leerTexto(persona['name'], fallback: 'No disponible');
      }
    }

    final creadores = List<Map<String, dynamic>>.from(
      (createdByRaw as List<dynamic>? ?? <dynamic>[]).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    if (creadores.isNotEmpty) {
      final nombres = creadores
          .map((creador) => _leerTexto(creador['name']))
          .where((nombre) => nombre.isNotEmpty)
          .join(', ');

      if (nombres.isNotEmpty) {
        return nombres;
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
    if (runtime is List) {
      for (final valor in runtime) {
        final minutos = valor is int ? valor : int.tryParse('$valor') ?? 0;
        if (minutos > 0) {
          return '$minutos min';
        }
      }

      return 'No disponible';
    }

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
