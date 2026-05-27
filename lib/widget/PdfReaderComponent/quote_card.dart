import 'package:flutter/material.dart';

class QuoteCard extends StatelessWidget{
  final String text;
  final String bookTitle;
  final int page;

  const QuoteCard({
    super.key, 
    required this.text, 
    required this.bookTitle,
    required this.page
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$text"',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic
            ),

          ),
          const SizedBox(height: 24,),
          Text("- $bookTitle",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16
          ),
          ),
          Text("Page $page",
          style: const TextStyle(color: Colors.white54,
          fontSize: 14
          ),)
        ],
      ),
    );
  }
}