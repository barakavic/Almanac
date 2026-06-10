import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:bookshelf/widget/reassign_book_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookActionsSheet extends ConsumerWidget{
  final Book book;
  const BookActionsSheet({
    super.key, required this.book
    });

    @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: (){
              Navigator.pop(
                context
              );
              Navigator.push(
                context, MaterialPageRoute(
                  builder: 
                  (_)=> PdfReaderScreen(book: book)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.archive),
            title: const Text('Archive'),
            onTap: (){
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: Icon(Icons.swap_horiz),
            title: const Text(
              'Reassign'
            ),
            onTap: () {
              Navigator.pop(context);

              showModalBottomSheet(
                context: context, 
                isScrollControlled: true,
                builder: 
              (ctx) => ReassignBookSheet(book: book)
              );
              
            },
          ),

          ListTile(
            leading: Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          )

        ],
      )
      );
  }
}
