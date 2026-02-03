import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'models/inspiration.dart';

/// Provider for the GeminiService
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final service = GeminiService();
  service.initialize();
  return service;
});

/// Provider for the StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for all inspirations
final inspirationsProvider = StateNotifierProvider<InspirationsNotifier, AsyncValue<List<Inspiration>>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return InspirationsNotifier(storage);
});

/// State notifier for managing inspirations
class InspirationsNotifier extends StateNotifier<AsyncValue<List<Inspiration>>> {
  final StorageService _storage;

  InspirationsNotifier(this._storage) : super(const AsyncValue.loading()) {
    _loadInspirations();
  }

  Future<void> _loadInspirations() async {
    try {
      await _storage.initialize();
      final inspirations = _storage.getAllInspirations();
      state = AsyncValue.data(inspirations);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addInspiration(Inspiration inspiration) async {
    await _storage.saveInspiration(inspiration);
    state = AsyncValue.data(_storage.getAllInspirations());
  }

  Future<void> removeInspiration(String id) async {
    await _storage.deleteInspiration(id);
    state = AsyncValue.data(_storage.getAllInspirations());
  }

  Future<void> toggleFavorite(String id) async {
    await _storage.toggleFavorite(id);
    state = AsyncValue.data(_storage.getAllInspirations());
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final inspirations = state.value ?? [];
    final index = inspirations.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = inspirations[index].copyWith(tags: tags);
      await _storage.updateInspiration(updated);
      state = AsyncValue.data(_storage.getAllInspirations());
    }
  }

  void refresh() {
    state = AsyncValue.data(_storage.getAllInspirations());
  }
}

/// Provider for generation state
final generatingProvider = StateProvider<bool>((ref) => false);

/// Provider for selected quality mode
final highQualityModeProvider = StateProvider<bool>((ref) => false);

/// Provider for chat history
final chatHistoryProvider = StateProvider<List<ChatMessage>>((ref) => []);

/// Simple chat message model
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.imageBytes,
  }) : timestamp = timestamp ?? DateTime.now();
}
