import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspirationsAsync = ref.watch(inspirationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Inspire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Settings screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Welcome to Mini Inspire',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Get AI-powered inspiration for your miniature painting projects. Generate color schemes, get painting advice, and explore new ideas.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.go('/generate'),
                      icon: const Icon(Icons.brush),
                      label: const Text('Generate Inspiration'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.palette,
                    title: 'Generate',
                    subtitle: 'Create new ideas',
                    onTap: () => context.go('/generate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.chat,
                    title: 'Ask Coach',
                    subtitle: 'Get painting tips',
                    onTap: () => context.go('/chat'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent inspirations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Inspirations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/gallery'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            inspirationsAsync.when(
              data: (inspirations) {
                if (inspirations.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.collections_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No inspirations yet',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.go('/generate'),
                              child: const Text('Generate your first one'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Show last 3 inspirations
                final recentInspirations = inspirations.take(3).toList();
                return SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentInspirations.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final inspiration = recentInspirations[index];
                      return _InspirationCard(
                        imageBytes: inspiration.imageBytes,
                        title: inspiration.prompt,
                        isFavorite: inspiration.isFavorite,
                        onTap: () {
                          // TODO: Open inspiration detail
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),

            const SizedBox(height: 24),

            // Tips section
            Text(
              'Painting Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const _TipCard(
              tip: 'Always thin your paints with water or medium for smoother application.',
              icon: Icons.water_drop,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspirationCard extends StatelessWidget {
  final dynamic imageBytes;
  final String title;
  final bool isFavorite;
  final VoidCallback onTap;

  const _InspirationCard({
    required this.imageBytes,
    required this.title,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),
                    if (isFavorite)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final IconData icon;

  const _TipCard({
    required this.tip,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tip),
            ),
          ],
        ),
      ),
    );
  }
}
