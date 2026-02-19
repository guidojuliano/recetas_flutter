# Cookly Flutter App

Aplicación móvil Flutter para explorar, crear y administrar recetas conectada a una API REST + Supabase Auth.

## Stack

- Flutter (SDK 3.10+)
- Provider (estado)
- Supabase Auth (Google OAuth + sesión)
- HTTP REST API (`recipes-api`)
- Freezed + json_serializable (modelos)

## Funcionalidad actual (MVP)

- Login con Google y modo invitado.
- Tabs principales:
  - `Home`
  - `Search`
  - `Categories`
  - `Favorites`
- CRUD de recetas (según permisos del autor).
- Favoritos solo para usuarios autenticados.
- Localización de UI por idioma del dispositivo:
  - Español (`es`)
  - Inglés (`en`)
  - Portugués (`pt`)
- Categorías localizadas desde backend.

## Requisitos

- Flutter SDK instalado
- Proyecto API corriendo (`recipes-api`)
- Supabase configurado (Auth + tabla `profiles`)

## Variables de entorno

Crear `.env` en la raíz del proyecto Flutter:

```env
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
API_URL=http://<host>:<port>
```

Referencia: `.env.example`.

## Ejecutar

```bash
flutter pub get
flutter run
```

## Estructura principal

- `lib/main.dart`: bootstrap, providers, tabs.
- `lib/providers/recipes_providers.dart`: carga/actualización de recetas.
- `lib/providers/favorites_provider.dart`: favoritos por usuario autenticado.
- `lib/screens/`: pantallas de UI.
- `lib/l10n/app_localizations.dart`: textos de interfaz.
- `lib/services/category_catalog_service.dart`: catálogo de categorías desde API.
- `lib/models/recipes_model.dart`: modelo `Recipe`/`Profile`.

## Contrato API esperado (resumen)

- `GET /categories?lang=es|en|pt`
  - devuelve array con categorías (incluye `id`, `name`, y opcionalmente campos de traducción).
- `GET /recipes?lang=...`
  - devuelve recetas con `recipe_categories` conteniendo `category_id`.
- `GET /me/favorites?lang=...`
  - devuelve recetas favoritas del usuario autenticado.
- `POST /recipes`, `PATCH /recipes/:id`, `DELETE /recipes/:id`
- `POST /recipes/:id/favorite`, `DELETE /recipes/:id/favorite`

## Calidad / verificación recomendada

```bash
dart analyze
dart format --set-exit-if-changed .
```

## Notas

- El contenido de recetas/publicaciones (título, ingredientes, instrucciones) no se traduce automáticamente.
