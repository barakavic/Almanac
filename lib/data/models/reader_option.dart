import 'package:flutter/material.dart';

class ReaderOption {
  final String id;
  final String displayname;
  final IconData icon;
  final List<String> platforms;
  final String? androidPackage;
  final String? linuxExecutable;
  final List<String>? linuxFallbacks;
  final String? windowsExecutable;

  const ReaderOption({
    required this.id,
    required this.displayname,
    required this.icon,
    required this.platforms,
    this.androidPackage,
    this.linuxExecutable,
    this.linuxFallbacks,
    this.windowsExecutable

  });

  


  static const List<ReaderOption> all = [
    ReaderOption(id: 'almanac', 
    displayname: 'Almanac', 
    icon: Icons.menu_book, 
    platforms: ['android', 'linux', 'windows'],
    ),
    ReaderOption(id: 'adobe', 
    displayname: 'Adobe Acrobat', 
    icon: Icons.picture_as_pdf, 
    platforms: ['android', 'windows'],
    androidPackage: 'com.adobe.reader',
    linuxExecutable: null,
    linuxFallbacks: null,
    windowsExecutable: 'Acrobat.exe'
    ),
    ReaderOption(id: 'okular', 
    displayname: 'Okular', 
    icon: Icons.chrome_reader_mode, 
    platforms: ['linux'],
    androidPackage: null,
    linuxExecutable: 'okular',
    linuxFallbacks: null,
    windowsExecutable: null
    ),
    ReaderOption(id: 'wps',
     displayname: 'WPS Office', 
     icon: Icons.description, 
     platforms: ['android', 'linux', 'windows'],
     androidPackage: 'cn.wps.moffice_eng',
     linuxExecutable: 'wpsoffice',
     linuxFallbacks: ['wps','et', 'wpp'],
     windowsExecutable: 'wps.exe'
     )

  ];
  

}

