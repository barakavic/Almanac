import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/models/subgenre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class SubgenreManagementDialog extends ConsumerStatefulWidget {
  final Genre genre;
  const SubgenreManagementDialog({super.key, required this.genre});

  @override
  ConsumerState<SubgenreManagementDialog> createState() => _SubgenreManagementDialogState();
}

class _SubgenreManagementDialogState extends ConsumerState<SubgenreManagementDialog> {
  final TextEditingController _subgenreController = TextEditingController();

  @override
  void dispose() {
    _subgenreController.dispose();
    super.dispose();
  }

  Future<void> _addSubgenre() async {
    final text = _subgenreController.text.trim();
    if (text.isEmpty) return;

    final newSubgenre = Subgenre(
      subgenreid: const Uuid().v4(),
      subgenrename: text,
      genreid: widget.genre.genreid,
    );

    await ref.read(subGenreRepositoryProvider).addSubgenre(newSubgenre);
    ref.invalidate(subGenresByGenreProvider(widget.genre.genreid));
    _subgenreController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subgenreState = ref.watch(subGenresByGenreProvider(widget.genre.genreid));

    return AlertDialog(
      title: Text('Subgenres for ${widget.genre.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subgenreController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a new subgenre...',
                    ),
                    onSubmitted: (_) => _addSubgenre(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSubgenre,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: subgenreState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (subgenres) {
                  if (subgenres.isEmpty) {
                    return const Center(child: Text('No subgenres yet.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: subgenres.length,
                    itemBuilder: (context, index) {
                      final subgenre = subgenres[index];
                      return ListTile(
                        title: Text(subgenre.subgenrename),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await ref.read(subGenreRepositoryProvider).deleteSubgenre(subgenre.subgenreid);
                            ref.invalidate(subGenresByGenreProvider(widget.genre.genreid));
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}