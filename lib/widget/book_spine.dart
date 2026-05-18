import 'package:bookshelf/data/models/book.dart';
import 'package:flutter/material.dart';

class BookSpine extends StatefulWidget{
  final Book book;
  final VoidCallback onTap;
  const BookSpine({
    super.key,
    required this.book,
    required this.onTap
  });


@override
State<BookSpine> createState() => _BookSpineState();


}
class _BookSpineState extends State<BookSpine>{
  bool isPulled = false;
  @override
  Widget build(BuildContext context) {

  final double progress = widget.book.totalPages > 0 ?(widget.book.lastPageRead / widget.book.totalPages).clamp(0.0, 1.0) 
  : 0.0; 

  return GestureDetector(
    onTapDown: (_) => setState(() => isPulled = true),
    onTapUp: (_)=> setState(() {
      isPulled = false;
    }),
    onTapCancel: () => setState(() {
      isPulled = false;
    }),
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      curve: Curves.elasticInOut,
      transform: Matrix4.translationValues(0, isPulled ? -16 : 0, 0),
      child: SizedBox(
        width: 52,
        height: 220,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(widget.book.spineColor),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(2,2)
                    ),
                  ],
                ),

              
            ),
            ),
            Center(
              child: RotatedBox(quarterTurns: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(widget.book.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                ),

                ),
                

              ),
              ),

            

            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                    
                  ),
                  minHeight: 3,

                ),

              ),
            
            )
          ],
        ),
      ),
      
    
    ),
    
    


  );


  }

}