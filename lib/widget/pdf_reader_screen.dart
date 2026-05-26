import 'dart:async';

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

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> with WidgetsBindingObserver{
  
   final PdfViewerController _pdfViewerController = PdfViewerController();
   late final _initialPage;
   int _currentPage = 1;
   Timer? _debounce;

   Future<void> _saveCurrentPage() async{
    if (_currentPage == _initialPage) return;
    try{
      await ref.read(bookRepositoryProvider).updateBook(widget.book.bookid, _currentPage);
      ref.invalidate(booksProvider);

    }
    catch(e, st){
      appLogger.e('Save Failed',error: e, stackTrace: st);
      _scheduleRetry();
    }
    }
  void _scheduleRetry([int attempts = 3]){
    if (attempts == 0) return;
    Future.delayed(Duration(seconds: 2,), (){
      _saveCurrentPage().catchError((_) => _scheduleRetry(attempts - 1));
    });
  }

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialPage = widget.book.lastpageread == 0? 1: widget.book.lastpageread;
    _currentPage = _initialPage;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused){
      Future.microtask(() => _saveCurrentPage());
    }
  }

  @override
  Widget build(BuildContext context){
    final book  = widget.book;
    return WillPopScope(child:  Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SfPdfViewer.file(
        File(book.filepath),
        canShowScrollHead: false,
        controller: _pdfViewerController,
        initialPageNumber: book.lastpageread == 0 ? 1 : book.lastpageread,
        onPageChanged: (PdfPageChangedDetails details) {
          _currentPage = details.newPageNumber;
          // _debounce?.cancel();
          _debounce = Timer(const Duration(seconds: 2), ()=> _saveCurrentPage());
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final totalpages = details.document.pages.count;

          if (widget.book.totalpages == 0){
            ref.read(bookRepositoryProvider).updateBookTotalPages(widget.book.bookid, totalpages);
          }

        },
      ),

    ),
    onWillPop: ()async{
      await _saveCurrentPage();
      return true;
    },
    );
  }

}