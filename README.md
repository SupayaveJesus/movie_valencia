# 🎬 Practico 4 - Movies App

Una aplicación Flutter para explorar películas usando la API de TMDB (The Movie Database). Busca películas, visualiza detalles y guarda tu historial de búsquedas.

## 📋 Requisitos Previos

- **Flutter SDK** (versión 3.0 o superior)
- **Dart SDK** (incluido con Flutter)
- **Android Studio** o **Xcode** (para emuladores)
- **Git**

## 🚀 Instalación y Configuración

### 1. Clonar el repositorio
```bash
git clone <url-del-repositorio>
cd practico4_movies
```

### 2. Instalar dependencias Dart/Flutter
```bash
flutter pub get
```

### 3. (Solo para iOS) Instalar dependencias nativas
```bash
cd ios
pod install
cd ..
```

### 4. Ejecutar la aplicación
```bash
# En emulador Android
flutter run

# O especificar un dispositivo
flutter devices  # Ver dispositivos disponibles
flutter run -d <device-id>
```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── config/
│   └── conn.dart              # Configuración de conexión API
├── models/
│   └── pelicula.dart          # Modelo de datos
├── services/
│   └── tmdb_services.dart     # Servicio de API
├── repository/
│   └── pelicula_repository.dart  # Gestión de datos
├── screen/
│   ├── home_screen.dart       # Pantalla principal
│   ├── buscar_screen.dart     # Búsqueda de películas
│   ├── detalle_screen.dart    # Detalles de película
│   └── historial_screen.dart  # Historial de búsquedas
└── widgets/                    # Componentes reutilizables
```

## 🔑 API Key

Este proyecto usa la API de TMDB. Necesitas:

1. Registrarte en [TMDB](https://www.themoviedb.org/)
2. Obtener tu API Key
3. Configurarla en `lib/config/conn.dart`

## 🛠️ Comandos Útiles

```bash
# Limpiar build anterior
flutter clean

# Obtener dependencias actualizado
flutter pub upgrade

# Ejecutar análisis de código
flutter analyze

# Ejecutar pruebas
flutter test
```

## 📚 Documentación Útil

- [Flutter Documentation](https://docs.flutter.dev/)
- [TMDB API](https://www.themoviedb.org/settings/api)
- [Dart Documentation](https://dart.dev/guides)

## 💡 Notas Importantes

- Los archivos de `build/`, `.dart_tool/`, `pubspec.lock` y dependencias se generan automáticamente
- Solo necesitas clonar el repositorio e instalar las dependencias
- Los cambios locales en `android/local.properties` y configuración específica de máquina NO se versionan

## 📝 Licencia

Este es un proyecto educativo para práctico de Flutter.
