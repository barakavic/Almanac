import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:bookshelf/widget/subgenre_management_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class GenreDetailScreen extends ConsumerStatefulWidget{
  final Genre genre;

  const GenreDetailScreen({
    required this.genre,
    super.key
  });

  @override
  ConsumerState<GenreDetailScreen> createState() => _GenreDetailScreenState();


}

class _GenreDetailScreenState extends ConsumerState<GenreDetailScreen>{

  
  
  String? selectedSubgenreId;

  Future<void> _importBookIntoGenre() async{
    try{
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf']
      );
      if (result == null){
        appLogger.w('User canceled the file picker');
        return;

      }
      final sourcePath = result.files.single.path!;

      final appDir = await getApplicationDocumentsDirectory();

      final fileName = result.files.single.name;

      final destinationPath = '${appDir.path}/$fileName';

      await File(sourcePath).copy(destinationPath);

      final newBook = Book(bookid: const Uuid().v4(),
       title: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''), 
       author: 'Unknown Author', 
       filepath: destinationPath, 
       spinecolor: Colors.primaries[DateTime.now().second% Colors.primaries.length].value, 
       lastpageread: 0, 
       totalpages: 0, 
       isarchived: false, 
       addedat: DateTime.now(),
       genreid: widget.genre.genreid,
       subgenreid: selectedSubgenreId
       );

       await ref.read(bookRepositoryProvider).addBook(newBook);
       ref.invalidate(booksByGenreProvider(widget.genre.genreid));
       ref.invalidate(booksProvider);

       if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book added successfully'))
        );
       }

    }
    catch(e, st){
      appLogger.e('Failed to import book', error: e, stackTrace: st);
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import book'))
        );
      }

      
    }
  }
  @override
  Widget build(BuildContext context) {
    final subGenresAsync = ref.watch(
    subGenresByGenreProvider(widget.genre.genreid),
  );
  
  final booksAsync = ref.watch(
    booksByGenreProvider(widget.genre.genreid)
  );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genre.name),
        actions: [
          IconButton(
            onPressed: () => showDialog(
              context: context, 
              builder: (_) => SubgenreManagementDialog(genre: widget.genre)
            ),
            icon: const Icon(Icons.label_outline)
          )
        ],
        
      ),
      body: Column(
        children: [
          subGenresAsync.when(data: (subgenres){
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ChoiceChip(label: const Text('All'), 
                  selected: selectedSubgenreId == null,
                  onSelected:  (_){
                    setState(() {
                      
                      selectedSubgenreId = null;
                    });
                  },
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  ...subgenres.map((subgenre){
                    return Padding(padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(subgenre.subgenrename),
                    selected: selectedSubgenreId == subgenre.subgenreid,
                    onSelected: (_){
                      setState(() {
                        selectedSubgenreId = subgenre.subgenreid;
                      });
                    },
                    ),

                    );
                  })
                ],
              ),
            );
          }, 
          error: (error, stacktrace ) => Text('Failed to load subgenres: $error'),
          loading: ()=> const LinearProgressIndicator()),

          Expanded(child: booksAsync.when(data: (books){
            final filteredBooks = selectedSubgenreId == null 
            ? books
            : books
            .where((book) => book.subgenreid == selectedSubgenreId).toList();
            if (filteredBooks.isEmpty){
              return const Center(
                child: Text('No books in this genre yet'),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12
                ), 
                itemCount: filteredBooks.length,
                itemBuilder: (context, index){
                  final book = filteredBooks[index];
                  final progress = book.totalpages == 0 
                  ? 0.0
                  : (book.lastpageread/ book.totalpages).clamp(0.0, 1.0);
                  return 
                  Card(
                    clipBehavior: Clip.hardEdge,
                    child:InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfReaderScreen(book: book),
                          ),
                        );
                      },
                      child:  Padding(padding: 
                    const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,               
                          style: const TextStyle(
                           fontWeight: FontWeight.bold
                          ),
                        
                        ),
                        const SizedBox(
                          height: 6
                        ),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(

                        ),
                        LinearProgressIndicator(value: progress,)
                      ],
                    ),
                    ),

                  )
                  );
                });
          }, error: (error, stackTrace) => Center(
            child: Text('Failed to load books: $error'),
          ), loading: ()=> const Center(child: CircularProgressIndicator(),)))
          
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _importBookIntoGenre,
      child: const Icon(Icons.add),),

  );
  }
}