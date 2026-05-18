import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/data/repository/genre_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dbHelperProvider = Provider<DbHelper>((ref)=> DbHelper());
final bookRepositoryProvider = Provider<BookRepository>(
  (ref)=> BookRepository(ref.watch(dbHelperProvider))
);
final booksProvider = FutureProvider<List<Book>>(
  (ref)=>ref.watch(bookRepositoryProvider).getAllBooks(),
);
final genreRepositoryProvider = Provider<GenreRepository>(
  (ref)=> GenreRepository(ref.watch(dbHelperProvider) )
);
final genreProvider = FutureProvider<List<Genre>>((ref) => ref.watch(genreRepositoryProvider).getAllGenres(),);
