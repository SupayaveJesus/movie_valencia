import 'package:sqflite/sqflite.dart';

import '../config/conn.dart';
import '../models/pelicula.dart';

class PeliculaRepository {
  Future<void> guardarEnHistorial(Pelicula pelicula) async {
    final db = await baseDatos;

    // `tmdb_id` es único. Reemplazar acá significa conservar una sola fila por
    // película remota y actualizar su snapshot/local timestamp cada vez que el
    // usuario vuelve a seleccionarla.
    await db.insert(
      'pelicula',
      pelicula.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Pelicula>> listar() async {
    final db = await baseDatos;

    final List<Map<String, dynamic>> maps = await db.query(
      'pelicula',
      orderBy: 'consultado_en DESC, id DESC',
    );

    return List.generate(maps.length, (i) {
      return Pelicula.fromMap(maps[i]);
    });
  }

  Future<void> eliminarTodo() async {
    final db = await baseDatos;
    await db.delete('pelicula');
  }
}
