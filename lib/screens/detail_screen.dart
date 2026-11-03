import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';

class DetailScreen extends StatefulWidget {
  final Recipe recipe;

  const DetailScreen({super.key, required this.recipe});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Recipe _recipe;
  bool _editMode = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cookTimeCtrl;
  late TextEditingController _servingsCtrl;
  late TextEditingController _notesCtrl;
  String? _selectedCategory;
  String? _selectedDifficulty;
  bool _formSubmitted = false;
  bool _saving = false;
  String? _saveError;

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
    _recipe = widget.recipe;
    _initControllers();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _recipe.name);
    _cookTimeCtrl =
        TextEditingController(text: _recipe.cookTime.toString());
    _servingsCtrl =
        TextEditingController(text: _recipe.servings?.toString() ?? '');
    _notesCtrl = TextEditingController(text: _recipe.notes ?? '');
    _selectedCategory = _recipe.category;
    _selectedDifficulty = _recipe.difficulty;
  }

  @override
  void dispose() {
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

  // ── Save ──

  Future<void> _save() async {
    setState(() {
      _formSubmitted = true;
      _saveError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final updated = _recipe.copyWith(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        cookTime: int.parse(_cookTimeCtrl.text.trim()),
        servings: _servingsCtrl.text.trim().isEmpty
            ? null
            : int.parse(_servingsCtrl.text.trim()),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      await context.read<RecipeProvider>().updateRecipe(updated);

      if (mounted) {
        setState(() {
          _recipe = updated;
          _editMode = false;
          _saving = false;
          _formSubmitted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveError =
              e is Exception ? e.toString() : 'Failed to save.';
          _saving = false;
        });
      }
    }
  }

  // ── Delete ──

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text(
            'Delete "${_recipe.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<RecipeProvider>().deleteRecipe(_recipe.id);
    if (mounted) Navigator.pop(context);
  }

  // ── Toggle favorite ──

  Future<void> _toggleFavorite() async {
    await context
        .read<RecipeProvider>()
        .toggleFavorite(_recipe.id, _recipe.favorite);
    setState(() {
      _recipe = _recipe.copyWith(favorite: !_recipe.favorite);
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editMode ? 'Edit Recipe' : 'Recipe Details'),
        actions: [
          if (!_editMode) ...[
            IconButton(
              icon: Icon(
                  _recipe.favorite
                      ? Icons.star
                      : Icons.star_border,
                  color: _recipe.favorite
                      ? Colors.amber
                      : Colors.white),
              onPressed: _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() {
                _editMode = true;
                _formSubmitted = false;
                _saveError = null;
                _initControllers();
              }),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _editMode ? _buildEditForm() : _buildViewMode(),
      ),
    );
  }

  // ── View Mode ──

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(_recipe.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(
                  _recipe.favorite
                      ? Icons.star
                      : Icons.star_border,
                  color: _recipe.favorite
                      ? Colors.amber
                      : Colors.grey,
                  size: 32),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DetailRow('Category', _recipe.category),
        _DetailRow('Difficulty', _recipe.difficulty),
        _DetailRow('Cook time', '${_recipe.cookTime} min'),
        if (_recipe.servings != null)
          _DetailRow('Servings', '${_recipe.servings}'),
        if (_recipe.notes != null &&
            _recipe.notes!.isNotEmpty) ...[
          const Divider(height: 24),
          Text('Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(_recipe.notes!),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () => setState(() {
                  _editMode = true;
                  _formSubmitted = false;
                  _saveError = null;
                  _initControllers();
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                onPressed: _delete,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Edit Form ──

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      autovalidateMode: _formSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration:
                const InputDecoration(labelText: 'Name *'),
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
                labelText: 'Category *'),
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text('Choose category')),
              ..._categories.map((c) =>
                  DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) =>
                setState(() => _selectedCategory = v),
            validator: _validateCategory,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            decoration: const InputDecoration(
                labelText: 'Difficulty *'),
            items: [
              const DropdownMenuItem(
                  value: null,
                  child: Text('Choose difficulty')),
              ..._difficulties.map((d) =>
                  DropdownMenuItem(value: d, child: Text(d))),
            ],
            onChanged: (v) =>
                setState(() => _selectedDifficulty = v),
            validator: _validateDifficulty,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cookTimeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Cook time (minutes) *'),
            validator: _validateCookTime,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _servingsCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Servings'),
            validator: _validateServings,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration:
                const InputDecoration(labelText: 'Notes'),
            validator: _validateNotes,
          ),
          const SizedBox(height: 24),
          if (_saveError != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_saveError!,
                  style: const TextStyle(color: Colors.red)),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          setState(() {
                            _editMode = false;
                            _formSubmitted = false;
                            _saveError = null;
                          });
                          _initControllers();
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12),
                    side: const BorderSide(
                        color: Color(0xFFE65100)),
                    foregroundColor: const Color(0xFFE65100),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Detail Row ──

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
