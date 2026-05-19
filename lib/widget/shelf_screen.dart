import 'dart:io';

import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/genre_divider.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:uuid/uuid.dart';

class ShelfScreen extends ConsumerStatefulWidget {
  const ShelfScreen({super.key});

  @override
  ConsumerState<ShelfScreen> createState() => _ShelfScreenState();

  
  
}
class _ShelfScreenState extends ConsumerState<ShelfScreen>{
  bool _isGridView = false;

   Future<void> _importBook()async{
    try{
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf']
      
    );
    if (result == null){
      appLogger.w("User canceled file picker");
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
  catch(e,st){
    appLogger.e('Failed to import book', error: e, stackTrace: st);
    if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import book'))
      );
    }
    
  }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(booksProvider);
    final genreAsync = ref.watch(genreProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Almanack'
        ),
        actions: [
          IconButton(onPressed: (){
            setState(() {
              _isGridView = !_isGridView;
              
            });
          }, icon: Icon(_isGridView?
          Icons.view_agenda:
          Icons.grid_view
          ),

          ),
        ],
      ),
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
        onPressed: () => _importBook(),
        tooltip: 'Import Book',
        child: const Icon(Icons.add),
      ),
    );
  }
   
  
}

