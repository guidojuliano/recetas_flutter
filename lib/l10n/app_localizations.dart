import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
  ];

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    return localizations ?? AppLocalizations(const Locale('es'));
  }

  String get _lang {
    final code = locale.languageCode.toLowerCase();
    if (code == 'en' || code == 'pt' || code == 'es') return code;
    return 'es';
  }

  String _t(String key) => _localizedValues[_lang]![key]!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'es': {
      'profile': 'Perfil',
      'myRecipes': 'Mis recetas',
      'logout': 'Cerrar sesión',
      'tabHome': 'Inicio',
      'tabSearch': 'Buscar',
      'tabCategories': 'Categorías',
      'tabFavorites': 'Favoritos',
      'needLoginTitle': 'Necesitas iniciar sesión',
      'needLoginSubtitle':
          'Para acceder a esta función, inicia sesión con Google.',
      'loginWithGoogle': 'INICIAR CON GOOGLE',
      'continueAsGuest': 'Seguir como invitado',
      'login': 'LOGIN',
      'oauthError': 'Error de OAuth: {error}',
      'byAuthor': 'por {name}',
      'noRecipesAvailable': 'No hay recetas disponibles',
      'removeFromFavorites': 'Quitar de favoritos',
      'addToFavorites': 'Agregar a favoritos',
      'ingredientTooLong': 'Ingrediente "{value}" supera 20 caracteres',
      'checkRequiredFields': 'Revisa los campos obligatorios',
      'addAtLeastOneIngredient': 'Agrega al menos un ingrediente',
      'selectCategories': 'Elegir categorías',
      'save': 'Guardar',
      'addNewRecipe': 'Agregar nueva receta',
      'title': 'Título',
      'imageUrl': 'URL de imagen',
      'instructions': 'Instrucciones',
      'loading': 'Cargando...',
      'createRecipe': 'Crear receta',
      'creating': 'Creando...',
      'pleaseEnterField': 'Completa {field}',
      'ingredients': 'Ingredientes',
      'ingredientHint': 'Escribe ingrediente y presiona Enter',
      'noCategoriesSelected': 'Sin categorías seleccionadas',
      'searchHint': 'Buscar por receta, autor, ingrediente o categoría',
      'typeToSearchRecipes': 'Escribe algo para buscar recetas',
      'categoryLoadError': 'Error cargando categorías:\n{error}',
      'noCategoriesAvailable': 'No hay categorías disponibles',
      'recipesLoadError': 'Error cargando recetas:\n{error}',
      'noRecipesForCategory': 'No hay recetas para {category}',
      'noFavoritesYet': 'Todavía no marcaste recetas como favoritas',
      'favoritesRequireLogin': 'Inicia sesión para ver tus favoritos',
      'myRecipesLoadError': 'Error cargando tus recetas:\n{error}',
      'noCreatedRecipesYet': 'No tienes recetas creadas todavía',
      'deleteRecipeTitle': 'Eliminar receta',
      'deleteRecipeConfirm':
          '¿Seguro que quieres eliminar esta receta? Esta acción no se puede deshacer.',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'recipeDeleted': 'Receta eliminada',
      'couldNotDelete': 'No se pudo eliminar: {error}',
      'edit': 'Editar',
      'editRecipe': 'Editar receta',
      'titleRequired': 'El título es obligatorio',
      'instructionsRequired': 'Las instrucciones son obligatorias',
      'addIngredientAndPressEnter': 'Agrega ingrediente y presiona Enter',
      'couldNotUpdate': 'No se pudo actualizar: {error}',
      'saving': 'Guardando...',
      'saveChanges': 'Guardar cambios',
      'noSearchResults': 'No encontramos resultados para "{query}"',
      'loginPending': 'Login pendiente',
      'join': 'Unirse',
      'signupPending': 'Registro pendiente',
      'couldNotLoadCategories': 'No se pudieron cargar categorías',
      'genericError': 'Error: {error}',
    },
    'en': {
      'profile': 'Profile',
      'myRecipes': 'My recipes',
      'logout': 'Log out',
      'tabHome': 'Home',
      'tabSearch': 'Search',
      'tabCategories': 'Categories',
      'tabFavorites': 'Favorites',
      'needLoginTitle': 'You need to sign in',
      'needLoginSubtitle': 'To access this feature, sign in with Google.',
      'loginWithGoogle': 'LOGIN WITH GOOGLE',
      'continueAsGuest': 'Continue as guest',
      'login': 'LOGIN',
      'oauthError': 'OAuth error: {error}',
      'byAuthor': 'by {name}',
      'noRecipesAvailable': 'No recipes available',
      'removeFromFavorites': 'Remove from favorites',
      'addToFavorites': 'Add to favorites',
      'ingredientTooLong': 'Ingredient "{value}" exceeds 20 characters',
      'checkRequiredFields': 'Check required fields',
      'addAtLeastOneIngredient': 'Add at least one ingredient',
      'selectCategories': 'Choose categories',
      'save': 'Save',
      'addNewRecipe': 'Add New Recipe',
      'title': 'Title',
      'imageUrl': 'Image URL',
      'instructions': 'Instructions',
      'loading': 'Loading...',
      'createRecipe': 'Create Recipe',
      'creating': 'Creating...',
      'pleaseEnterField': 'Please enter {field}',
      'ingredients': 'Ingredients',
      'ingredientHint': 'Type ingredient and press Enter',
      'noCategoriesSelected': 'No categories selected',
      'searchHint': 'Search by recipe, author, ingredient or category',
      'typeToSearchRecipes': 'Type something to search recipes',
      'categoryLoadError': 'Error loading categories:\n{error}',
      'noCategoriesAvailable': 'No categories available',
      'recipesLoadError': 'Error loading recipes:\n{error}',
      'noRecipesForCategory': 'No recipes for {category}',
      'noFavoritesYet': 'You have not marked any recipes as favorites yet',
      'favoritesRequireLogin': 'Sign in to view your favorites',
      'myRecipesLoadError': 'Error loading your recipes:\n{error}',
      'noCreatedRecipesYet': 'You have not created any recipes yet',
      'deleteRecipeTitle': 'Delete recipe',
      'deleteRecipeConfirm':
          'Are you sure you want to delete this recipe? This action cannot be undone.',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'recipeDeleted': 'Recipe deleted',
      'couldNotDelete': 'Could not delete: {error}',
      'edit': 'Edit',
      'editRecipe': 'Edit recipe',
      'titleRequired': 'Title is required',
      'instructionsRequired': 'Instructions are required',
      'addIngredientAndPressEnter': 'Add ingredient and press Enter',
      'couldNotUpdate': 'Could not update: {error}',
      'saving': 'Saving...',
      'saveChanges': 'Save changes',
      'noSearchResults': 'No results found for "{query}"',
      'loginPending': 'Login pending',
      'join': 'Join',
      'signupPending': 'Signup pending',
      'couldNotLoadCategories': 'Could not load categories',
      'genericError': 'Error: {error}',
    },
    'pt': {
      'profile': 'Perfil',
      'myRecipes': 'Minhas receitas',
      'logout': 'Sair',
      'tabHome': 'Início',
      'tabSearch': 'Buscar',
      'tabCategories': 'Categorias',
      'tabFavorites': 'Favoritos',
      'needLoginTitle': 'Você precisa entrar',
      'needLoginSubtitle': 'Para acessar este recurso, entre com o Google.',
      'loginWithGoogle': 'ENTRAR COM GOOGLE',
      'continueAsGuest': 'Continuar como convidado',
      'login': 'LOGIN',
      'oauthError': 'Erro de OAuth: {error}',
      'byAuthor': 'por {name}',
      'noRecipesAvailable': 'Não há receitas disponíveis',
      'removeFromFavorites': 'Remover dos favoritos',
      'addToFavorites': 'Adicionar aos favoritos',
      'ingredientTooLong': 'Ingrediente "{value}" excede 20 caracteres',
      'checkRequiredFields': 'Revise os campos obrigatórios',
      'addAtLeastOneIngredient': 'Adicione pelo menos um ingrediente',
      'selectCategories': 'Escolher categorias',
      'save': 'Salvar',
      'addNewRecipe': 'Adicionar nova receita',
      'title': 'Título',
      'imageUrl': 'URL da imagem',
      'instructions': 'Instruções',
      'loading': 'Carregando...',
      'createRecipe': 'Criar receita',
      'creating': 'Criando...',
      'pleaseEnterField': 'Preencha {field}',
      'ingredients': 'Ingredientes',
      'ingredientHint': 'Digite o ingrediente e pressione Enter',
      'noCategoriesSelected': 'Nenhuma categoria selecionada',
      'searchHint': 'Buscar por receita, autor, ingrediente ou categoria',
      'typeToSearchRecipes': 'Digite algo para buscar receitas',
      'categoryLoadError': 'Erro ao carregar categorias:\n{error}',
      'noCategoriesAvailable': 'Não há categorias disponíveis',
      'recipesLoadError': 'Erro ao carregar receitas:\n{error}',
      'noRecipesForCategory': 'Não há receitas para {category}',
      'noFavoritesYet': 'Você ainda não marcou receitas como favoritas',
      'favoritesRequireLogin': 'Entre para ver seus favoritos',
      'myRecipesLoadError': 'Erro ao carregar suas receitas:\n{error}',
      'noCreatedRecipesYet': 'Você ainda não criou receitas',
      'deleteRecipeTitle': 'Excluir receita',
      'deleteRecipeConfirm':
          'Tem certeza de que deseja excluir esta receita? Esta ação não pode ser desfeita.',
      'cancel': 'Cancelar',
      'delete': 'Excluir',
      'recipeDeleted': 'Receita excluída',
      'couldNotDelete': 'Não foi possível excluir: {error}',
      'edit': 'Editar',
      'editRecipe': 'Editar receita',
      'titleRequired': 'O título é obrigatório',
      'instructionsRequired': 'As instruções são obrigatórias',
      'addIngredientAndPressEnter': 'Adicione o ingrediente e pressione Enter',
      'couldNotUpdate': 'Não foi possível atualizar: {error}',
      'saving': 'Salvando...',
      'saveChanges': 'Salvar alterações',
      'noSearchResults': 'Não encontramos resultados para "{query}"',
      'loginPending': 'Login pendente',
      'join': 'Entrar',
      'signupPending': 'Cadastro pendente',
      'couldNotLoadCategories': 'Não foi possível carregar categorias',
      'genericError': 'Erro: {error}',
    },
  };

  String get profile => _t('profile');
  String get myRecipes => _t('myRecipes');
  String get logout => _t('logout');
  String get tabHome => _t('tabHome');
  String get tabSearch => _t('tabSearch');
  String get tabCategories => _t('tabCategories');
  String get tabFavorites => _t('tabFavorites');
  String get needLoginTitle => _t('needLoginTitle');
  String get needLoginSubtitle => _t('needLoginSubtitle');
  String get loginWithGoogle => _t('loginWithGoogle');
  String get continueAsGuest => _t('continueAsGuest');
  String get login => _t('login');
  String get noRecipesAvailable => _t('noRecipesAvailable');
  String get removeFromFavorites => _t('removeFromFavorites');
  String get addToFavorites => _t('addToFavorites');
  String get checkRequiredFields => _t('checkRequiredFields');
  String get addAtLeastOneIngredient => _t('addAtLeastOneIngredient');
  String get selectCategories => _t('selectCategories');
  String get save => _t('save');
  String get addNewRecipe => _t('addNewRecipe');
  String get title => _t('title');
  String get imageUrl => _t('imageUrl');
  String get instructions => _t('instructions');
  String get loading => _t('loading');
  String get createRecipe => _t('createRecipe');
  String get creating => _t('creating');
  String get ingredients => _t('ingredients');
  String get ingredientHint => _t('ingredientHint');
  String get noCategoriesSelected => _t('noCategoriesSelected');
  String get searchHint => _t('searchHint');
  String get typeToSearchRecipes => _t('typeToSearchRecipes');
  String get noCategoriesAvailable => _t('noCategoriesAvailable');
  String get noFavoritesYet => _t('noFavoritesYet');
  String get favoritesRequireLogin => _t('favoritesRequireLogin');
  String get noCreatedRecipesYet => _t('noCreatedRecipesYet');
  String get deleteRecipeTitle => _t('deleteRecipeTitle');
  String get deleteRecipeConfirm => _t('deleteRecipeConfirm');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get recipeDeleted => _t('recipeDeleted');
  String get edit => _t('edit');
  String get editRecipe => _t('editRecipe');
  String get titleRequired => _t('titleRequired');
  String get instructionsRequired => _t('instructionsRequired');
  String get addIngredientAndPressEnter => _t('addIngredientAndPressEnter');
  String get saving => _t('saving');
  String get saveChanges => _t('saveChanges');
  String get loginPending => _t('loginPending');
  String get join => _t('join');
  String get signupPending => _t('signupPending');
  String get couldNotLoadCategories => _t('couldNotLoadCategories');

  String oauthError(String error) =>
      _t('oauthError').replaceAll('{error}', error);
  String byAuthor(String name) => _t('byAuthor').replaceAll('{name}', name);
  String ingredientTooLong(String value) =>
      _t('ingredientTooLong').replaceAll('{value}', value);
  String pleaseEnterField(String field) =>
      _t('pleaseEnterField').replaceAll('{field}', field);
  String categoryLoadError(String error) =>
      _t('categoryLoadError').replaceAll('{error}', error);
  String recipesLoadError(String error) =>
      _t('recipesLoadError').replaceAll('{error}', error);
  String noRecipesForCategory(String category) =>
      _t('noRecipesForCategory').replaceAll('{category}', category);
  String myRecipesLoadError(String error) =>
      _t('myRecipesLoadError').replaceAll('{error}', error);
  String couldNotDelete(String error) =>
      _t('couldNotDelete').replaceAll('{error}', error);
  String couldNotUpdate(String error) =>
      _t('couldNotUpdate').replaceAll('{error}', error);
  String noSearchResults(String query) =>
      _t('noSearchResults').replaceAll('{query}', query);
  String genericError(String error) =>
      _t('genericError').replaceAll('{error}', error);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en', 'pt'].contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
