import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> inicializarBaseDatos() async {
  return openDatabase(
    join(await getDatabasesPath(), 'peliculasDb.db'),
    onCreate: (db, version) {
      return db.execute('''
        CREATE TABLE pelicula(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tmdb_id INTEGER,
          titulo TEXT,
          anio TEXT,
          duracion TEXT,
          genero TEXT,
          director TEXT,
          sinopsis TEXT,
          imagen TEXT,
          rating REAL,
          consultado_en INTEGER
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        // El historial previo era un placeholder. La migración agrega el id de
        // TMDB y la marca de tiempo para poder persistir aperturas reales y
        // reordenarlas sin duplicar entradas del mismo detalle.
        await db.execute('ALTER TABLE pelicula ADD COLUMN tmdb_id INTEGER');
        await db.execute(
          'ALTER TABLE pelicula ADD COLUMN consultado_en INTEGER',
        );
        await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_pelicula_tmdb_id ON pelicula(tmdb_id)',
        );
      }
    },
    onOpen: (db) async {
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_pelicula_tmdb_id ON pelicula(tmdb_id)',
      );
    },
    version: 2,
  );
}

final baseDatos = inicializarBaseDatos();
