import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/widget/book_detail_screen.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:flutter/material.dart';

class CurrentlyReadingSection extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onLongPressBook;
  final List<Genre> genres;

  const CurrentlyReadingSection({
    required this.books,
    required this.onLongPressBook,
    required this.genres,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentlyReading = books.where((b) => b.lastpageread > 0 && !b.isarchived).toList();
    if (currentlyReading.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Currently Reading',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: currentlyReading.map((book) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                  child: Draggable<Book>(
                    data: book,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Opacity(opacity: 0.75,
                      child: BookSpine(book: book, onTap: (){}
                      ),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3,
                    child: BookSpine(book: book, onTap: (){
                      
                    }),
                    ),
                    child: GestureDetector(
                    onLongPress: () => onLongPressBook(book),
                    child: BookSpine(
                    book: book,
                    onTap: () {
                      final genre = 
                      genres.where(
                        (g) => g.genreid == book.genreid).
                        firstOrNull;
                      if(genre == null) return;

                      

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book, genre: genre)),
                      );
                    },
                  ),)
                    )
                 );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
