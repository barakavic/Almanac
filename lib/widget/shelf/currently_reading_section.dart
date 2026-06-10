import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/widget/book_spine.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:flutter/material.dart';

class CurrentlyReadingSection extends StatelessWidget {
  final List<Book> books;
  final Function(Book) onReassignBook;

  const CurrentlyReadingSection({
    required this.books,
    required this.onReassignBook,
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
                child: GestureDetector(
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.open_in_new),
                              title: const Text('Open'),
                              onTap: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.archive),
                              title: const Text('Archive'),
                              onTap: () {
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.close),
                              title: const Text('Cancel'),
                              onTap: () => Navigator.pop(ctx),
                            ),
                            ListTile(
                              leading: const Icon(Icons.swap_horiz),
                              title: const Text('Reassign'),
                              onTap: () {
                                Navigator.pop(ctx);
                                onReassignBook(book);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
