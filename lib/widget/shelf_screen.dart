import 'dart:io';

import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/widget/genre_divider.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:uuid/uuid.dart';

class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key});

  Future<void> _importBook(WidgetRef ref)async{
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf']
      
    );
    if (result == null){
      return;
    }
    final sourcePath = result.files.single.path!;

    final appDir = await 
    getApplicationDocumentsDirectory();
    final filename = result.files.single.name;
    final destPath = '${appDir.path}/$filename';

    await File(sourcePath).copy(destPath);

    final newBook = Book(
      bookId: const Uuid().v4(),
      title: filename.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      author: 'Unknown Author',
      filepath: destPath,
      spineColor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
      lastPageRead: 0,
      totalPages: 0,
      isArchived: false,
      addedAt: DateTime.now(),
    );

    await ref.read(bookRepositoryProvider).addBook(newBook);
    ref.invalidate(booksProvider);
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(booksProvider);
    final genreAsync = ref.watch(genreProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error, $err')),
        data: (books) {
          return genreAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error, $err')),
            data: (genres) {
              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      
                      for (final genre in genres) ...[
                        GenreDivider(genre: genre),
                        const SizedBox(width: 8),
                        ...books
                            .where((book) =>
                                book.genreId == genre.genreId &&
                                !book.isArchived)
                            .map((book) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: BookSpine(
                              book: book,
                              onTap: () {
                                
                              },
                            ),
                          );
                        }),
                      ],
                      
                      
                      ...books
                          .where((book) =>
                              book.genreId == null && !book.isArchived)
                          .map((book) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: BookSpine(
                            book: book,
                            onTap: () {
                              
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importBook(ref),
        tooltip: 'Import Book',
        child: const Icon(Icons.add),
      ),
    );
  }
  
}

