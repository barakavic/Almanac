

class Subgenre {
  final String subgenreid;
  final String subgenrename;
  final String genreid;

  const Subgenre({
    required this.subgenreid,
    required this.subgenrename,
    required this.genreid
    });

  Map<String, dynamic> toMap() => {
    'subgenreid': subgenreid,
    'subgenrename': subgenrename,
    'genreid': genreid
  };

  factory Subgenre.fromMap(Map<String, dynamic> map) => Subgenre(
    subgenreid: map['subgenreid'] ?? '',
    subgenrename: map['subgenrename'] ?? '',
    genreid: map['genreid'] ?? '',
  );

  
}

