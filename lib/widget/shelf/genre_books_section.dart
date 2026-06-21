import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/widget/book_detail_screen.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:bookshelf/widget/genre_divider.dart';
import 'package:flutter/material.dart';

class GenreBooksSection extends StatelessWidget {
  final Genre genre;
  final List<Book> books;
  final List<Genre> genres;
  final Function(Book) onLongPressBook;
  final Future<void> Function(Book book, Genre targetGenre) onDropBook;

  const GenreBooksSection({
    required this.genre,
    required this.genres,
    required this.books,
    required this.onLongPressBook,
    required this.onDropBook,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final genreBooks = books
        .where((b) => b.genreid == genre.genreid && !b.isarchived)
        .toList();
    if (genreBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DragTarget<Book>(
          onAcceptWithDetails: (details) async  { 
            debugPrint('DROP FIRED : ${details.data.title} -> ${genre.name}');
            await onDropBook(details.data, genre);},
          builder: (context, candidateData, rejectedData) 
          {
            final isHovering = candidateData.isNotEmpty;
            return Container(
          color: 
          isHovering ? Colors.white.withOpacity
          (0.1) : Colors.transparent,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Text(
                genre.name,
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold
                  ),
              ),
              const SizedBox(
                width: 8
                ),
              const Icon(
                Icons.chevron_right, 
                size: 20
                ),
            ],
          ),
        ));},),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              GenreDivider(genre: genre),
              const SizedBox(width: 16),
              ...genreBooks.map((book) {
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
                      final genreMap = genres.where((g) => g.genreid == book.genreid).firstOrNull;

                      if(genreMap == null) return;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book, genre: genre)),
                      );
                    },
                  ),)
                    )
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
