import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkMode = ThemeData(
    scaffoldBackgroundColor: Color(0xFF1A0F0A),
    
      colorScheme: ColorScheme.dark(
        surface: Color(0xFF2A1810),
        primary: Color(0xFF00B4A6),
        secondary: Color(0xFFC9A0DC),
        onSurface: Color(0xFFFDF6E3),

        
        error: Colors.red.shade600,
        
        
        

        
        
      ),
      textTheme: const TextTheme( bodyMedium: TextStyle(color: Color(0xFF9E8C7A)) ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF00B4A6),
        foregroundColor: Color(0xFF1A0F0A),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Color(0xFFC9A0DC)),
            foregroundColor: MaterialStateProperty.all(Color(0xFF1A0F0A)),
            
          ),
          

            

        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Color(0xFF1A0F0A)),
            side: MaterialStateProperty.all(BorderSide(color:
            Color(0xFF00B4A6))),
          ),



        ),

        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: Color(0xFFE8651A)
        )
    );

  
}