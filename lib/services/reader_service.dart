import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/reader_option.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/services/reading_session_detector.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:device_apps_plus/device_apps_plus.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<String?> findExecutableLinux(String linuxExecutable) async{
  final result = await Process.run('which', [linuxExecutable]);
  final path = result.stdout;
  if (result.exitCode ==0 ){
    return path.toString().trim();
  }
  else{
    return null;
  }
}

Future<String?> findExecutableWindows(String windowsExecutable)async{
  final result = await Process.run('where', [windowsExecutable], runInShell: true);
  final path = (result.stdout);
  if(result.exitCode == 0){
    return path.toString().trim();
  }
  else{
    return null;
  }
}

Future<bool> isInstalled(ReaderOption reader)async{
  if (reader.id == 'almanac'){
    return true;

  }
  if (Platform.isAndroid){
    if (reader.androidPackage == null ){
      return false;
  }
  final installed = await DeviceAppsPlus().isAppInstalled(reader.androidPackage!);
  return installed;
  
  }
  if (Platform.isLinux){
  if (reader.linuxExecutable == null) return false;
  final path = await findExecutableLinux(reader.linuxExecutable!);
  if (path != null) return true;

  if (reader.linuxFallbacks != null){
    for (final fallback in reader.linuxFallbacks!){
      final fallbackPath = await findExecutableLinux(fallback);
      if (fallbackPath != null)return true;
    }
  }
  return false;
}
  if (Platform.isWindows ){
    if (reader.windowsExecutable == null)return false;
    final path = await findExecutableWindows(reader.windowsExecutable!);
    return path != null;
  }
return false;
}

Future<List<ReaderOption>> listAvailableReaders() async{
  final String? currentPlatform;

  if (Platform.isAndroid){
    currentPlatform = 'android';

  }
  else if(Platform.isLinux){
    currentPlatform = 'linux';
  }
  else if(Platform.isWindows){
    currentPlatform = 'windows';
  }
  else {
    return [];
  }
  final List<ReaderOption> available = [];

  for (final reader in ReaderOption.all){
    if (!reader.platforms.contains(currentPlatform)) continue;

    final installed = await isInstalled(reader);
    if(installed) available.add(reader);
  }
  return available;
}

Future<List<ReaderOption>> availableReaders() async => listAvailableReaders();

class ReaderService {
  static final Map<String, StreamSubscription<FileSystemEvent>> _subscriptions = {};

  static Future<List<ReaderOption>> availableReaders() => listAvailableReaders();

  static Future<void> openWith(ReaderOption reader, Book book, BuildContext context) async {
    return launchReaderWith(reader, book, context);
  }

  static Future<void> startWatching(Book book, {BookRepository? bookRepository}) async {
    if (Platform.isAndroid) return;

    final filepath = book.filepath;
    if (filepath == null || filepath.isEmpty) return;

    final file = File(filepath);
    if (!await file.exists()) return;

    await stopWatching(book.bookid);

    final repo = bookRepository ?? BookRepository(DbHelper());

    final subscription = file.watch().listen((event) async {
      if (event.type == FileSystemEvent.modify || event is FileSystemEvent) {
        final detectedPage = await ReadingSessionDetector().detect(book);
        if (detectedPage != null) {
          await repo.updateBook(book.bookid, detectedPage);

          try {
            final bytes = await file.readAsBytes();
            final newHash = sha256.convert(bytes).toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('hash_${book.bookid}', newHash);
            appLogger.i('Silently updated page to $detectedPage for book ${book.bookid}');
          } catch (e) {
            appLogger.e('Failed to update hash post-detection', error: e);
          }
        }
      }
    });

    _subscriptions[book.bookid] = subscription;
  }

  static Future<void> stopWatching(String bookId) async {
    final sub = _subscriptions.remove(bookId);
    await sub?.cancel();
  }

  static Future<void> stopAllWatching() async {
    for (final sub in _subscriptions.values) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  static bool isWatching(String bookId) => _subscriptions.containsKey(bookId);
}

Future<void> launchReaderWith(ReaderOption reader, Book book, BuildContext context) async{
  if (reader.id == 'almanac'){
    Navigator.push(context, 
    MaterialPageRoute(builder: (context) => 
    PdfReaderScreen(book: book),
    ));
    return;

  }

  await _takePreopenSnapshot(book, reader.id);
  await ReaderService.startWatching(book);

  if (Platform.isAndroid){
    await OpenFile.open(book.filepath);
  }

  if (Platform.isLinux){
    final executablePath = await findExecutableLinux(reader.linuxExecutable!);
    if (executablePath == null){
      if (context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${reader.displayname} not found on this device'))
        );
      }
      return;
    }
    await Process.run(executablePath, [book.filepath ?? '']);
  }

  if (Platform.isWindows){
    final executablePath = await findExecutableWindows(reader.windowsExecutable!);
    if (executablePath == null){
      if (context.mounted){
        ScaffoldMessenger.of(context).
        showSnackBar(SnackBar(
          content: Text(
            '${reader.displayname} not found on this device'
          )));

      }
      return;
    }
    await Process.run(executablePath, [book.filepath ?? ''] , runInShell: true);
  }

  
}

Future<void> openWith(ReaderOption reader, Book book, BuildContext context) async => launchReaderWith(reader, book, context);

Future<void> _takePreopenSnapshot(Book book, String readerid) async{
    final prefs = await SharedPreferences.getInstance();
    final bytes = await File(book.filepath ?? '' ).readAsBytes();
    final hash = sha256.convert(bytes).toString();
    prefs.setString('hash_${book.bookid}', hash);

    final document = PdfDocument(inputBytes: bytes);
    final Map<int, int> snapshot = {};

    for (int i = 0; i < document.pages.count; i++){
      final count = document.pages[i].annotations.count;
      if (count > 0){
        snapshot[i + 1] = count;
      }
    }

    document.dispose();

    prefs.setString('snapshot_${book.bookid}', jsonEncode(snapshot.map((k, v) => MapEntry(k.toString(), v))));


    prefs.setString('session_start_${book.bookid}', DateTime.now().toIso8601String());

    prefs.setString('last_reader_${book.bookid}', readerid);



  }
