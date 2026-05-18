import 'package:bookshelf/data/models/genre.dart';
import 'package:flutter/material.dart';

class GenreDivider extends StatelessWidget{
  final Genre genre;
  const GenreDivider({super.key,
  required this.genre});

  @override
  Widget build(BuildContext context){
    return SizedBox(
      width: 36,
      height: 220,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10,
          width: 0.5
          ),

        
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            genre.name.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 70,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.0
            ),

            
          ),
          ),
          ),

      ),
      
    );
    
  }

}