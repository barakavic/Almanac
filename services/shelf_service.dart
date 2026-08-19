import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class AlmanacServer{
  HttpServer? _httpserver;
  final Router _router = Router();
  final BookRepository _bookrepository;

   Future<void> start() async{
    String ipAddress = '0.0.0.0';
    try{
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false
      );
      if (interfaces.isNotEmpty){
        ipAddress = interfaces.first.addresses.first.address;
      }
    }
    catch(e, st){
      appLogger.e("Failed to get LAN IP", error: e, stackTrace: st);
    }

    _router.get('/ping', _pinghandler);
    _router.get('/books', _bookshandler);

    _httpserver = await shelf_io.serve(_router.call, 
    ipAddress, 8675
    );
    appLogger.i('Almanac Server is running on http://$ipAddress:8675');


  }

  AlmanacServer(
    this._bookrepository

  );

  Future<shelf.Response> _pinghandler(shelf.Request request) async{
    final payload = {
      'device_name': Platform.localHostname,
      'platform' : Platform.operatingSystem,
      'available_storage_bytes' : 5000000000 // Hardcoded 50GB
    };
    return shelf.Response.ok(
      jsonEncode(payload),
      headers: {'Content-Type' : 'application/json'}
    );

  }

  Future<shelf.Response> _bookshandler(shelf.Request request) async{
    try{
      final books = await _bookrepository.getAllBooks();

      final booksJsonList = books.map((book) => book.toMap()).toList();

      return shelf.Response.ok(
        jsonEncode(booksJsonList),
        headers: {'Content-Type' : 'application/json'}
      );

    
    }
    catch(e, st){
      appLogger.e('Failed to fetch books for API', error: e, stackTrace: st);
      return shelf.Response.internalServerError(
        body: 'Failed to fetch books'
      );
    }
  }

  bool get isRunning => _httpserver != null;

  Future<void> stop() async {
    await _httpserver?.close(force: true);
    _httpserver = null;
    appLogger.i('Almanac Server Stopped');
  }

  
  
}