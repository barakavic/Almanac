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
        File(book.filepath),
        controller: _pdfViewerController,
        initialPageNumber: book.lastpageread == 0 ? 1 : book.lastpageread,
        onPageChanged: (PdfPageChangedDetails details) {
          ref.read(bookRepositoryProvider).updateBook(
            book.bookid,
            details.newPageNumber,
          );
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final totalpages = details.document.pages.count;

          if (widget.book.totalpages == 0){
            ref.read(bookRepositoryProvider).updateBookTotalPages(widget.book.bookid, totalpages);
          }

        },
      ),

    );
  }

}