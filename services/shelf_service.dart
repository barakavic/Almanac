import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:disk_space/disk_space.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class AlmanacServer{

  
  HttpServer? _httpserver;
  final Router _router = Router();
  final BookRepository _bookrepository;
  String _pairingToken = '';

    void setPairingToken(String token){
    _pairingToken = token;
  }

  shelf.Handler get _handler => shelf.Pipeline()
  .addMiddleware(_authMiddleware())
  .addHandler(_router.call);

  shelf.Middleware _authMiddleware(){
    return (shelf.Handler innerHandler){
      return (shelf.Request request) async{
        if (request.url.path == 'pair'){
          return innerHandler(request);
        }

        final token = request.headers['x-almanac-token'];
        if (token == null || token != _pairingToken){
          return shelf.Response.forbidden(
            jsonEncode(
              {'error': 'Unauthorized Device'}
            ),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return innerHandler(request);
      };
    };
  }

 
    
   Future<void> start() async{
    final ipAddress = await _getLanIp();
    _httpserver = await shelf_io.serve(_handler, 
    ipAddress, 8765
    );
    appLogger.i('Almanac Server is running on http://$ipAddress:8765');


  }

  AlmanacServer(
    this._bookrepository

  ){
    _router.get('/ping', _pinghandler);
    _router.get('/books', _bookshandler);
  }

  Future<shelf.Response> _pinghandler(shelf.Request request) async{
    final diskSpace = await DiskSpace.getFreeDiskSpace;
    final payload = {
      'device_name': Platform.localHostname,
      'platform' : Platform.operatingSystem,
      'available_storage_bytes' : diskSpace ?? 0
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

  
  Future<String> _getLanIp() async{
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4
  );
  for (final interface in interfaces){
    for (final address in interface.addresses){
      if (!address.isLoopback) return address.address;

    }
   
  }
   return '0.0.0.0';
}
  



  
}

