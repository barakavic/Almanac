import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GenreDivider extends ConsumerWidget {
  final Genre genre;
  const GenreDivider({super.key, required this.genre});

  void _showOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename Genre'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Change Color'),
            onTap: () {
              Navigator.pop(context);
              _showColorDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: genre.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Genre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Genre Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != genre.name) {
                await ref.read(genreRepositoryProvider).updateGenre(genre.genreid, newName);
                ref.invalidate(genreProvider);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showColorDialog(BuildContext context, WidgetRef ref) {
    final presetColors = [
      0xFF1F4FBF, // Default Blue
      0xFFB71C1C, // Red
      0xFF1B5E20, // Green
      0xFFE65100, // Orange
      0xFF4A148C, // Purple
      0xFF263238, // Blue Grey
      0xFF006064, // Cyan
      0xFF827717, // Lime/Olive
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...presetColors.map((c) => GestureDetector(
                  onTap: () async {
                    await ref.read(genreRepositoryProvider).updateGenreColor(genre.genreid, c);
                    ref.invalidate(genreProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: Color(c),
                    radius: 20,
                  ),
                )),
            // Empty custom for later
            GestureDetector(
              onTap: () {
                // TODO: Implement color wheel
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 2),
                ),
                child: const Icon(Icons.colorize, color: Colors.grey, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => _showOptions(context, ref),
      child: SizedBox(
        width: 36,
        height: 220,
        child: Container(
          decoration: BoxDecoration(
            color: genre.genrecolor != 0 ? Color(genre.genrecolor) : const Color(0xFF1F4FBF),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 0.5
            ),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                genre.name.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}