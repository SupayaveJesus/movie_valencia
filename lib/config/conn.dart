import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> inicializarBaseDatos() async {
  return openDatabase(
    join(await getDatabasesPath(), 'peliculasDb.db'),
    onCreate: (db, version) {
      return db.execute('''
        CREATE TABLE pelicula(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          anio TEXT,
          duracion TEXT,
          genero TEXT,
          director TEXT,
          sinopsis TEXT,
          imagen TEXT,
          rating REAL
        )
      ''');
    },
    version: 1,
  );
}

final baseDatos = inicializarBaseDatos();