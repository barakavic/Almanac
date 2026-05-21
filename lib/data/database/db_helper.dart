import 'package:bookshelf/utils/app_logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _db;

  Future<Database> get database async{
    _db??= await _initDB();
    return _db!;
  }
  Future<Database> _initDB() async{
    try{
    final dir= await getApplicationDocumentsDirectory();
    final path= join(dir.path, 'bookshelf.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
    }
    catch(e, st){
      appLogger.e('Failed to open database', error: e, stackTrace: st);
      rethrow;
    }
}
  Future<void> _onCreate(Database db, int version) async{
    try{
    await db.execute("CREATE TABLE books( bookid TEXT PRIMARY KEY, title TEXT, author TEXT, filepath TEXT, spinecolor INTEGER, genreid TEXT, subgenreid TEXT, lastpageread INTEGER, totalpages INTEGER, isarchived INTEGER, addedat TEXT, aisummaryenabled INTEGER DEFAULT 1, quizmode INTEGER DEFAULT 1, FOREIGN KEY(genreid) REFERENCES genre(genreid) ON DELETE SET NULL, FOREIGN KEY(subgenreid) REFERENCES subgenre(subgenreid) ON DELETE SET NULL);");

    await db.execute("CREATE TABLE genre( genreid TEXT PRIMARY KEY, name TEXT, genreColor INTEGER); ");

    await db.execute("CREATE TABLE subgenre( subgenreid TEXT PRIMARY KEY, subgenrename TEXT, genreId TEXT, FOREIGN KEY (genreid) REFERENCES genre(genreid) ON DELETE SET NULL );");

    await db.execute("CREATE TABLE annotations(annotationid TEXT PRIMARY KEY, bookid TEXT, pagenumber INTEGER, highlightedtext TEXT, note TEXT, tag TEXT, createdat TEXT, FOREIGN KEY(bookid) references books(bookid) ON DELETE CASCADE);");

    await db.execute('''CREATE TABLE summaries(
  summaryid TEXT PRIMARY KEY,
  bookid TEXT,
  frompage INTEGER,
  topage INTEGER,
  usersummary TEXT,
  aisummary TEXT,
  createdat TEXT,
  FOREIGN KEY(bookid) REFERENCES books(bookid) ON DELETE CASCADE
  );''');

    await db.execute('''CREATE TABLE wishlist(
  wishlistid TEXT PRIMARY KEY,
  coverpath TEXT,
  title TEXT,
  addedat TEXT
  );''');

  
    }
    catch(e, st){
      appLogger.e('Failed to create database', error: e, stackTrace: st);
      rethrow;
    }

  }
}