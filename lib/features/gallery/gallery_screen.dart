import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/models/inspiration.dart';
import '../../core/router.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final inspirationsAsync = ref.watch(inspirationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: 'favorites',
                child: Text('Favorites'),
              ),
              const PopupMenuItem(
                value: 'high_quality',
                child: Text('High Quality'),
              ),
            ],
          ),
        ],
      ),
      body: inspirationsAsync.when(
        data: (inspirations) {
          // Apply filter
          List<Inspiration> filtered = inspirations;
          if (_selectedFilter == 'favorites') {
            filtered = inspirations.where((i) => i.isFavorite).toList();
          } else if (_selectedFilter == 'high_quality') {
            filtered = inspirations.where((i) => i.isHighQuality).toList();
          }

          if (filtered.isEmpty) {
            return _buildEmptyState(context);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final inspiration = filtered[index];
              return _GalleryCard(
                inspiration: inspiration,
                onTap: () => _showInspirationDetail(context, inspiration),
                onFavorite: () {
                  ref
                      .read(inspirationsProvider.notifier)
                      .toggleFavorite(inspiration.id);
                },
                onDelete: () => _confirmDelete(context, inspiration),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(inspirationsProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    if (_selectedFilter == 'favorites') {
      message = 'No favorites yet. Tap the heart icon to add favorites.';
    } else if (_selectedFilter == 'high_quality') {
      message = 'No high quality images yet. Generate with the HQ toggle on.';
    } else {
      message = 'Your gallery is empty. Generate some inspirations!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Inspirations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInspirationDetail(BuildContext context, Inspiration inspiration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        inspiration.imageBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prompt
                    Text(
                      'Prompt',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(inspiration.prompt),
                    const SizedBox(height: 16),

                    // Description
                    if (inspiration.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(inspiration.description),
                      const SizedBox(height: 16),
                    ],

                    // Metadata
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            inspiration.isHighQuality ? '4K Quality' : 'Standard',
                          ),
                          avatar: Icon(
                            inspiration.isHighQuality
                                ? Icons.high_quality
                                : Icons.sd,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_formatDate(inspiration.createdAt)),
                          avatar: const Icon(Icons.calendar_today, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(inspirationsProvider.notifier)
                                  .toggleFavorite(inspiration.id);
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              inspiration.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            label: Text(
                              inspiration.isFavorite
                                  ? 'Unfavorite'
                                  : 'Favorite',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go(
                                '/chat',
                                extra: ChatWithInspirationExtra(
                                  imageBytes: inspiration.imageBytes,
                                  prompt: 'How do I paint this? Give me step-by-step instructions for: ${inspiration.prompt}',
                                ),
                              );
                            },
                            icon: const Icon(Icons.brush),
                            label: const Text('Get Tips'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Inspiration inspiration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inspiration?'),
        content: const Text(
          'This will permanently delete this inspiration from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(inspirationsProvider.notifier)
                  .removeInspiration(inspiration.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _GalleryCard extends StatelessWidget {
  final Inspiration inspiration;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  const _GalleryCard({
    required this.inspiration,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    inspiration.imageBytes,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: onFavorite,
                      icon: Icon(
                        inspiration.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: inspiration.isFavorite
                            ? Colors.red
                            : Colors.black.withOpacity(0.5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  // Quality badge
                  if (inspiration.isHighQuality)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '4K',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                inspiration.prompt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
