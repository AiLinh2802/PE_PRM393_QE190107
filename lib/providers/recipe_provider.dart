import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeService _service = RecipeService();

  List<Recipe> _allRecipes = [];
  StreamSubscription? _subscription;

  // Filter state
  String _categoryFilter = 'All';
  String _difficultyFilter = 'All';
  bool _favoritesOnly = false;
  String _searchQuery = '';

  String get categoryFilter => _categoryFilter;
  String get difficultyFilter => _difficultyFilter;
  bool get favoritesOnly => _favoritesOnly;
  String get searchQuery => _searchQuery;

  void listenToRecipes(String userId) {
    _subscription?.cancel();
    _subscription = _service.recipesStream(userId).listen((recipes) {
      _allRecipes = recipes;
      notifyListeners();
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _allRecipes = [];
    _categoryFilter = 'All';
    _difficultyFilter = 'All';
    _favoritesOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  List<Recipe> get filteredRecipes {
    List<Recipe> result = List.from(_allRecipes);

    if (_categoryFilter != 'All') {
      result = result.where((r) => r.category == _categoryFilter).toList();
    }
    if (_difficultyFilter != 'All') {
      result = result.where((r) => r.difficulty == _difficultyFilter).toList();
    }
    if (_favoritesOnly) {
      result = result.where((r) => r.favorite).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        result = result.where((r) {
          return r.name.toLowerCase().contains(q) ||
              (r.notes?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    }

    // Sort: cookTime ASC, then name ASC (case-insensitive)
    result.sort((a, b) {
      final cmp = a.cookTime.compareTo(b.cookTime);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return result;
  }

  int get totalRecipes => filteredRecipes.length;
  int get totalFavorites => filteredRecipes.where((r) => r.favorite).length;
  int get totalCookTime =>
      filteredRecipes.fold(0, (sum, r) => sum + r.cookTime);

  Map<String, int> get categoryBreakdown {
    final map = <String, int>{};
    for (final r in filteredRecipes) {
      map[r.category] = (map[r.category] ?? 0) + 1;
    }
    // Sort by count DESC, tie-break by predefined category order
    final order = ['Breakfast', 'Lunch', 'Dinner', 'Dessert'];
    final entries = map.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return order.indexOf(a.key).compareTo(order.indexOf(b.key));
      });
    return Map.fromEntries(entries);
  }

  void setCategoryFilter(String value) {
    _categoryFilter = value;
    notifyListeners();
  }

  void setDifficultyFilter(String value) {
    _difficultyFilter = value;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = 'All';
    _difficultyFilter = 'All';
    _favoritesOnly = false;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> addRecipe(Recipe recipe) async {
    await _service.addRecipe(recipe);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _service.updateRecipe(recipe);
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _service.deleteRecipe(recipeId);
  }

  Future<void> toggleFavorite(String recipeId, bool currentValue) async {
    await _service.toggleFavorite(recipeId, currentValue);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
