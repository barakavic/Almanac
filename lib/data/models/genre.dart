
class Genre {
  final String genreid;
  final String name;
  final int genrecolor;

  const Genre({ 
    required this.genreid,
    required this.name,
    required this.genrecolor


  });
  Map<String, dynamic> toMap() => {
    'genreid': genreid,
    'name': name,
    'genreColor': genrecolor,
  };

  factory Genre.fromMap(Map<String, dynamic> map) => Genre( 
    genreid: map['genreid'] ?? '', 
    name: map['name'] ?? '', 
    genrecolor: map['genreColor'] ?? map['genrecolor'] ?? 0
  );
}