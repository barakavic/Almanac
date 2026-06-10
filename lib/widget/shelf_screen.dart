import 'dart:async';
import 'dart:io';

import 'package:bookshelf/widget/book_actions_sheet.dart';
import 'package:bookshelf/widget/import_genre_picker_sheet.dart';
import 'package:bookshelf/widget/shelf/unsorted_books_section.dart';
import 'package:bookshelf/widget/shelf/currently_reading_section.dart';
import 'package:bookshelf/widget/shelf/genre_books_section.dart';
import 'package:app_links/app_links.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/genre_management_screen.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:share_handler/share_handler.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:uuid/uuid.dart';

class ShelfScreen extends ConsumerStatefulWidget {
  const ShelfScreen({super.key});

  @override
  ConsumerState<ShelfScreen> createState() => _ShelfScreenState();
  
}
class _ShelfScreenState extends ConsumerState<ShelfScreen>{
    final Set<String> _processingPaths = {};
    bool _isGridView = false;

    late AppLinks _appLinks;
    StreamSubscription<Uri>? _linkSubScription;
    StreamSubscription? _shareSub;

    @override
    void initState(){
      super.initState();
      // ColdStart
      WidgetsBinding.instance.addPostFrameCallback(
        (_){
          ShareHandlerPlatform.instance.getInitialSharedMedia().then((media){
            if (media?.attachments?.isNotEmpty == true){
            final path = media?.attachments?.first?.path;
            if(path!= null) _handleIncomingFile(path);}
          });
        }
      );

      _shareSub =  ShareHandlerPlatform.instance.sharedMediaStream.listen((media){
        if (media.attachments?.isNotEmpty == true)
        {final path = media.attachments!.first?.path;
        if (path != null) _handleIncomingFile(path);}
      });
      _appLinks = AppLinks();

      _appLinks.getInitialLink().then((uri){
        if (uri != null) _processIncomingUri(uri);
      });

      _linkSubScription = _appLinks.uriLinkStream.listen(_processIncomingUri);

     }

    @override
    void dispose(){
      _shareSub?.cancel();
      _linkSubScription?.cancel();
      super.dispose();
    }

    Future<void> _processIncomingUri(Uri uri) async{
      try{

        if(uri.scheme != 'content' && uri.scheme != 'file') return;

        File file = await toFile(uri.toString());
        
        if (!file.path.toLowerCase().endsWith('.pdf')) {
          appLogger.w('Ignored non-PDF file: ${file.path}');
          return;
          }

        await _handleIncomingFile(file.path);

      }
      catch(e,st){
        appLogger.e('Failed to process File $e', error: e, stackTrace: st);
      }

    }

    Future<void> _handleIncomingFile(String sharedFilePath) async{
      try{
        
      final fileName = sharedFilePath.split('/').last;

      final appDir = await getApplicationDocumentsDirectory();
      final destinationPath = '${appDir.path}/$fileName';

      if(_processingPaths.contains(destinationPath)){
        return;
      }

      _processingPaths.add(destinationPath);
      
      try{
        
      final existing = await ref.read(bookRepositoryProvider).getBookByPath(destinationPath);
      if (existing != null){
        if (mounted){
          Navigator.push(context, 
          MaterialPageRoute(builder: (_)=> 
          PdfReaderScreen(book: existing)));
        }
        return;
      }

      await File(sharedFilePath).copy(destinationPath);

      final newBook = Book(
        bookid: const Uuid().v4(), 
        title: fileName.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false
          ),
           ''), 
           author: 'Unknown Author', 
           filepath: destinationPath, 
           spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
            lastpageread: 0, 
            totalpages: 0, 
            isarchived: false, 
            addedat: DateTime.now()
            );

            await ref.read(bookRepositoryProvider).addBook(newBook);

            ref.invalidate(booksProvider);

            if(mounted){
              Navigator.push(context, MaterialPageRoute(builder: (_) => PdfReaderScreen(book: newBook)));
            }
      } finally{
        _processingPaths.remove(destinationPath);

      }
      }
      
      catch(e,st){
        appLogger.e('Failed to process incoming File',error: e, stackTrace: st);
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to open shared book'))
          );
        }
      
      }

    }

  

void _showBookActions(Book book){
  showModalBottomSheet(
    context: context, 
    builder: 
    (ctx)=> BookActionsSheet(book: book),
    );
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

    if (!mounted) return;

    final selectedGenres = await showModalBottomSheet<Map<String, String?>>(
      context: context, 
      builder: (ctx) => const ImportGenrePickerSheet(),
      );

      final genreid = selectedGenres?['genreid'];
      final subgenreid = selectedGenres?['subgenreid'];

    

    final newBook = Book(
      bookid: const Uuid().v4(),
      title: filename.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      author: 'Unknown Author',
      filepath: destPath,
      spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
      lastpageread: 0,
      totalpages: 0,
      isarchived: false,
      genreid: genreid,
      subgenreid: subgenreid,
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
          }, 
          icon: Icon(_isGridView?
          Icons.view_agenda:
          Icons.grid_view
          ),

          ),

          IconButton(icon: const Icon(Icons.category), onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (context)=> const GenreManagementScreen()));
          },)
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
            loading: () => const Center(child: SpinKitThreeBounce(color: Colors.blue,)),
            error: (err, stack) => Center(child: Text('Error, $err')),
                        data: (genres) {
              return ListView(
                children: [
                  CurrentlyReadingSection(
                    books: books,
                    onLongPressBook: _showBookActions,
                  ),
                  UnsortedBooksSection(
                    books: books,
                    onLongPressBook: _showBookActions,
                  ),
                  ...genres.map((genre) => GenreBooksSection(
                    genre: genre,
                    books: books,
                    onLongPressBook: _showBookActions,
                  )),
                ],
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

