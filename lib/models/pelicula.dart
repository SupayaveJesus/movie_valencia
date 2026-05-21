/// Modelo usado para el detalle completo de la película y para persistir
/// ese snapshot en la base local.
///
/// Lo mantenemos separado del resultado de búsqueda porque la pantalla de lista
/// solo necesita un subconjunto del payload de TMDB. Esa separación hace más
/// evidente qué datos pertenecen a cada paso del flujo.
class Pelicula {
  /// `id` es la clave local de SQLite.
  /// `tmdbId` identifica la película en TMDB.
  ///
  /// Mantener ambos ids separados evita mezclar identidad local con identidad
  /// remota. El primero organiza la tabla; el segundo nos permite reconocer la
  /// misma película cuando vuelve desde la API y refrescar su snapshot sin crear
  /// duplicados en historial.
  final int? id;
  final int? tmdbId;
  final String titulo;
  final String anio;
  final String duracion;
  final String genero;
  final String director;
  final String sinopsis;
  final String imagen;
  final double rating;
  final DateTime? consultadoEn;

  Pelicula({
    this.id,
    this.tmdbId,
    required this.titulo,
    required this.anio,
    required this.duracion,
    required this.genero,
    required this.director,
    required this.sinopsis,
    required this.imagen,
    required this.rating,
    this.consultadoEn,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'titulo': titulo,
      'anio': anio,
      'duracion': duracion,
      'genero': genero,
      'director': director,
      'sinopsis': sinopsis,
      'imagen': imagen,
      'rating': rating,
      'consultado_en': consultadoEn?.millisecondsSinceEpoch,
    };
  }

  factory Pelicula.fromMap(Map<String, dynamic> map) {
    return Pelicula(
      id: map['id'] as int?,
      tmdbId: map['tmdb_id'] as int?,
      titulo: map['titulo'] as String,
      anio: map['anio'] as String,
      duracion: map['duracion'] as String,
      genero: map['genero'] as String,
      director: map['director'] as String,
      sinopsis: map['sinopsis'] as String,
      imagen: map['imagen'] as String,
      rating: (map['rating'] is int)
          ? (map['rating'] as int).toDouble()
          : (map['rating'] as double? ?? 0.0),
      consultadoEn: map['consultado_en'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['consultado_en'] as int),
    );
  }
}

/// Resultado liviano para la pantalla de búsqueda.
///
/// Representa EXACTAMENTE lo que la lista necesita renderizar y navegar al
/// detalle: id, título, fecha y poster. Nada más.
class PeliculaResumen {
  final int id;
  final String titulo;
  final String fechaEstreno;
  final String imagen;

  const PeliculaResumen({
    required this.id,
    required this.titulo,
    required this.fechaEstreno,
    required this.imagen,
  });

  String get anio {
    if (fechaEstreno.isEmpty) {
      return 'Año no disponible';
    }

    return fechaEstreno.split('-').first;
  }
}
