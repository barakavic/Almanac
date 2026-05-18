
class Genre {
  final String genreId;
  final String name;
  final int genreColor;

  const Genre({ 
    required this.genreId,
    required this.name,
    required this.genreColor


  });
Map<String, dynamic> toMap() => {
  'genreId': genreId,
  'name': name,
  'genreColor': genreColor,
};
factory Genre.fromMap(Map<String, dynamic> map) => Genre( 
genreId: map['genreId'] ?? '', 
name: map['name'] ?? '', 
genreColor: map['genreColor'] ?? 0
);
}