import 'dart:async';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/PdfReaderComponent/quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';

const List<double> invertColorMatrix = <double>[
  -1.0, 0.0, 0.0, 0.0, 255.0,
  0.0, -1.0, 0.0, 0.0, 255.0,
  0.0, 0.0, -1.0, 0.0, 255.0,
  0.0, 0.0, 0.0 , 1.0, 0.0
];
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
   String? _selectedText;
   final ScreenshotController _screenshotController = ScreenshotController();
   bool _isDarkMode = false;

   bool _showScrollHead = true;
   PdfScrollDirection _pdfScrollDirection = PdfScrollDirection.vertical;
   PdfPageLayoutMode _layoutMode = PdfPageLayoutMode.continuous;

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

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

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
    final pdfViewer = SfPdfViewer.file(
        File(book.filepath),
        canShowScrollHead: _showScrollHead,
        controller: _pdfViewerController,
        scrollDirection: _pdfScrollDirection,
        pageLayoutMode: _layoutMode,
        initialPageNumber: book.lastpageread == 0 ? 1 : book.lastpageread,
        onPageChanged: (PdfPageChangedDetails details) {
          _currentPage = details.newPageNumber;
          _debounce?.cancel();
          _debounce = Timer(const Duration(seconds: 2), ()=> _saveCurrentPage());
        },
        onTextSelectionChanged: (
          PdfTextSelectionChangedDetails details
        ){
          setState(() {
            _selectedText = details.selectedText;
          });
        },
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          final totalpages = details.document.pages.count;

          if (widget.book.totalpages == 0){
            ref.read(bookRepositoryProvider).updateBookTotalPages(widget.book.bookid, totalpages);
          }

        },

        
      );
    return WillPopScope(child:  Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(onPressed: _showReaderSettings, 
          icon: Icon(Icons.more_vert)
          )
        ],
      ),
      body: _isDarkMode ? ColorFiltered(
      colorFilter: const ColorFilter.matrix(invertColorMatrix), 
      child: pdfViewer)
      : pdfViewer,

      floatingActionButton: _selectedText != null && _selectedText!.isNotEmpty ? 
      FloatingActionButton.extended(onPressed: () async{
        final capturedImage = await _screenshotController.captureFromWidget(
          QuoteCard(text: _selectedText!, 
          bookTitle: book.title, 
          page: _currentPage
          ),
          delay: const Duration(
            milliseconds: 100
          ),

          
        );
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/quote.png').create();
        await imagePath.writeAsBytes(capturedImage);

        await Share.shareXFiles([XFile(imagePath.path)], text: 'Check out this quote!');
        final shareText = '"$_selectedText"\n\n-${book.title}, Page $_currentPage';
        Share.share(shareText);
      }, icon: const Icon(Icons.ios_share),
      label: const Text('Share Quote'),
      ): null,


    ),
    onWillPop: ()async{
      await _saveCurrentPage();
      return true;
    },
    );
  }

   void _showReaderSettings(){
      showModalBottomSheet(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setSheetState){
        return SafeArea(child: Wrap(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _isDarkMode,
              onChanged: (val) {
                setState(() => _isDarkMode = val);
                setSheetState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Show Scroll Head'),
              value: _showScrollHead,
              onChanged: (val){
                setState(()=> _showScrollHead =val);
                setSheetState(() {});
              },
              ),
            ListTile(
              title: const Text('Scroll Mode'),
              subtitle: Text(
                _layoutMode == PdfPageLayoutMode.continuous 
                ? 'Continuous' :  'Single Page'
                ),
                trailing: DropdownButton<PdfPageLayoutMode>(
                  value: _layoutMode,
                  items: const [
                    DropdownMenuItem(
                      value: PdfPageLayoutMode.continuous,
                      child: Text(
                        'Continuous'
                        ),),
                    DropdownMenuItem(
                      value: PdfPageLayoutMode.single,
                      child: Text('Single page'), 
                      ),

                ],
                onChanged: (val){
                  if ( val != null){
                    setState (() => _layoutMode = val);
                    setSheetState((){});

                  }
                },
                )
            ),

            ListTile(
              title: const Text('Scroll Direction'),
              subtitle: Text(
                _pdfScrollDirection == PdfScrollDirection.vertical ? 'Vertical': 'Horizontal'
                ),
              trailing: DropdownButton<PdfScrollDirection>(
                value: _pdfScrollDirection,
                items: [
                  DropdownMenuItem(
                    value: PdfScrollDirection.vertical,
                    child: Text('Vertical'),
                    ),
                    DropdownMenuItem(value: PdfScrollDirection.horizontal,
                    child: Text('Horizontal'),
                    ),
                ],
                onChanged: (val){
                  if (val != null){
                    setState(() => _pdfScrollDirection = val);
                    setSheetState((){});
                  }
                },
              ),
            )
          ],

        )
        );
      }));
    }

}