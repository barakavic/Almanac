import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
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
   late final _initialPage;
   int _currentPage = 1;

@override
  void initState() {
    super.initState();
    _initialPage = widget.book.lastpageread == 0 ? 1 : widget.book.lastpageread;
    _currentPage = _initialPage;
    super.initState();
  }

  @override
  void dispose() {
    if(_currentPage != _initialPage){
      ref.read(bookRepositoryProvider).updateBook(widget.book.bookid, _currentPage)
      .catchError((e, st){
        appLogger.e(e);

      });

    }
    super.dispose();
  }

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
          setState(()=> _currentPage = details.newPageNumber);
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