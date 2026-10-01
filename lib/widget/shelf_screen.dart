import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/services/book_file_metadata.dart';
import 'package:bookshelf/ui/devices/devices_screen.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/widget/GridView/grid_view.dart';
import 'package:bookshelf/widget/book_actions_sheet.dart';
import 'package:bookshelf/widget/genre_management_screen.dart';
import 'package:bookshelf/widget/import_genre_picker_sheet.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:bookshelf/widget/shelf/currently_reading_section.dart';
import 'package:bookshelf/widget/shelf/genre_books_section.dart';
import 'package:bookshelf/widget/shelf/unsorted_books_section.dart';
import 'package:bookshelf/widget/transfer_progress_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_handler/share_handler.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:uuid/uuid.dart';

class ShelfScreen extends ConsumerStatefulWidget {
  const ShelfScreen({super.key});

  @override
  ConsumerState<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends ConsumerState<ShelfScreen> {
  final Set<String> _processingPaths = {};

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubScription;
  StreamSubscription? _shareSub;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final server = await ref.read(almanacServerProvider.future);
      if (!server.isRunning) {
        await server.start();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Platform.isLinux) return;

      ShareHandlerPlatform.instance.getInitialSharedMedia().then((media) {
        if (media?.attachments?.isNotEmpty == true) {
          final path = media?.attachments?.first?.path;
          if (path != null) _handleIncomingFile(path);
        }
      });

      _shareSub = ShareHandlerPlatform.instance.sharedMediaStream.listen((media) {
        if (media.attachments?.isNotEmpty == true) {
          final path = media.attachments?.first?.path;
          if (path != null) _handleIncomingFile(path);
        }
      });
    });

    _initAppLinks();
  }

  @override
  void dispose() {
    _linkSubScription?.cancel();
    _shareSub?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    if (Platform.isLinux) return;

    _appLinks = AppLinks();

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (e, st) {
      appLogger.e('Failed to get initial app link', error: e, stackTrace: st);
    }

    _linkSubScription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleUri(uri);
      },
      onError: (err, st) {
        appLogger.e('App link stream error', error: err, stackTrace: st);
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    try {
      final file = await toFile(uri.toString());
      await _handleIncomingFile(file.path);
    } catch (e, st) {
      appLogger.e('Failed to handle URI $uri', error: e, stackTrace: st);
    }
  }

  Future<void> _handleIncomingFile(String sharedFilePath) async {
    if (!sharedFilePath.endsWith('.pdf')) return;

    final fileName = sharedFilePath.split('/').last;
    final docsDir = await getApplicationDocumentsDirectory();
    final destinationPath = '${docsDir.path}/$fileName';

    if (_processingPaths.contains(destinationPath)) return;
    _processingPaths.add(destinationPath);

    try {
      final existing = await ref.read(bookRepositoryProvider).getBookByPath(destinationPath);
      if (existing != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PdfReaderScreen(book: existing)),
          );
        }
        return;
      }

      await File(sharedFilePath).copy(destinationPath);
      final metadata = await BookFileMetadata.fromPath(destinationPath);

      final newBook = Book(
        bookid: const Uuid().v4(),
        title: fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
        author: 'Unknown Author',
        filepath: destinationPath,
        spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
        lastpageread: 0,
        totalpages: 0,
        isarchived: false,
        addedat: DateTime.now(),
        sha256: metadata.sha256,
        filesizebytes: metadata.fileSizeBytes,
      );

      await ref.read(bookRepositoryProvider).addBook(newBook);
      ref.invalidate(booksProvider);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfReaderScreen(book: newBook)),
        );
      }
    } finally {
      _processingPaths.remove(destinationPath);
    }
  }

  void _showBookActions(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookActionsSheet(book: book),
    );
  }

  Future<void> _handleBookDrop(Book book, Genre targetGenre) async {
    try {
      await ref.read(bookRepositoryProvider).reassignBook(
            book.bookid,
            targetGenre.genreid,
            null,
          );
      ref.invalidate(booksProvider);
    } catch (e, st) {
      appLogger.e('Failed to move book to genre via drag and drop', error: e, stackTrace: st);
    }
  }

  Future<void> _importBook() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
      );

      if (files != null && files.isNotEmpty) {
        final file = files.single;
        if (file.path != null) {
          final filePath = file.path!;
          final fileName = file.name;

          final metadata = await BookFileMetadata.fromPath(filePath);

          final newBook = Book(
            bookid: const Uuid().v4(),
            title: fileName.replaceAll(RegExp(r'\.(pdf|epub)$', caseSensitive: false), ''),
            author: 'Unknown Author',
            filepath: filePath,
            spinecolor: Colors.primaries[DateTime.now().second % Colors.primaries.length].value,
            lastpageread: 0,
            totalpages: 0,
            isarchived: false,
            addedat: DateTime.now(),
            sha256: metadata.sha256,
            filesizebytes: metadata.fileSizeBytes,
          );

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const ImportGenrePickerSheet(),
          );
        }
      }
    } catch (e, st) {
      appLogger.e('Failed to import book', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import book')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(booksProvider);
    final genreAsync = ref.watch(genreProvider);
    final isGridView = ref.watch(viewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Almanac'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(viewModeProvider.notifier).toggleView();
            },
            icon: Icon(isGridView ? Icons.view_agenda : Icons.grid_view),
          ),
          IconButton(
            icon: const Icon(Icons.phonelink),
            tooltip: 'Paired Devices',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DevicesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GenreManagementScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          const TransferProgressBanner(),
          Expanded(
            child: bookAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error, $err')),
              data: (books) {
                return genreAsync.when(
                  loading: () => const Center(child: SpinKitThreeBounce(color: Colors.blue)),
                  error: (err, stack) => Center(child: Text('Error, $err')),
                  data: (genres) {
                    if (isGridView) {
                      return GridViewScreen(
                        onBookLongPress: _showBookActions,
                        genres: genres,
                      );
                    }
                    return ListView(
                      children: [
                        CurrentlyReadingSection(
                          books: books,
                          genres: genres,
                          onLongPressBook: _showBookActions,
                        ),
                        UnsortedBooksSection(
                          books: books,
                          genres: genres,
                          onLongPressBook: _showBookActions,
                        ),
                        if (genres.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  size: 48,
                                  color: Colors.white30,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No Genres Yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GenreManagementScreen(),
                                    ),
                                  ),
                                  label: const Text(
                                    'Create a Genre',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...genres.map((genre) => GenreBooksSection(
                                genre: genre,
                                genres: genres,
                                books: books,
                                onLongPressBook: _showBookActions,
                                onDropBook: _handleBookDrop,
                              )),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _importBook(),
        tooltip: 'Import Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}
