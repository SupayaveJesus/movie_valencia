import 'package:dio/dio.dart';
import '../models/pelicula.dart';

class TmdbService {
  final Dio _dio = Dio();

  final String _apiKey = 'TU_API_KEY_AQUI';
  final String _baseUrl = 'https://api.themoviedb.org/3';
  final String _imagenUrl = 'https://image.tmdb.org/t/p/w500';

  Future<List<dynamic>> buscarPeliculas(String titulo, String anio) async {
    final respuesta = await _dio.get(
      '$_baseUrl/search/movie',
      queryParameters: {
        'api_key': _apiKey,
        'query': titulo,
        'language': 'es-ES',
        if (anio.isNotEmpty) 'year': anio,
      },
    );

    return respuesta.data['results'];
  }

  Future<Pelicula> obtenerDetallePelicula(int idPelicula) async {
    final detalle = await _dio.get(
      '$_baseUrl/movie/$idPelicula',
      queryParameters: {
        'api_key': _apiKey,
        'language': 'es-ES',
      },
    );

    final creditos = await _dio.get(
      '$_baseUrl/movie/$idPelicula/credits',
      queryParameters: {
        'api_key': _apiKey,
        'language': 'es-ES',
      },
    );

    String director = 'No disponible';

    for (var persona in creditos.data['crew']) {
      if (persona['job'] == 'Director') {
        director = persona['name'];
        break;
      }
    }

    String generos = '';
    for (var genero in detalle.data['genres']) {
      generos += '${genero['name']}, ';
    }

    if (generos.isNotEmpty) {
      generos = generos.substring(0, generos.length - 2);
    } else {
      generos = 'No disponible';
    }

    String anio = 'No disponible';

    if (detalle.data['release_date'] != null &&
        detalle.data['release_date'].toString().isNotEmpty) {
      anio = detalle.data['release_date'].toString().split('-')[0];
    }

    String imagen = '';

    if (detalle.data['poster_path'] != null) {
      imagen = '$_imagenUrl${detalle.data['poster_path']}';
    }

    return Pelicula(
      titulo: detalle.data['title'] ?? 'Sin título',
      anio: anio,
      duracion: '${detalle.data['runtime'] ?? 0} min',
      genero: generos,
      director: director,
      sinopsis: detalle.data['overview'] ?? 'Sin sinopsis',
      imagen: imagen,
      rating: (detalle.data['vote_average'] ?? 0).toDouble(),
    );
  }
}