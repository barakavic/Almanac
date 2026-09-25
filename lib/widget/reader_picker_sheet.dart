import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/reader_option.dart';
import 'package:bookshelf/services/reader_service.dart';
import 'package:flutter/material.dart';

class ReaderPickerSheet extends StatelessWidget {
  final Book book;

  const ReaderPickerSheet({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: FutureBuilder<List<ReaderOption>>(
          future: ReaderService.availableReaders(),
          builder: (context, snapshot) {
            final readers = snapshot.data ?? const <ReaderOption>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Open with',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Unable to load readers'),
                  )
                else if (readers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No readers available'),
                  )
                else
                  ...readers.map(
                    (reader) => ListTile(
                      leading: Icon(reader.icon),
                      title: Text(reader.displayname),
                      onTap: () {
                        Navigator.pop(context);
                        ReaderService.openWith(reader, book, context);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
