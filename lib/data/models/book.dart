import 'package:bookshelf/utils/app_logger.dart';

class Book {
  final String bookid;
  final String title;
  final String author;
  final String? filepath;
  final int spinecolor;
  final String? genreid;
  final String? subgenreid;
  final int lastpageread;
  final int totalpages;
  final bool isarchived;
  final DateTime addedat;
  final bool isremote;
  final String? remotedeviceid;
  final String? deviceid;
  final DateTime? lastopenedat;
  final String? sha256;
  final int? filesizebytes;
  final int isindexed;

  const Book({
    required this.bookid,
    required this.title,
    required this.author,
    this.filepath,
    required this.spinecolor,
    this.genreid,
    this.subgenreid,
    required this.lastpageread,
    required this.totalpages,
    required this.isarchived,
    required this.addedat,
    this.isremote = false,
    this.remotedeviceid,
    this.deviceid,
    this.lastopenedat,
    this.sha256,
    this.filesizebytes,
    this.isindexed = 0,
  });

  Book copyWith({
    String? bookid,
    String? title,
    String? author,
    String? filepath,
    int? spinecolor,
    String? genreid,
    String? subgenreid,
    int? lastpageread,
    int? totalpages,
    bool? isarchived,
    DateTime? addedat,
    bool? isremote,
    String? remotedeviceid,
    String? deviceid,
    DateTime? lastopenedat,
    String? sha256,
    int? filesizebytes,
    int? isindexed,
  }) {
    return Book(
      bookid: bookid ?? this.bookid,
      title: title ?? this.title,
      author: author ?? this.author,
      filepath: filepath ?? this.filepath,
      spinecolor: spinecolor ?? this.spinecolor,
      genreid: genreid ?? this.genreid,
      subgenreid: subgenreid ?? this.subgenreid,
      lastpageread: lastpageread ?? this.lastpageread,
      totalpages: totalpages ?? this.totalpages,
      isarchived: isarchived ?? this.isarchived,
      addedat: addedat ?? this.addedat,
      isremote: isremote ?? this.isremote,
      remotedeviceid: remotedeviceid ?? this.remotedeviceid,
      deviceid: deviceid ?? this.deviceid,
      lastopenedat: lastopenedat ?? this.lastopenedat,
      sha256: sha256 ?? this.sha256,
      filesizebytes: filesizebytes ?? this.filesizebytes,
      isindexed: isindexed ?? this.isindexed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookid': bookid,
      'title': title,
      'author': author,
      'filepath': filepath,
      'spinecolor': spinecolor,
      'genreid': genreid,
      'subgenreid': subgenreid,
      'lastpageread': lastpageread,
      'totalpages': totalpages,
      'isarchived': isarchived ? 1 : 0,
      'addedat': addedat.toIso8601String(),
      'isremote': isremote ? 1 : 0,
      'remotedeviceid': remotedeviceid,
      'deviceid': deviceid,
      'lastopenedat': lastopenedat?.toIso8601String(),
      'sha256': sha256,
      'filesizebytes': filesizebytes,
      'isindexed': isindexed,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    try {
      final lastOpenedAt = map['lastopenedat'] as String?;
      return Book(
        bookid: map['bookid'] ?? '',
        title: map['title'] ?? '',
        author: map['author'] ?? '',
        filepath: map['filepath'] as String?,
        spinecolor: map['spinecolor'] ?? 0,
        genreid: map['genreid'],
        subgenreid: map['subgenreid'],
        lastpageread: map['lastpageread'] ?? 0,
        totalpages: map['totalpages'] ?? 0,
        isarchived: map['isarchived'] == 1,
        addedat: DateTime.parse(map['addedat']),
        isremote: map['isremote'] == 1,
        remotedeviceid: map['remotedeviceid'],
        deviceid: map['deviceid'],
        lastopenedat: lastOpenedAt == null
            ? null
            : DateTime.parse(lastOpenedAt),
        sha256: map['sha256'],
        filesizebytes: map['filesizebytes'] as int?,
        isindexed: map['isindexed'] as int? ?? 0,
      );
    } catch (e, st) {
      appLogger.e('failed to parse Book. Map $map', error: e, stackTrace: st);
      rethrow;
    }
  }
}
