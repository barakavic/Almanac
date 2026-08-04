import 'package:bookshelf/data/database/db_helper.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/chapter.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/models/subgenre.dart';
import 'package:bookshelf/data/repository/book_repository.dart';
import 'package:bookshelf/data/repository/chapter_repository.dart';
import 'package:bookshelf/data/repository/genre_repository.dart';
import 'package:bookshelf/data/repository/subgenre_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ViewModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('is_grid_view') ?? false;
  }

  void toggleView() {
    state = !state;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('is_grid_view', state);
  }
}

final viewModeProvider = NotifierProvider<ViewModeNotifier, bool>(() {
  return ViewModeNotifier();
});

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
final genreProvider = 
FutureProvider<List<Genre>>(
  (ref) => ref.watch(genreRepositoryProvider).getAllGenres(),
  );


final subGenreRepositoryProvider = Provider<SubgenreRepository>(
  (ref) => SubgenreRepository(ref.watch(dbHelperProvider)),);

final subGenresByGenreProvider = FutureProvider.family<List<Subgenre>, String>((ref, genreid){
  return ref.watch(subGenreRepositoryProvider).getSubgenreByGenre(genreid);

});

final booksByGenreProvider = 
FutureProvider.family<List<Book>, String>(
  (ref, genreid){
  return ref.watch(
    bookRepositoryProvider).
    getBooksByGenre(genreid);
});

final chaptersRepositoryProvider = 
Provider<ChapterRepository>(
  (ref) => ChapterRepository(
    ref.watch(dbHelperProvider)
    )
);

final chaptersByBookProvider = 
  FutureProvider.family<List<Chapter>, String>(
    (ref, bookid){
      return ref.watch(
        chaptersRepositoryProvider
        ).getChaptersForBook(bookid);
    }
  );

final genreColorByBookProvider = FutureProvider.family<int?, String>((ref, bookid){
  return ref.watch(bookRepositoryProvider).getGenreColorByBook(bookid);
});
