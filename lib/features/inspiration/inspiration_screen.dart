import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers.dart';
import '../../core/models/inspiration.dart';

class InspirationScreen extends ConsumerStatefulWidget {
  const InspirationScreen({super.key});

  @override
  ConsumerState<InspirationScreen> createState() => _InspirationScreenState();
}

class _InspirationScreenState extends ConsumerState<InspirationScreen> {
  final TextEditingController _promptController = TextEditingController();
  Uint8List? _referenceImage;
  Uint8List? _generatedImage;
  String? _generatedDescription;
  bool _isGenerating = false;
  String? _error;
  List<Color> _selectedColors = [];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _addColor(Color color) {
    setState(() {
      _selectedColors.add(color);
    });
  }

  void _removeColor(int index) {
    setState(() {
      _selectedColors.removeAt(index);
    });
  }

  Future<void> _pickReferenceImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _referenceImage = bytes;
      });
    }
  }

  Future<void> _generate() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedImage = null;
    });

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final highQuality = ref.read(highQualityModeProvider);

      // Convert colors to hex strings for the API
      final colorHexList = _selectedColors.isNotEmpty
          ? _selectedColors
              .map((c) =>
                  '#${c.value.toRadixString(16).substring(2).toUpperCase()}')
              .toList()
          : null;

      final result = await geminiService.generateInspiration(
        _promptController.text.trim(),
        highQuality: highQuality,
        referenceImage: _referenceImage,
        colorPalette: colorHexList,
      );

      setState(() {
        _generatedImage = result.imageBytes;
        _generatedDescription = result.description;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _saveInspiration() async {
    if (_generatedImage == null) return;

    final inspiration = Inspiration.create(
      prompt: _promptController.text.trim(),
      description: _generatedDescription ?? '',
      imageBytes: _generatedImage!,
      isHighQuality: ref.read(highQualityModeProvider),
    );

    await ref.read(inspirationsProvider.notifier).addInspiration(inspiration);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inspiration saved to gallery!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final highQuality = ref.watch(highQualityModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Inspiration'),
        actions: [
          // Quality toggle
          IconButton(
            icon: Icon(
              highQuality ? Icons.high_quality : Icons.sd,
              color: highQuality
                  ? Theme.of(context).colorScheme.secondary
                  : null,
            ),
            tooltip: highQuality ? 'High Quality (4K)' : 'Standard Quality',
            onPressed: () {
              ref.read(highQualityModeProvider.notifier).state = !highQuality;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quality indicator
            if (highQuality)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nano Banana Pro - 4K Quality',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Prompt input
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe your miniature',
                hintText: 'e.g., Dark Angels successor chapter in winter camo with battle damage',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.edit),
                suffixIcon: _promptController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _promptController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Reference image section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Reference Image (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_referenceImage != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _referenceImage = null;
                              });
                            },
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_referenceImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _referenceImage!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickReferenceImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Reference for Style Transfer'),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color palette section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Color Palette (Optional)',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_selectedColors.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedColors.clear();
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Selected colors display
                    if (_selectedColors.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < _selectedColors.length; i++)
                            GestureDetector(
                              onTap: () => _removeColor(i),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _selectedColors[i],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          _AddColorButton(onColorSelected: _addColor),
                        ],
                      ),
                    ] else
                      _AddColorButton(onColorSelected: _addColor),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add colors, tap a color to remove it',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Generate button
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Inspiration'),
            ),

            // Error display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Generated image result
            if (_generatedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Generated Inspiration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Image.memory(
                            _generatedImage!,
                            fit: BoxFit.cover,
                          ),
                          if (_generatedDescription != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _generatedDescription!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _generate,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Regenerate'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _saveInspiration,
                                    icon: const Icon(Icons.save),
                                    label: const Text('Save'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Example prompts
            Text(
              'Example Prompts',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ExamplePromptChip(
                  label: 'Space Wolves in snow base',
                  onTap: () {
                    _promptController.text = 'Space Wolves Space Marine in snow camo with ice and frost effects';
                    setState(() {});
                  },
                ),
                _ExamplePromptChip(
                  label: 'Nurgle plague marine',
                  onTap: () {
                    _promptController.text = 'Nurgle Death Guard plague marine with rusty armor and pustules';
                    setState(() {});
                  },
                ),
                _ExamplePromptChip(
                  label: 'High Elf mage',
                  onTap: () {
                    _promptController.text = 'High Elf mage in white and blue robes with glowing magical effects';
                    setState(() {});
                  },
                ),
                _ExamplePromptChip(
                  label: 'Steampunk tank',
                  onTap: () {
                    _promptController.text = 'Steampunk tank with brass pipes, weathered copper, and rust effects';
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamplePromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExamplePromptChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _AddColorButton extends StatefulWidget {
  final ValueChanged<Color> onColorSelected;

  const _AddColorButton({required this.onColorSelected});

  @override
  State<_AddColorButton> createState() => _AddColorButtonState();
}

class _AddColorButtonState extends State<_AddColorButton> {
  Color _pickerColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _showColorPicker(context),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8),
      ),
      child: const Icon(Icons.add),
    );
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Colour picker',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: _pickerColor,
                  onColorChanged: (color) {
                    setModalState(() {
                      _pickerColor = color;
                    });
                  },
                  colorPickerWidth: MediaQuery.of(context).size.width - 32,
                  pickerAreaHeightPercent: 0.5,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsvWithHue,
                  labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      widget.onColorSelected(_pickerColor);
                      Navigator.pop(context);
                    },
                    child: const Text('Add Color'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
