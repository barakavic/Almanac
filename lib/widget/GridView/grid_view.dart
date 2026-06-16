import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GridViewScreen extends ConsumerWidget{
  const GridViewScreen({
    super.key,
    required this.onBookLongPress,
    });

    final void Function(Book book) onBookLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(booksProvider);
    final genreAsync = ref.watch(genreProvider);
    return bookAsync.when(data: 
    (books){
      if(books.isEmpty){
        return const Center(
          child: Text(
            'No Books Yet'
          ),
        );
      }
      return genreAsync.when(data: (genres){
        final genresMap = Map.fromEntries(genres.map((g)=> MapEntry(g.genreid, g)));
        return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: 
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68
        ),
        itemCount: books.length,
        itemBuilder: (context, index){
          final book = books[index];
          return _BookGridCard(
            book: book,
            onTap: () {
              Navigator.push(context, 
              MaterialPageRoute(builder: (_) => 
              PdfReaderScreen(book: book)));
            },
            onLongPress: () => onBookLongPress(book),

          );
        });
      
      },
      error: (error, stack) => Center(child: Text('Error: $error')),
      loading: () => const Center(child: CircularProgressIndicator(),)
      );
       }, error: (error, stack) => Center(child:  Text('Error: $error'),), 
    loading: () => const Center(child: LinearProgressIndicator(),));
  }
}

class _BookGridCard extends StatelessWidget{
  final Book book;
  final Genre? genre;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _BookGridCard({
    this.genre,
    required this.book,
    required this.onTap,
    required this.onLongPress
  });

  @override
  Widget build(BuildContext context) {

    LinearProgressIndicator gridProgressIndicator = LinearProgressIndicator(
      value: book.totalpages == 0 ? 0.0 :
      (book.lastpageread/book.totalpages).clamp(0.0, 1.0) ,
      minHeight: 8.2,
      borderRadius: BorderRadius.circular(4),
    );
    
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.hardEdge,
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: genre != null ? Color(genre!.genrecolor) : Color(book.spinecolor),
          width: 2
        )
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: [
            
            
            const SizedBox(
              height: 16
            ),
            Padding(padding: 
            const EdgeInsets.symmetric(
              horizontal: 12
              
            ),
            child: Text(book.title,
            style: Theme.of(context).
            textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.w600
              ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            ),
            ),
            
            const SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12
              ),
              child: Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              ),

              const Spacer(),
              Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: gridProgressIndicator
              ),
              Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              
              child: Text(
                '${book.lastpageread}/${book.totalpages} pages',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)
              ),
              )

          ],)
      ),
      ),

    );
  }
}