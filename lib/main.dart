import 'package:bookshelf/theme/app_theme.dart';
import 'package:bookshelf/widget/shelf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;
  runApp(const ProviderScope(
    child: MyApp(),
  ));
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookshelf',
      theme: AppTheme.darkMode,
      darkTheme: AppTheme.darkMode,
      themeMode: ThemeMode.system,
      home: const ShelfScreen(),

    );

  }
}

