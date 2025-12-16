import 'dart:typed_data';
import 'package:hive/hive.dart';

part 'inspiration.g.dart';

/// A saved inspiration with generated image and metadata
@HiveType(typeId: 0)
class Inspiration extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String prompt;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final Uint8List imageBytes;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isHighQuality;

  @HiveField(6)
  List<String> tags;

  @HiveField(7)
  bool isFavorite;

  Inspiration({
    required this.id,
    required this.prompt,
    required this.description,
    required this.imageBytes,
    required this.createdAt,
    this.isHighQuality = false,
    this.tags = const [],
    this.isFavorite = false,
  });

  /// Create a new inspiration with a generated ID
  factory Inspiration.create({
    required String prompt,
    required String description,
    required Uint8List imageBytes,
    bool isHighQuality = false,
    List<String> tags = const [],
  }) {
    return Inspiration(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      prompt: prompt,
      description: description,
      imageBytes: imageBytes,
      createdAt: DateTime.now(),
      isHighQuality: isHighQuality,
      tags: tags,
    );
  }

  /// Copy with modified fields
  Inspiration copyWith({
    String? prompt,
    String? description,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Inspiration(
      id: id,
      prompt: prompt ?? this.prompt,
      description: description ?? this.description,
      imageBytes: imageBytes,
      createdAt: createdAt,
      isHighQuality: isHighQuality,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
