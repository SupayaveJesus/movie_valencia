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
          tipo_media TEXT,
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
        // reordenarlas.
        await db.execute('ALTER TABLE pelicula ADD COLUMN tmdb_id INTEGER');
        await db.execute(
          'ALTER TABLE pelicula ADD COLUMN consultado_en INTEGER',
        );
      }

      if (oldVersion < 3) {
        // El historial del práctico representa consultas realizadas. Por eso
        // cada apertura debe persistirse como evento independiente.
        await db.execute(
          "ALTER TABLE pelicula ADD COLUMN tipo_media TEXT DEFAULT 'movie'",
        );
        await db.execute('DROP INDEX IF EXISTS idx_pelicula_tmdb_id');
      }
    },
    onOpen: (db) async {
      await db.execute('DROP INDEX IF EXISTS idx_pelicula_tmdb_id');
    },
    version: 3,
  );
}

final baseDatos = inicializarBaseDatos();
