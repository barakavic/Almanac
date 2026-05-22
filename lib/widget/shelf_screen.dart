import 'dart:io';

import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/genre_divider.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
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

    Widget _buildUnassignedSection(List<Book> allBooks) {
    final unassignedBooks = allBooks.where((b) => b.genreid == null && !b.isarchived).toList();
    
    if (unassignedBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text("Unsorted Books", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: unassignedBooks.map((book) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: BookSpine(book: book, onTap: () {
                  Navigator.push(context, 
                  MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)) 
                  );
                }),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


      Widget _buildCurrentlyReadingSection(List<Book> allBooks){
        final currentlyReading = allBooks.where((b)=>b.lastpageread > 0 && !b.isarchived).toList();

        if (currentlyReading.isEmpty)
          return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.symmetric(
              horizontal: 24, vertical: 16
            ),
            child: Text('Currently Reading',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
            ),
            
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                
              ),
              child: Row(
                children: currentlyReading.map((book){
                  return Padding(padding: const EdgeInsets.only(right: 16.0),
                  child: BookSpine(book: book, onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (_)=> PdfReaderScreen(book: book)));

                  }),
                  );
                }).toList(),
              ),
            )
            
          ],
        );
      }

    Widget _buildGenreSection(Genre genre, List<Book> allBooks){
      final genreBooks = allBooks.where((b)=> b.genreid 
      == genre.genreid && !b.isarchived
      ).toList();
      if (genreBooks.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {},
            child: Padding(padding: EdgeInsets.symmetric(
              horizontal: 24, vertical: 16

            ),
            child: Row(
              children: [
                Text(genre.name, 
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
                ),
                const SizedBox(
                  width: 8,
                ),
                const Icon(Icons.chevron_right, size: 20,),

              ],
            ),
            ),
          ),
          SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 16
        ),
        child: Row(
          children: [
            GenreDivider(genre: genre),
            const SizedBox(width: 16,),
            ...genreBooks.map((book){
// 
              return Padding(padding: EdgeInsets.only(
                right: 16.0
              ),
              child: BookSpine(book: book, onTap: (){
                Navigator.push(context, 
                MaterialPageRoute(builder: (_)=> PdfReaderScreen(book: book)
                ),
                );
// 
// 
              }
              // 
              ),
              );
            })
          ],
        ),
      ),
        ],
      );

      

/*       return 
 */
    }

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
      bookid: const Uuid().v4(),
      title: filename.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      author: 'Unknown Author',
      filepath: destPath,
      spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
      lastpageread: 0,
      totalpages: 0,
      isarchived: false,
      addedat: DateTime.now(),
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
          'Almanac'
        ),
        actions: [
          IconButton(onPressed: (){
            setState(() {
              _isGridView = !_isGridView
              
              ;
              
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
          if (_isGridView){
            return const Center(child: Text('Grid view is coming soon'),);
          }
          return genreAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error, $err')),
            data: (genres) {
              return Center(
                child: ListView(
                  children: [
                    _buildCurrentlyReadingSection(books),
                    for (final genre in genres)
                    _buildGenreSection(genre, books),
                    _buildUnassignedSection(books),
                  ],
                )
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

