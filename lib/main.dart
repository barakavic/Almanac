import 'dart:io';

import 'package:bookshelf/theme/app_theme.dart';
import 'package:bookshelf/widget/shelf_screen.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if(!kIsWeb && (Platform.isLinux || Platform.isWindows)){
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
   
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 * 1024 * 1024;

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
    child: const MyApp(),
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

