import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:bookshelf/data/repository/book_repository.dart';

final dbHelperProvider = Provider<DbHelper>((ref) {
  return DbHelper();
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(ref.watch(dbHelperProvider));
});

class PdfReaderScreen extends ConsumerWidget{
  final Book book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SfPdfViewer.file(
        File(book.filepath),
        initialPageNumber: book.lastPageRead == 0 ? 1 : book.lastPageRead,
        onPageChanged: (PdfPageChangedDetails details) {
          ref.read(bookRepositoryProvider).updateBook(
            book.bookId,
            details.newPageNumber,
          );
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {},
      ),

    );
  }
}