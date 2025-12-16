import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
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

      final result = await geminiService.generateInspiration(
        _promptController.text.trim(),
        highQuality: highQuality,
        referenceImage: _referenceImage,
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
