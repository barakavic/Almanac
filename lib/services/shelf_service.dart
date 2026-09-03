import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/data/repository/device_repository.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:uuid/uuid.dart';

class AlmanacServer{

  
  HttpServer? _httpserver;
  final Router _router = Router();
  final BookRepository _bookrepository;
  String _pairingToken = '';
  final DeviceRepository _deviceRepository;
  final String localDeviceUuid;

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
    this._bookrepository,
    this._deviceRepository,
    this.localDeviceUuid

  ){
    _router.get('/ping', _pinghandler);
    _router.get('/books', _bookshandler);
    _router.post('/pair', _pairhandler);
  }

  Future<shelf.Response> _pinghandler(shelf.Request request) async{
    final diskSpace = await DiskSpacePlus().getFreeDiskSpace;
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


Future<shelf.Response> _pairhandler( shelf.Request request) async {
    

  try {
    final payloadString = await request.readAsString();
    final payload = await jsonDecode(payloadString) as Map<String, dynamic>;

    final incomingDevice = Device.fromMap(payload);

    await _deviceRepository.addDevice(incomingDevice);
    appLogger.i('Paired Successfully with ${incomingDevice.devicename}');

    final myDevice = Device(
    deviceid:  const Uuid().v4(), 
    devicename: Platform.localHostname,
    platform: Platform.operatingSystem,
    macaddress: localDeviceUuid, //localDeviceUuid is initialized in the main.dart
    port: 8765, 
    createdat: DateTime.now().toIso8601String(), 
    lastseenat: DateTime.now().toIso8601String()
    );
    return shelf.Response.ok(
      jsonEncode(myDevice.toMap()),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, st) {
    appLogger.e('failed to create process pairing request', error: e, stackTrace: st);
    return shelf.Response.internalServerError(
      body: jsonEncode(
        {'error': 'Failed to process pairing request'}
      ),
      headers: {'Content-Type': 'application/json'},
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

