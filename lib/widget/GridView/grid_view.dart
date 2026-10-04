import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/widget/book_detail_screen.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GridViewScreen extends ConsumerWidget {
  final List<Book> books;
  final List<Genre> genres;
  final void Function(Book book) onBookLongPress;

  const GridViewScreen({
    super.key,
    required this.books,
    required this.genres,
    required this.onBookLongPress,
  });

  Color? _deviceColor(Book book, List<Device> devices) {
    if (!book.isremote) return null;
    final device =
        devices.firstWhereOrNull((d) => d.deviceid == book.remotedeviceid);
    return switch (device?.platform) {
      'linux' => Colors.yellow,
      'windows' => Colors.red,
      'android' => Colors.green,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(pairedDevicesProvider);
    final devices = devicesAsync.valueOrNull ?? [];
    final genreMap = {for (final g in genres) g.genreid: g};

    if (books.isEmpty) {
      return const Center(child: Text('No Books Yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final genre = genreMap[book.genreid];
        final devColor = _deviceColor(book, devices);
        return BookGridCard(
          book: book,
          genre: genre,
          deviceColor: devColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: book, genre: genre),
              ),
            );
          },
          onLongPress: () => onBookLongPress(book),
        );
      },
    );
  }
}

class BookGridCard extends StatelessWidget {
  final Book book;
  final Genre? genre;
  final Color? deviceColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BookGridCard({
    super.key,
    this.genre,
    this.deviceColor,
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.totalpages == 0
        ? 0.0
        : (book.lastpageread / book.totalpages).clamp(0.0, 1.0);

    // Inner radius shrinks slightly when wrapped by an outer device border
    final innerRadius = deviceColor != null ? 12.0 : 16.0;

    final card = Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(innerRadius),
      clipBehavior: Clip.hardEdge,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(innerRadius),
          border: Border.all(
            color: genre != null
                ? Color(genre!.genrecolor)
                : Color(book.spinecolor),
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(innerRadius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.2,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  '${book.lastpageread}/${book.totalpages} pages',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (deviceColor == null) return card;

    // Outer device-platform coloured border
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: deviceColor!, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: card,
      ),
    );
  }
}
