import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/recipe_provider.dart';
import 'detail_screen.dart';
import 'home_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _searchCtrl = TextEditingController();

  // Add recipe form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cookTimeCtrl = TextEditingController();
  final _servingsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _formSubmitted = false;
  bool _formLoading = false;
  String? _formError;
  String? _formSuccess;
  bool _showAddForm = false;

  static const List<String> _categories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert'
  ];
  static const List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      context.read<RecipeProvider>().setSearchQuery(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _cookTimeCtrl.dispose();
    _servingsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Validators ──

  String? _validateName(String? val) {
    if (!_formSubmitted) return null;
    if (val == null || val.trim().isEmpty) return 'Name is required';
    if (val.trim().length > 80) {
      return 'Name must be at most 80 characters';
    }
    return null;
  }

  String? _validateCategory(String? val) {
    if (!_formSubmitted) return null;
    if (val == null || val.isEmpty) return 'Please choose a category';
    return null;
  }

  String? _validateDifficulty(String? val) {
    if (!_formSubmitted) return null;
    if (val == null || val.isEmpty) return 'Please choose a difficulty';
    return null;
  }

  String? _validateCookTime(String? val) {
    if (!_formSubmitted) return null;
    if (val == null || val.trim().isEmpty) return 'Cook time is required';
    final n = int.tryParse(val.trim());
    if (n == null || n < 1 || n > 600) {
      return 'Cook time must be a whole number from 1 to 600';
    }
    return null;
  }

  String? _validateServings(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final n = int.tryParse(val.trim());
    if (n == null || n < 1 || n > 20) {
      return 'Servings must be a whole number from 1 to 20';
    }
    return null;
  }

  String? _validateNotes(String? val) {
    if (val != null && val.length > 300) {
      return 'Notes must be at most 300 characters';
    }
    return null;
  }

  // ── Submit add form ──

  Future<void> _submitForm() async {
    setState(() {
      _formSubmitted = true;
      _formError = null;
      _formSuccess = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _formLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final recipe = Recipe(
        id: '',
        userId: user.uid,
        name: _nameCtrl.text.trim(),
        category: _selectedCategory!,
        difficulty: _selectedDifficulty!,
        cookTime: int.parse(_cookTimeCtrl.text.trim()),
        servings: _servingsCtrl.text.trim().isEmpty
            ? null
            : int.parse(_servingsCtrl.text.trim()),
        favorite: false,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<RecipeProvider>().addRecipe(recipe);

      if (mounted) {
        setState(() {
          _formSuccess = 'Recipe added';
          _formLoading = false;
          _formSubmitted = false;
          _nameCtrl.clear();
          _cookTimeCtrl.clear();
          _servingsCtrl.clear();
          _notesCtrl.clear();
          _selectedCategory = null;
          _selectedDifficulty = null;
        });
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(() {
          _formError = e.message ?? 'Failed to add recipe.';
          _formLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _formError = e.toString();
          _formLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await context.read<app_auth.AuthProvider>().signOut();
    context.read<RecipeProvider>().stopListening();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final recipeProvider = context.watch<RecipeProvider>();
    final filtered = recipeProvider.filteredRecipes;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            user?.email ?? 'RecipeBox',
            style: const TextStyle(fontSize: 14),
          ),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: _logout,
              child: const Text('Logout',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Column(
          children: [
            // Summary
            _buildSummary(recipeProvider),
            // Filter bar
            _buildFilterBar(recipeProvider),
            // Add recipe toggle
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recipes',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _showAddForm = !_showAddForm;
                      if (!_showAddForm) {
                        _formSubmitted = false;
                        _formError = null;
                        _formSuccess = null;
                      }
                    }),
                    icon: Icon(
                        _showAddForm ? Icons.close : Icons.add),
                    label: Text(
                        _showAddForm ? 'Cancel' : 'Add Recipe'),
                  ),
                ],
              ),
            ),
            // Add form
            if (_showAddForm) _buildAddForm(),
            // Recipe list
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No recipes found',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _RecipeCard(
                        recipe: filtered[i],
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailScreen(recipe: filtered[i]),
                            ),
                          );
                        },
                        onToggleFavorite: () =>
                            recipeProvider.toggleFavorite(
                          filtered[i].id,
                          filtered[i].favorite,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Summary Widget ──

  Widget _buildSummary(RecipeProvider p) {
    final breakdown = p.categoryBreakdown;
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3E0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _SummaryChip('Recipes: ${p.totalRecipes}'),
              _SummaryChip('Favorites: ${p.totalFavorites}'),
              _SummaryChip('Total time: ${p.totalCookTime} min'),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              children: breakdown.entries
                  .map((e) => Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 12)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Filter Bar ──

  Widget _buildFilterBar(RecipeProvider p) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search recipes...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        p.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Category + Difficulty dropdowns
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: p.categoryFilter,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['All', ..._categories]
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style:
                                  const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) =>
                      p.setCategoryFilter(v ?? 'All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: p.difficultyFilter,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: ['All', ..._difficulties]
                      .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(d,
                              style:
                                  const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) =>
                      p.setDifficultyFilter(v ?? 'All'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Favorites only + Clear
          Row(
            children: [
              const Text('Favorites only',
                  style: TextStyle(fontSize: 13)),
              Switch(
                value: p.favoritesOnly,
                onChanged: (v) => p.setFavoritesOnly(v),
                materialTapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  p.clearFilters();
                  _searchCtrl.clear();
                },
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero),
                child: const Text('Clear',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Add Recipe Form ──

  Widget _buildAddForm() {
    return Flexible(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.shade200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.orange.shade50,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _formSubmitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Recipe',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Name *', isDense: true),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                      labelText: 'Category *', isDense: true),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Choose category')),
                    ..._categories.map((c) => DropdownMenuItem(
                        value: c, child: Text(c))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedCategory = v),
                  validator: _validateCategory,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
                  decoration: const InputDecoration(
                      labelText: 'Difficulty *',
                      isDense: true),
                  items: [
                    const DropdownMenuItem(
                        value: null,
                        child: Text('Choose difficulty')),
                    ..._difficulties.map((d) => DropdownMenuItem(
                        value: d, child: Text(d))),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedDifficulty = v),
                  validator: _validateDifficulty,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cookTimeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Cook time (minutes) *',
                      isDense: true),
                  validator: _validateCookTime,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _servingsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Servings', isDense: true),
                  validator: _validateServings,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Notes', isDense: true),
                  validator: _validateNotes,
                ),
                const SizedBox(height: 16),
                if (_formSuccess != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_formSuccess!,
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ),
                if (_formError != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_formError!,
                        style:
                            const TextStyle(color: Colors.red)),
                  ),
                ElevatedButton(
                  onPressed: _formLoading ? null : _submitForm,
                  child: _formLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Add Recipe'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary Chip ──

class _SummaryChip extends StatelessWidget {
  final String label;
  const _SummaryChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Recipe Card ──

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _Tag(recipe.category,
                            Colors.blue.shade100),
                        _Tag(recipe.difficulty,
                            Colors.green.shade100),
                        _Tag('${recipe.cookTime} min',
                            Colors.orange.shade100),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  recipe.favorite
                      ? Icons.star
                      : Icons.star_border,
                  color: recipe.favorite
                      ? Colors.amber
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag ──

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
