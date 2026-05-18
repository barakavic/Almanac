

class Subgenre {
  final String subGenreId;
  final String subGenreName;
  final String genreId;

  const Subgenre({
    required this.subGenreId,
    required this.subGenreName,
    required this.genreId
    });

  Map<String, dynamic> toMap() => {
    'subGenreId': subGenreId,
    'subGenreName': subGenreName,
    'genreId': genreId
  };

  factory Subgenre.fromMap(Map<String, dynamic> map) => Subgenre(
    subGenreId: map['subGenreId'] ?? '',
    subGenreName: map['subGenreName'] ?? '',
    genreId: map['genreId'] ?? '',
  );

  
}

