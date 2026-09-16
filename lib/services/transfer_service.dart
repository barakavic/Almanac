import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/models/pending_transfer.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/data/repository/pending_transfer_repository.dart';
import 'package:bookshelf/data/repository/watched_folder_repository.dart';
import 'package:bookshelf/services/book_file_metadata.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/utils/device_identity.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class NoWatchedFolderException implements Exception {
  final String message;
  NoWatchedFolderException([this.message = 'No watched folder declared on this device. Please declare a watched folder before downloading.']);

  @override
  String toString() => message;
}

class TransferStorageException implements Exception {
  final String message;
  const TransferStorageException(this.message);

  @override
  String toString() => message;
}

class TransferProgressState {
  final bool isTransferring;
  final double speedKbps;
  final int bytesRemaining;
  final Duration estimatedTimeRemaining;
  final int completedBooksCount;
  final int totalBooksCount;
  final String currentBookTitle;

  const TransferProgressState({
    this.isTransferring = false,
    this.speedKbps = 0.0,
    this.bytesRemaining = 0,
    this.estimatedTimeRemaining = Duration.zero,
    this.completedBooksCount = 0,
    this.totalBooksCount = 0,
    this.currentBookTitle = '',
  });

  TransferProgressState copyWith({
    bool? isTransferring,
    double? speedKbps,
    int? bytesRemaining,
    Duration? estimatedTimeRemaining,
    int? completedBooksCount,
    int? totalBooksCount,
    String? currentBookTitle,
  }) {
    return TransferProgressState(
      isTransferring: isTransferring ?? this.isTransferring,
      speedKbps: speedKbps ?? this.speedKbps,
      bytesRemaining: bytesRemaining ?? this.bytesRemaining,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      completedBooksCount: completedBooksCount ?? this.completedBooksCount,
      totalBooksCount: totalBooksCount ?? this.totalBooksCount,
      currentBookTitle: currentBookTitle ?? this.currentBookTitle,
    );
  }
}

class TransferService {
  final BookRepository _bookRepository;
  final WatchedFolderRepository _watchedFolderRepository;
  final PendingTransferRepository _pendingTransferRepository;
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 5;

  bool _cancelCurrentTransfer = false;

  final ValueNotifier<TransferProgressState> progressNotifier =
      ValueNotifier(const TransferProgressState());

  TransferService(
    this._bookRepository,
    this._watchedFolderRepository,
    this._pendingTransferRepository,
  );

  Future<List<Book>> fetchRemoteManifest(Device remoteDevice) async {
    if (remoteDevice.ipaddress.isEmpty || remoteDevice.pairingcode == null) {
      appLogger.w('Cannot fetch manifest: missing IP or pairing code for ${remoteDevice.devicename}');
      return [];
    }

    try {
      final url = Uri.parse('http://${remoteDevice.ipaddress}:${remoteDevice.port}/books/manifest');
      final response = await http.get(
        url,
        headers: {
          'x-almanac-token': remoteDevice.pairingcode!,
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Book.fromMap(item as Map<String, dynamic>)).toList();
      } else {
        appLogger.w('Failed to fetch manifest from ${remoteDevice.devicename}: ${response.statusCode}');
      }
    } catch (e, st) {
      appLogger.e('Error fetching manifest from ${remoteDevice.devicename}', error: e, stackTrace: st);
    }

    return [];
  }

  Future<bool> _hasExternalStorageWriteAccess(String path) async {
    if (!Platform.isAndroid) return true;

    final appDocumentsDir = await getApplicationDocumentsDirectory();
    final isAppOwnedPath = path.startsWith(appDocumentsDir.path) ||
        path.contains('/Android/data/') ||
        path.contains('/app_flutter/');

    if (isAppOwnedPath) return true;

    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    if (status.isLimited) return true;

    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      final requested = await Permission.storage.request();
      return requested.isGranted || requested.isLimited;
    }

    return false;
  }

  Future<String> _getDestinationFolderPath() async {
    final deviceId = await getDeviceFingerprint();
    final folders = await _watchedFolderRepository.getFolderForDevice(deviceId);

    if (folders.isEmpty) {
      throw NoWatchedFolderException();
    }

    final activeFolder = folders.firstWhere(
      (f) => f.isavailable == 1 && f.absolutepath.isNotEmpty,
      orElse: () => folders.first,
    );

    if (activeFolder.absolutepath.isEmpty) {
      throw NoWatchedFolderException();
    }

    final preferredDir = Directory(activeFolder.absolutepath);
    final fallbackDir = await getApplicationDocumentsDirectory();
    final safeDir = Directory(p.join(fallbackDir.path, 'library'));

    try {
      if (!await preferredDir.exists()) {
        await preferredDir.create(recursive: true);
      }

      final hasWriteAccess = await _hasExternalStorageWriteAccess(activeFolder.absolutepath);
      if (!hasWriteAccess) {
        if (!await safeDir.exists()) {
          await safeDir.create(recursive: true);
        }
        return safeDir.path;
      }

      final probeFile = File(p.join(preferredDir.path, '.bookshelf_write_test'));
      await probeFile.writeAsString('ok');
      await probeFile.delete();
      return activeFolder.absolutepath;
    } on PathAccessException {
      if (!await safeDir.exists()) {
        await safeDir.create(recursive: true);
      }
      return safeDir.path;
    } on FileSystemException {
      if (!await safeDir.exists()) {
        await safeDir.create(recursive: true);
      }
      return safeDir.path;
    }
  }

  Future<void> cancelCurrentTransfer() async {
    _cancelCurrentTransfer = true;
    progressNotifier.value = progressNotifier.value.copyWith(
      isTransferring: false,
      currentBookTitle: '',
    );
  }

  Future<void> enqueueOfflineTransfer({
    required Device remoteDevice,
    required Book remoteBook,
  }) async {
    final myDeviceId = await getDeviceFingerprint();

    final remoteStub = Book(
      bookid: remoteBook.bookid,
      title: remoteBook.title,
      author: remoteBook.author,
      filepath: null,
      spinecolor: remoteBook.spinecolor,
      genreid: remoteBook.genreid,
      subgenreid: remoteBook.subgenreid,
      lastpageread: remoteBook.lastpageread,
      totalpages: remoteBook.totalpages,
      isarchived: remoteBook.isarchived,
      addedat: DateTime.now(),
      isremote: true,
      remotedeviceid: remoteDevice.deviceid,
      deviceid: myDeviceId,
      sha256: remoteBook.sha256,
      filesizebytes: remoteBook.filesizebytes,
    );

    await _bookRepository.addBook(remoteStub);

    final transferId = const Uuid().v4();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'transfer_$transferId.tmp'));

    final pendingTransfer = PendingTransfer(
      transferid: transferId,
      bookid: remoteBook.bookid,
      sourcedeviceid: remoteDevice.deviceid ?? '',
      targetdeviceid: myDeviceId,
      filechecksum: remoteBook.sha256 ?? '',
      filesizebytes: remoteBook.filesizebytes ?? 0,
      transfertype: TransferType.direct,
      currenthop: 1,
      priority: 1,
      status: TransferStatus.waitingForSource,
      retrycount: 0,
      temppath: tempFile.path,
      lastattemptedat: DateTime.now(),
      createdat: DateTime.now(),
    );

    await _pendingTransferRepository.enqueueTransfer(pendingTransfer);
    appLogger.i('Queued offline transfer for "${remoteBook.title}" from ${remoteDevice.devicename}');
  }

  Future<void> processQueueForDevice(Device remoteDevice) async {
    if (remoteDevice.deviceid == null) return;

    final waitingTransfers = await _pendingTransferRepository.getTransfersWaitingForSource(remoteDevice.deviceid!);

    if (waitingTransfers.isEmpty) return;

    appLogger.i('Processing ${waitingTransfers.length} queued transfer(s) for ${remoteDevice.devicename}');

    for (final transfer in waitingTransfers) {
      if (transfer.retrycount >= _maxRetries) {
        await _pendingTransferRepository.expireTransfer(transfer.transferid);
        appLogger.w('Transfer ${transfer.transferid} expired after exceeding $_maxRetries retries');
        continue;
      }

      await _pendingTransferRepository.incrementRetry(transfer.transferid);
      final book = await _bookRepository.getBookById(transfer.bookid);

      if (book == null) {
        await _pendingTransferRepository.updateStatus(transfer.transferid, TransferStatus.failed);
        continue;
      }

      try {
        await downloadBook(remoteDevice: remoteDevice, remoteBook: book);
      } catch (e) {
        appLogger.w('Retry failed for transfer ${transfer.transferid}: $e');
      }
    }
  }

  Future<bool> downloadBatch({
    required Device remoteDevice,
    required List<Book> books,
  }) async {
    if (books.isEmpty) return true;

    int totalBatchBytes = books.fold(0, (sum, b) => sum + (b.filesizebytes ?? 0));
    int completedBooks = 0;
    int bytesDownloadedTotal = 0;

    progressNotifier.value = TransferProgressState(
      isTransferring: true,
      speedKbps: 0.0,
      bytesRemaining: totalBatchBytes,
      estimatedTimeRemaining: Duration.zero,
      completedBooksCount: 0,
      totalBooksCount: books.length,
      currentBookTitle: books.first.title,
    );

    for (int i = 0; i < books.length; i++) {
      final book = books[i];
      progressNotifier.value = progressNotifier.value.copyWith(
        completedBooksCount: i,
        currentBookTitle: book.title,
      );

      final success = await downloadBookInternal(
        remoteDevice: remoteDevice,
        remoteBook: book,
        onChunk: (chunkLength, speedKbps) {
          bytesDownloadedTotal += chunkLength;
          final remainingBytes = totalBatchBytes - bytesDownloadedTotal;
          final safeRemainingBytes = remainingBytes < 0 ? 0 : remainingBytes;

          Duration remainingTime = Duration.zero;
          if (speedKbps > 0) {
            final secondsLeft = (safeRemainingBytes / (speedKbps * 1024)).round();
            remainingTime = Duration(seconds: secondsLeft);
          }

          progressNotifier.value = progressNotifier.value.copyWith(
            speedKbps: speedKbps,
            bytesRemaining: safeRemainingBytes,
            estimatedTimeRemaining: remainingTime,
          );
        },
      );

      if (success) {
        completedBooks++;
      } else {
        await enqueueOfflineTransfer(remoteDevice: remoteDevice, remoteBook: book);
      }
    }

    progressNotifier.value = const TransferProgressState(isTransferring: false);
    return completedBooks == books.length;
  }

  Future<bool> downloadBook({
    required Device remoteDevice,
    required Book remoteBook,
  }) async {
    return downloadBatch(remoteDevice: remoteDevice, books: [remoteBook]);
  }

  Future<bool> downloadBookInternal({
    required Device remoteDevice,
    required Book remoteBook,
    required void Function(int chunkLength, double speedKbps) onChunk,
  }) async {
    _cancelCurrentTransfer = false;
    final destFolder = await _getDestinationFolderPath();

    if (remoteBook.sha256 != null && remoteBook.sha256!.isNotEmpty) {
      final localDuplicate = await _bookRepository.getLocalBookByChecksum(remoteBook.sha256!);
      if (localDuplicate != null && localDuplicate.filepath != null) {
        appLogger.i('Book "${remoteBook.title}" already exists locally at ${localDuplicate.filepath}. Skipping download.');
        return true;
      }
    }

    final transferId = const Uuid().v4();
    final myDeviceId = await getDeviceFingerprint();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, 'transfer_$transferId.tmp'));

    final pendingTransfer = PendingTransfer(
      transferid: transferId,
      bookid: remoteBook.bookid,
      sourcedeviceid: remoteDevice.deviceid ?? '',
      targetdeviceid: myDeviceId,
      filechecksum: remoteBook.sha256 ?? '',
      filesizebytes: remoteBook.filesizebytes ?? 0,
      transfertype: TransferType.direct,
      currenthop: 1,
      priority: 1,
      status: TransferStatus.transferring,
      retrycount: 0,
      temppath: tempFile.path,
      lastattemptedat: DateTime.now(),
      createdat: DateTime.now(),
    );

    await _pendingTransferRepository.enqueueTransfer(pendingTransfer);

    try {
      final downloadUrl = Uri.parse('http://${remoteDevice.ipaddress}:${remoteDevice.port}/books/${remoteBook.bookid}/download');
      final request = http.Request('GET', downloadUrl);
      request.headers['x-almanac-token'] = remoteDevice.pairingcode ?? '';

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        appLogger.w('Download failed with status code ${response.statusCode}');
        await _pendingTransferRepository.updateStatus(transferId, TransferStatus.failed);
        return false;
      }

      final sink = tempFile.openWrite();
      final stopwatch = Stopwatch()..start();
      int bytesReceivedInSample = 0;
      int sampleStartTime = stopwatch.elapsedMilliseconds;

      await for (final chunk in response.stream) {
        if (_cancelCurrentTransfer) {
          await sink.close();
          await _pendingTransferRepository.cancelTransfer(transferId);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          return false;
        }

        sink.add(chunk);
        bytesReceivedInSample += chunk.length;

        final now = stopwatch.elapsedMilliseconds;
        final elapsedSampleTime = now - sampleStartTime;

        if (elapsedSampleTime >= 300) {
          final speedKbps = (bytesReceivedInSample / (elapsedSampleTime / 1000)) / 1024;
          onChunk(bytesReceivedInSample, speedKbps);
          bytesReceivedInSample = 0;
          sampleStartTime = now;
        }
      }

      if (bytesReceivedInSample > 0) {
        final elapsedSampleTime = (stopwatch.elapsedMilliseconds - sampleStartTime);
        final speedKbps = elapsedSampleTime > 0
            ? (bytesReceivedInSample / (elapsedSampleTime / 1000)) / 1024
            : 0.0;
        onChunk(bytesReceivedInSample, speedKbps);
      }

      await sink.close();
      client.close();

      final downloadedMetadata = await BookFileMetadata.fromPath(tempFile.path);

      if (remoteBook.sha256 != null &&
          remoteBook.sha256!.isNotEmpty &&
          downloadedMetadata.sha256 != remoteBook.sha256) {
        appLogger.e('Checksum mismatch for "${remoteBook.title}". Expected: ${remoteBook.sha256}, Got: ${downloadedMetadata.sha256}');
        if (await tempFile.exists()) await tempFile.delete();
        await _pendingTransferRepository.updateStatus(transferId, TransferStatus.failed);
        return false;
      }

      await _pendingTransferRepository.updateStatus(transferId, TransferStatus.verifying);

      final ext = p.extension(remoteBook.filepath ?? '.pdf');
      final finalFileName = '${remoteBook.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_')}${ext.isEmpty ? '.pdf' : ext}';
      final finalPath = p.join(destFolder, finalFileName);

      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.copy(finalPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final updatedBook = Book(
        bookid: remoteBook.bookid,
        title: remoteBook.title,
        author: remoteBook.author,
        filepath: finalPath,
        spinecolor: remoteBook.spinecolor,
        genreid: remoteBook.genreid,
        subgenreid: remoteBook.subgenreid,
        lastpageread: remoteBook.lastpageread,
        totalpages: remoteBook.totalpages,
        isarchived: remoteBook.isarchived,
        addedat: DateTime.now(),
        isremote: false,
        remotedeviceid: null,
        deviceid: myDeviceId,
        lastopenedat: remoteBook.lastopenedat,
        sha256: downloadedMetadata.sha256,
        filesizebytes: downloadedMetadata.fileSizeBytes,
      );

      await _bookRepository.addBook(updatedBook);
      await _pendingTransferRepository.updateStatus(transferId, TransferStatus.complete);

      appLogger.i('Successfully transferred "${remoteBook.title}" to $finalPath');
      return true;
    } catch (e, st) {
      appLogger.e('Error during book transfer', error: e, stackTrace: st);
      if (await tempFile.exists()) {
        try { await tempFile.delete(); } catch (_) {}
      }
      if (_cancelCurrentTransfer) {
        await _pendingTransferRepository.cancelTransfer(transferId);
        return false;
      }
      await _pendingTransferRepository.updateStatus(transferId, TransferStatus.failed);
      rethrow;
    }
  }
}
