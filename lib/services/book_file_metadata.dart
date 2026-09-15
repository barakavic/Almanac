import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;

class BookFileMetadata {
  const BookFileMetadata({
    required this.sha256,
    required this.fileSizeBytes,
  });

  final String sha256;
  final int fileSizeBytes;

  static Future<BookFileMetadata> fromPath(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Book file does not exist', filePath);
    }

    final digest = await crypto.sha256.bind(file.openRead()).first;
    return BookFileMetadata(
      sha256: digest.toString(),
      fileSizeBytes: await file.length(),
    );
  }
}
