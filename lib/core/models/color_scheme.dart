/// A color extracted from an image with paint brand matches
class PaintColor {
  final String name;
  final int hexValue;
  final String? citadelMatch;
  final String? vallejoMatch;
  final String? armyPainterMatch;

  const PaintColor({
    required this.name,
    required this.hexValue,
    this.citadelMatch,
    this.vallejoMatch,
    this.armyPainterMatch,
  });

  /// Get the color as a Flutter Color
  int get color => hexValue;

  /// Get the hex string representation
  String get hexString => '#${hexValue.toRadixString(16).padLeft(6, '0').toUpperCase()}';

  @override
  String toString() {
    final matches = <String>[];
    if (citadelMatch != null) matches.add('Citadel: $citadelMatch');
    if (vallejoMatch != null) matches.add('Vallejo: $vallejoMatch');
    if (armyPainterMatch != null) matches.add('Army Painter: $armyPainterMatch');
    return '$name ($hexString) - ${matches.join(', ')}';
  }
}

/// A complete color scheme for a miniature
class ColorScheme {
  final String name;
  final List<PaintColor> primaryColors;
  final List<PaintColor> accentColors;
  final List<PaintColor> metallicColors;
  final String? notes;
  final DateTime createdAt;

  ColorScheme({
    required this.name,
    required this.primaryColors,
    this.accentColors = const [],
    this.metallicColors = const [],
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get all colors in the scheme
  List<PaintColor> get allColors => [
        ...primaryColors,
        ...accentColors,
        ...metallicColors,
      ];

  /// Get a shopping list of all paints needed
  List<String> get shoppingList {
    final paints = <String>{};
    for (final color in allColors) {
      if (color.citadelMatch != null) paints.add('Citadel ${color.citadelMatch}');
      if (color.vallejoMatch != null) paints.add('Vallejo ${color.vallejoMatch}');
    }
    return paints.toList()..sort();
  }
}
