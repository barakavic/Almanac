import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/chapter.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/widget/pdf_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;
  final Genre genre;
  const BookDetailScreen({
    super.key,
    required this.book,
    required this.genre,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double _calculateChapterProgress(Chapter chapter, int lastPageRead) {
    if (lastPageRead >= chapter.chapterendpagenumber) return 1.0;
    if (lastPageRead < chapter.chapterstartpagenumber) return 0.0;

    final totalPages = chapter.chapterendpagenumber - chapter.chapterstartpagenumber + 1;
    final pagesRead = lastPageRead - chapter.chapterstartpagenumber + 1;
    return (pagesRead / totalPages).clamp(0.0, 1.0);
  }

  void _showChapterEditor(List<Chapter> existingChapters) {
    final totalPages = widget.book.totalpages;
    final colorVal = ref.read(genreColorByBookProvider(widget.book.bookid)).valueOrNull;
    final containerColor = colorVal != null ? Color(colorVal) : Theme.of(context).colorScheme.primary;

    final list = <_EditableChapter>[];
    if (existingChapters.isEmpty) {
      list.add(_EditableChapter(
        title: 'Chapter 1',
        startPage: 1,
        endPage: totalPages > 0 ? totalPages : 1,
      ));
    } else {
      for (final c in existingChapters) {
        list.add(_EditableChapter(
          title: c.title,
          startPage: c.chapterstartpagenumber,
          endPage: c.chapterendpagenumber,
        ));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            String? error;

            void validateAndSave() async {
              setState(() {
                error = null;
              });

              final parsed = <_ParsedRange>[];
              for (int i = 0; i < list.length; i++) {
                final item = list[i];
                final title = item.titleController.text.trim();
                final start = int.tryParse(item.startPageController.text) ?? 0;
                final end = int.tryParse(item.endPageController.text) ?? 0;

                if (title.isEmpty) {
                  setState(() {
                    error = 'Chapter ${i + 1} title cannot be empty.';
                  });
                  return;
                }
                if (start < 1 || (totalPages > 0 && start > totalPages)) {
                  setState(() {
                    error = 'Chapter ${i + 1} start page must be between 1 and $totalPages.';
                  });
                  return;
                }
                if (end < 1 || (totalPages > 0 && end > totalPages)) {
                  setState(() {
                    error = 'Chapter ${i + 1} end page must be between 1 and $totalPages.';
                  });
                  return;
                }
                if (start > end) {
                  setState(() {
                    error = 'Chapter ${i + 1} start page cannot be greater than end page.';
                  });
                  return;
                }
                parsed.add(_ParsedRange(title: title, start: start, end: end));
              }

              if (parsed.isNotEmpty) {
                parsed.sort((a, b) => a.start.compareTo(b.start));
                for (int i = 0; i < parsed.length - 1; i++) {
                  if (parsed[i].end >= parsed[i + 1].start) {
                    setState(() {
                      error = 'Chapter ranges must not overlap.';
                    });
                    return;
                  }
                }
                if (totalPages > 0 && parsed.last.end != totalPages) {
                  setState(() {
                    error = 'The last chapter must end on page $totalPages.';
                  });
                  return;
                }
              }

              final repository = ref.read(chaptersRepositoryProvider);
              await repository.deleteChaptersForBook(widget.book.bookid);

              for (int i = 0; i < parsed.length; i++) {
                final p = parsed[i];
                await repository.addChapter(Chapter(
                  chapterid: const Uuid().v4(),
                  bookid: widget.book.bookid,
                  title: p.title,
                  chapterstartpagenumber: p.start,
                  chapterendpagenumber: p.end,
                  chapterorder: i + 1,
                ));
              }

              ref.invalidate(chaptersByBookProvider(widget.book.bookid));
              Navigator.pop(context);
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Chapters',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            final nextStart = list.isEmpty
                                ? 1
                                : (int.tryParse(list.last.endPageController.text) ?? 0) + 1;
                            list.add(_EditableChapter(
                              title: 'Chapter ${list.length + 1}',
                              startPage: nextStart,
                              endPage: totalPages > 0 ? totalPages : nextStart,
                            ));
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: item.titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item.startPageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Start',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item.endPageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'End',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    list.removeAt(index).dispose();
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: validateAndSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: containerColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      for (final item in list) {
        item.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.book.bookid));
    final genreColorAsync = ref.watch(genreColorByBookProvider(widget.book.bookid));
    final containerColor = genreColorAsync.valueOrNull != null
        ? Color(genreColorAsync.valueOrNull!)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final backgroundColor = containerColor.withOpacity(0.10);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: containerColor.withOpacity(0.16),
      ),
      body: Container(
        decoration: BoxDecoration(color: backgroundColor),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: containerColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.book.author,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: widget.book.totalpages == 0
                              ? 0.0
                              : (widget.book.lastpageread / widget.book.totalpages).clamp(0.0, 1.0),
                          minHeight: 8.0,
                          borderRadius: BorderRadius.circular(12),
                          color: Color(widget.book.spinecolor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Page ${widget.book.lastpageread} of ${widget.book.totalpages}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfReaderScreen(book: widget.book),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: containerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Continue Reading'),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Chapters'),
                Tab(text: 'Summary'),
                Tab(text: 'Quiz')
              ],
              indicatorColor: containerColor,
              labelColor: containerColor,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  chaptersAsync.when(
                    data: (chapters) {
                      if (chapters.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('No Chapters Detected for This Book'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showChapterEditor([]),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: containerColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Define Chapters Manually'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${chapters.length} Chapters',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showChapterEditor(chapters),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: chapters.length,
                              itemBuilder: (context, index) {
                                final chapter = chapters[index];
                                final progress = _calculateChapterProgress(
                                  chapter,
                                  widget.book.lastpageread,
                                );
                                final isCompleted = progress >= 1.0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                chapter.title,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            if (isCompleted)
                                              const Icon(Icons.check_circle, color: Colors.green)
                                            else
                                              Text(
                                                'pg. ${chapter.chapterstartpagenumber} - ${chapter.chapterendpagenumber}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          borderRadius: BorderRadius.circular(4),
                                          color: Color(widget.book.spinecolor),
                                          backgroundColor: Color(widget.book.spinecolor).withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    error: (err, stack) => Center(
                      child: Text('Error Loading Chapters, $err'),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('AI summaries coming soon'),
                      ],
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Quiz mode coming soon')
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableChapter {
  final TextEditingController titleController;
  final TextEditingController startPageController;
  final TextEditingController endPageController;

  _EditableChapter({
    required String title,
    required int startPage,
    required int endPage,
  })  : titleController = TextEditingController(text: title),
        startPageController = TextEditingController(text: startPage.toString()),
        endPageController = TextEditingController(text: endPage.toString());

  void dispose() {
    titleController.dispose();
    startPageController.dispose();
    endPageController.dispose();
  }
}

class _ParsedRange {
  final String title;
  final int start;
  final int end;
  _ParsedRange({
    required this.title,
    required this.start,
    required this.end,
  });
}