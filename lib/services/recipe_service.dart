import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'recipes';

  Stream<List<Recipe>> recipesStream(String userId) {
    return _db
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Recipe.fromFirestore(d)).toList());
  }

  Future<void> addRecipe(Recipe recipe) async {
    // Check for duplicate name (case-insensitive) for the same user
    final query = await _db
        .collection(_collection)
        .where('userId', isEqualTo: recipe.userId)
        .where('name_lowercase', isEqualTo: recipe.name.toLowerCase().trim())
        .get();

    if (query.docs.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'A recipe with this name already exists.',
      );
    }

    await _db.collection(_collection).add(recipe.toFirestore());
  }

  Future<void> updateRecipe(Recipe recipe) async {
    // Check for duplicate name (case-insensitive), excluding current recipe
    final query = await _db
        .collection(_collection)
        .where('userId', isEqualTo: recipe.userId)
        .where('name_lowercase', isEqualTo: recipe.name.toLowerCase().trim())
        .get();

    final duplicate = query.docs.where((d) => d.id != recipe.id).toList();
    if (duplicate.isNotEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'A recipe with this name already exists.',
      );
    }

    await _db.collection(_collection).doc(recipe.id).update(recipe.toFirestore());
  }

  Future<void> deleteRecipe(String recipeId) async {
    await _db.collection(_collection).doc(recipeId).delete();
  }

  Future<void> toggleFavorite(String recipeId, bool currentValue) async {
    await _db.collection(_collection).doc(recipeId).update({
      'favorite': !currentValue,
    });
  }
}
