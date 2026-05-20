import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
class PdfReaderScreen extends ConsumerStatefulWidget{
  final Book book;
  

  const PdfReaderScreen({super.key, required this.book});
  
  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();

  

  
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen>{
  
   final PdfViewerController _pdfViewerController = PdfViewerController();
     

  @override
  Widget build(BuildContext context){
    final book  = widget.book;
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SfPdfViewer.file(
        controller: _pdfViewerController,
        File(book.filepath),
        initialPageNumber: book.lastPageRead == 0 ? 1 : book.lastPageRead,
        onPageChanged: (PdfPageChangedDetails details) {
          ref.read(bookRepositoryProvider).updateBook(
            book.bookid,
            details.newPageNumber,
          );
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final totalPages = details.document.pages.count;

          if (widget.book.totalPages == 0){
            ref.read(bookRepositoryProvider).updateBook(widget.book.bookid, totalPages);
          }

        },
      ),

    );
  }

}