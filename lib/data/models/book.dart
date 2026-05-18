
class Book{
  final String bookId;
  final String title;
  final String author;
  final String filepath;
  final int spineColor;
  final String? genreId;
  final String? subgenreId;
  final int lastPageRead;
  final int totalPages;
  final bool isArchived;
  final DateTime addedAt;

  const Book(
{ required this.bookId,
  required this.title,
  required this.author,
  required this.filepath,
  required this.spineColor,
  this.genreId,
  this.subgenreId,
  required this.lastPageRead,
  required this.totalPages,
  required this.isArchived,
  required this.addedAt}
);

Map<String, dynamic> toMap(){
  return {
    'bookId': bookId,
    'title': title,
    'author': author,
    'filepath': filepath,
    'spineColor': spineColor,
    'genreId': genreId,
    'subgenreId': subgenreId,
    'lastPageRead': lastPageRead,
    'totalPages' : totalPages,
    'isArchived': isArchived ? 1: 0,
    'addedAt': addedAt.toIso8601String(),
  };
}

factory Book.fromMap(Map<String, dynamic> map){
  return Book(
    bookId: map['bookid'] ?? '', 
    title: map['title'] ?? '', 
    author: map['author']?? '', 
    filepath: map['filepath']?? '', 
    spineColor:map['spinecolor']?? 0, 
    genreId:map['genreid'], 
    subgenreId:map['subgenreid'], 
    lastPageRead:map['lastpageread']?? 0, 
    totalPages:map['totalpages']?? 0, 
    isArchived:map['isarchived'] == 1, 
    addedAt:DateTime.parse(map['addedat']));
}

}



