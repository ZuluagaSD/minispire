import 'package:hive_flutter/hive_flutter.dart';
import '../models/inspiration.dart';

/// Service for persisting data locally using Hive
class StorageService {
  static const String _inspirationsBox = 'inspirations';

  Box<Inspiration>? _box;

  /// Initialize Hive and open boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InspirationAdapter());
    }

    // Open boxes
    _box = await Hive.openBox<Inspiration>(_inspirationsBox);
  }

  /// Get all saved inspirations
  List<Inspiration> getAllInspirations() {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    return _box!.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get favorite inspirations
  List<Inspiration> getFavorites() {
    return getAllInspirations().where((i) => i.isFavorite).toList();
  }

  /// Get inspirations by tag
  List<Inspiration> getByTag(String tag) {
    return getAllInspirations()
        .where((i) => i.tags.contains(tag))
        .toList();
  }

  /// Save a new inspiration
  Future<void> saveInspiration(Inspiration inspiration) async {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    await _box!.put(inspiration.id, inspiration);
  }

  /// Update an existing inspiration
  Future<void> updateInspiration(Inspiration inspiration) async {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    await _box!.put(inspiration.id, inspiration);
  }

  /// Delete an inspiration
  Future<void> deleteInspiration(String id) async {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    await _box!.delete(id);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String id) async {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    final inspiration = _box!.get(id);
    if (inspiration != null) {
      final updated = inspiration.copyWith(isFavorite: !inspiration.isFavorite);
      await _box!.put(id, updated);
    }
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final inspiration in getAllInspirations()) {
      tags.addAll(inspiration.tags);
    }
    return tags.toList()..sort();
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAll() async {
    if (_box == null) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
    await _box!.clear();
  }

  /// Close the database
  Future<void> close() async {
    await _box?.close();
  }
}
