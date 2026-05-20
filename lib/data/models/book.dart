
import 'package:bookshelf/utils/app_logger.dart';

class Book{
  final String bookid;
  final String title;
  final String author;
  final String filepath;
  final int spinecolor;
  final String? genreid;
  final String? subgenreid;
  final int lastpageread;
  final int totalpages;
  final bool isarchived;
  final DateTime addedat;

  const Book(
{ required this.bookid,
  required this.title,
  required this.author,
  required this.filepath,
  required this.spinecolor,
  this.genreid,
  this.subgenreid,
  required this.lastpageread,
  required this.totalpages,
  required this.isarchived,
  required this.addedat}
);

Map<String, dynamic> toMap(){
  
  return {
    'bookid': bookid,
    'title': title,
    'author': author,
    'filepath': filepath,
    'spinecolor': spinecolor,
    'genreid': genreid,
    'subgenreid': subgenreid,
    'lastpageread': lastpageread,
    'totalpages' : totalpages,
    'isarchived': isarchived ? 1: 0,
    'addedat': addedat.toIso8601String(),
  };
  
}

factory Book.fromMap(Map<String, dynamic> map){
  
  try{
  return Book(
    bookid: map['bookid'] ?? '', 
    title: map['title'] ?? '', 
    author: map['author']?? '', 
    filepath: map['filepath']?? '', 
    spinecolor:map['spinecolor']?? 0, 
    genreid:map['genreid'], 
    subgenreid:map['subgenreid'], 
    lastpageread:map['lastpageread']?? 0, 
    totalpages:map['totalpages']?? 0, 
    isarchived:map['isarchived'] == 1, 
    addedat:DateTime.parse(map['addedat']));
}
catch(e,st){
  appLogger.e('failed to parse Book. Map $map', error: e, stackTrace: st);
  rethrow;
}
}
}



