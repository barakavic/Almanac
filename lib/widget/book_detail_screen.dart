import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookDetailScreen extends ConsumerStatefulWidget{
  final Book book;
  final Genre genre;
  BookDetailScreen({
    super.key,
    required this.book,
    required this.genre
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState(); 
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> 
with SingleTickerProviderStateMixin{
  late TabController _tabController;

  @override
  void initState(){
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();

  }




  @override
  Widget build(BuildContext context) {


    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.book.bookid));
    final genreColorAsync =  ref.watch(genreColorByBookProvider(widget.book.bookid));
    final containerColor = genreColorAsync.
    valueOrNull != null? 
    Color(genreColorAsync.valueOrNull!) : 
    Theme.of(context).
    colorScheme.surfaceContainerHighest;
  
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title,        
        style: Theme.of(context).textTheme.headlineMedium 
        ),
        backgroundColor: Color(widget.book.spinecolor).withAlpha(3),
      ),
      body: Column(
        children: [
           Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: containerColor.withOpacity(0.14)
                ),
              
              child: Column(
              children: [Text(
              widget.book.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(
              height: 4
            ),
            Text(
              widget.book.author,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(
              height: 12
            ),

            LinearProgressIndicator(
              value: widget.book.totalpages == 0 ?
              0.0 :
              (widget.book.lastpageread / widget.book.totalpages).
              clamp(0.0, 1.0),
              minHeight: 8.0,
              borderRadius: BorderRadius.circular(12),
              color: Color(widget.book.spinecolor),
            ),
            ]
),),
            const SizedBox(
              height: 8.0
            ),
            Text(
              'Page ${widget.book.lastpageread} of ${widget.book.totalpages}',
              style: Theme.of(context).textTheme.bodySmall,

            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: (){
                Navigator.push(context, 
                MaterialPageRoute(builder: (_) => PdfReaderScreen(
                  book: widget.book
                  ))
                );
              }, 
              child: const Text('Continue Reading'),),
            ),
            
          ],
          

        ),
        
      ),

      TabBar(tabs: const[
        Tab(text: 'Chapters',),
        Tab(text: 'Summary',),
        Tab(text: 'Quiz')
      ],
      ),
      Expanded(
        child: TabBarView(
      controller: _tabController,
      children: [
        chaptersAsync.when(data: (chapters){
          if (chapters.isEmpty){
            return const Center(
              child: Text(
                'No Chapters Detected for This Book'
              ),


            );

          }

          return ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index){
              final chapter = chapters[index];
              return ListTile(
                title: Text(chapter.title),
                trailing: Text('pg. ${chapter.chapterstartpagenumber}'),
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PdfReaderScreen(
                      book: widget.book
                      ),
                      ),
                      );
                }
              );

            }
            );
        }, 
        error: (err, stack) => Center(child: Text('Error Loading Chapters, $err',),), 
        loading: () => Center(child: CircularProgressIndicator(

        ),
        ),
        ),
        
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('AI summaries coming soon'),
            ],
          ),
        ),

        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Quiz mode coming soon')
            ]
          ),
        )
      ],
      )
      )


        ],
      )      
    );
  }
}