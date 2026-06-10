import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:flutter/material.dart';

class UnsortedBooksSection extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onLongPressBook;

  const UnsortedBooksSection({
    required this.books,
    required this.onLongPressBook,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final unassignedBooks = books.where((b) => b.genreid == null && !b.isarchived).toList();
    if (unassignedBooks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            "Unsorted Books",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: unassignedBooks.map((book) {
              return GestureDetector(
                onLongPress: () => onLongPressBook(book),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: BookSpine(
                    book: book,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
