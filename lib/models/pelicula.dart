class Pelicula {
  int? id;
  String titulo;
  String anio;
  String duracion;
  String genero;
  String director;
  String sinopsis;
  String imagen;
  double rating;

  Pelicula({
    this.id,
    required this.titulo,
    required this.anio,
    required this.duracion,
    required this.genero,
    required this.director,
    required this.sinopsis,
    required this.imagen,
    required this.rating,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'anio': anio,
      'duracion': duracion,
      'genero': genero,
      'director': director,
      'sinopsis': sinopsis,
      'imagen': imagen,
      'rating': rating,
    };
  }

  factory Pelicula.fromMap(Map<String, dynamic> map) {
    return Pelicula(
      id: map['id'] as int?,
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
    );
  }
}
