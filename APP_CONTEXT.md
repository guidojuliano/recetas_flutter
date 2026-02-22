# App Context: recetas_flutter

Ultima actualizacion: 19-02-2026

## Resumen
- App Flutter de recetas (Cookly) conectada a una API REST y Supabase Auth.
- Soporta login con Google y modo invitado.
- Tiene navegacion principal por tabs: Home, Search, Categories y Favorites.
- Estado global con `provider` (`RecipesProvider`, `FavoritesProvider`).
- UI localizada en espanol, ingles y portugues segun locale del dispositivo.

## Stack y dependencias principales
- Flutter SDK 3.10+
- `provider` para estado
- `http` para llamadas REST
- `supabase_flutter` para autenticacion/sesion
- `flutter_dotenv` para config por entorno
- `freezed` + `json_serializable` para modelos
- `cached_network_image` + `flutter_svg` para imagenes/fallback
- `google_fonts` (Poppins)

## Configuracion de entorno
- Archivo `.env` requerido en raiz:
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
  - `API_URL` (opcional, fallback: `https://recipes-api-silk.vercel.app`)
- `lib/config/env_config.dart` centraliza lectura de variables.

## Entry point y navegacion
- `lib/main.dart`
  - Carga `.env`, valida credenciales Supabase e inicializa cliente.
  - Registra `MultiProvider` con:
    - `RecipesProvider`
    - `FavoritesProvider`
  - `home` inicial: `InitialScreen`.
- `InitialScreen`
  - Si hay sesion activa, redirige a `RecipeBook`.
  - Login OAuth Google.
  - Hace upsert de perfil en tabla `profiles` (`id`, `display_name`, `avatar_url`).
  - Permite continuar como invitado.
- `RecipeBook`
  - `DefaultTabController` con 4 tabs funcionales:
    - `HomeScreen`
    - `SearchScreen`
    - `CategoriesScreen`
    - `FavoritesScreen`
  - AppBar con avatar y hoja de perfil:
    - Ir a `MyRecipesScreen`
    - Cerrar sesion

## Modelo de datos
- `lib/models/recipes_model.dart`
  - `Recipe`:
    - `id`
    - `owner` (`Profile`)
    - `title`
    - `imageUrl` (mapea `image_url`)
    - `ingredients` (`List<String>`)
    - `instructions`
    - `categories` (`List<String>`, mapea desde `recipe_categories[].category_id`)
  - `Profile`:
    - `id`
    - `displayName` (mapea `display_name`)
    - `avatarUrl` (mapea `avatar_url`)

## Providers y flujo de estado
- `lib/providers/recipes_providers.dart`
  - Estado: `isLoading`, `recipes`.
  - `fetchRecipes()` -> `GET /recipes?lang=<es|en|pt>`.
  - `fetchRecipesByOwnerId(ownerId)` -> `GET /recipes?owner_id=...&lang=...`.
  - `updateRecipe(...)` -> `PATCH /recipes/:id` (Bearer token).
  - `deleteRecipe(...)` -> `DELETE /recipes/:id` (Bearer token).
- `lib/providers/favorites_provider.dart`
  - Estado: set de IDs favoritos.
  - Escucha cambios de auth para recargar favoritos.
  - `toggleFavorite(recipeId)`:
    - `POST /recipes/:id/favorite` o `DELETE /recipes/:id/favorite`
    - Actualizacion optimista en UI
  - Carga inicial: `GET /me/favorites?lang=...` (requiere sesion).

## Pantallas implementadas
- `lib/screens/home_screen.dart`
  - Lista principal de recetas.
  - FAB para crear receta (si invitado, abre `guest_login_sheet`).
  - Bottom sheet `RecipeForm` para crear receta:
    - Campos: titulo, imagen URL opcional, ingredientes, instrucciones, categorias.
    - Carga categorias desde `GET /categories?lang=...`.
    - Crea receta con `POST /recipes` + Bearer token.
- `lib/screens/recipe_detail.dart`
  - Muestra imagen, autor, categorias, ingredientes e instrucciones.
  - Permite favorito.
  - Si el usuario es autor: editar y eliminar receta.
  - Edicion via bottom sheet (`PATCH /recipes/:id`).
  - Eliminacion con confirmacion (`DELETE /recipes/:id`).
- `lib/screens/search_screen.dart`
  - Busqueda local con debounce (300ms) sobre recetas cargadas.
  - Filtra por titulo, autor, ingredientes y categoria.
  - Normaliza acentos para mejorar matching.
- `lib/screens/categories_screen.dart`
  - Carga categorias desde backend y muestra listado visual.
  - Navega a `CategoryRecipesScreen`.
- `lib/screens/category_recipes_screen.dart`
  - Filtra recetas por categoria (id como string).
  - Soporta pull-to-refresh.
- `lib/screens/favorites_screen.dart`
  - Requiere sesion para visualizar favoritos.
  - Lista recetas favoritas del usuario autenticado.
- `lib/screens/my_recipes_screen.dart`
  - Lista recetas del usuario actual (`owner_id`).
  - Soporta pull-to-refresh.
- `lib/screens/login_screen.dart` y `lib/screens/signup_screen.dart`
  - Pantallas placeholder (pendientes).

## Localizacion (i18n)
- `lib/l10n/app_localizations.dart`
  - Idiomas soportados: `es`, `en`, `pt`.
  - Strings centralizados con placeholders (`{error}`, `{name}`, etc.).
- Los requests a API incluyen `lang` segun locale del dispositivo.

## Servicios y utilidades
- `lib/services/category_catalog_service.dart`
  - Carga y cachea categorias (`/categories?lang=...`).
  - Expone mapa id->nombre para detalle y busqueda.
- `lib/utils/category_translation.dart`
  - Resuelve traducciones de categorias desde distintas formas de payload.
- `lib/widgets/recipe_image.dart`
  - Muestra imagen remota con cache.
  - Maneja `data:image/svg+xml`.
  - Fallback a asset (`assets/images/logo.PNG`).
- `lib/widgets/guest_login_sheet.dart`
  - Bottom sheet para pedir login cuando una accion requiere autenticacion.

## Contrato API que usa hoy la app
- `GET /recipes?lang=...`
- `GET /recipes?owner_id=...&lang=...`
- `POST /recipes`
- `PATCH /recipes/:id`
- `DELETE /recipes/:id`
- `GET /categories?lang=...`
- `GET /me/favorites?lang=...`
- `POST /recipes/:id/favorite`
- `DELETE /recipes/:id/favorite`

## Assets y docs
- Assets: `assets/images/` (logos, fondo, imagen de ejemplo).
- Capturas/documentacion visual: `docs/images/`.

## Estado actual / pendientes
- Flujo MVP principal operativo: auth, listado, busqueda, categorias, favoritos, CRUD (autor).
- `login_screen.dart` y `signup_screen.dart` siguen como placeholders.
- El provider de recetas tiene `notifyListeners()` redundante en `fetchRecipes()` (posible mejora tecnica).
