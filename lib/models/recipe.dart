import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String difficulty;
  final int cookTime;
  final int? servings;
  final bool favorite;
  final String? notes;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.difficulty,
    required this.cookTime,
    this.servings,
    this.favorite = false,
    this.notes,
    required this.createdAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? '',
      cookTime: (data['cookTime'] as num?)?.toInt() ?? 0,
      servings: (data['servings'] as num?)?.toInt(),
      favorite: data['favorite'] ?? false,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'category': category,
      'difficulty': difficulty,
      'cookTime': cookTime,
      'servings': servings,
      'favorite': favorite,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Recipe copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? difficulty,
    int? cookTime,
    Object? servings = _sentinel,
    bool? favorite,
    Object? notes = _sentinel,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      cookTime: cookTime ?? this.cookTime,
      servings: servings == _sentinel ? this.servings : servings as int?,
      favorite: favorite ?? this.favorite,
      notes: notes == _sentinel ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const _sentinel = Object();
