import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReassignBookSheet extends ConsumerStatefulWidget{
  final Book book;

  
  const ReassignBookSheet({
    required this.book,
    super.key
  });

  @override
  ConsumerState<ReassignBookSheet> createState() => 
  _ReassignBooskSheetState();
  
}

class _ReassignBooskSheetState extends ConsumerState<ReassignBookSheet>{

  String? _selectedGenreId;
  String? _selectedSubgenreId;

  @override
  void initState(){
    super.initState();
    _selectedGenreId = widget.book?.genreid;
    _selectedSubgenreId = widget.book?.subgenreid;

  }

  Future<void> _confirmReassignment() async{
    await ref.read(bookRepositoryProvider).reassignBook(
      widget.book!.bookid, 
      _selectedGenreId, 
      _selectedSubgenreId);


    ref.invalidate(
      booksProvider
    );

    if(_selectedGenreId != null){
      ref.invalidate(
        booksByGenreProvider(_selectedGenreId!)
      );
    }

    if(mounted) Navigator.pop(context);

  
  }

  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genreProvider);
    return Container(
      padding: const EdgeInsets.all(16),

      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reassign "${widget.book?.title}"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ), 
            ),
            const SizedBox(
              height: 16,
            ),

            const Text(
              'Select Genre:'
            ),
            genresAsync.when(
              data: (genres) => Wrap(
                spacing: 8,
                children: [
                  ... genres.map((genre)=> ChoiceChip(
                    label: Text(genre.name),
                     selected: _selectedGenreId == genre.genreid,
                     onSelected: (selected){
                      setState(() {
                        _selectedGenreId = selected ? genre.genreid : null;
                        _selectedSubgenreId = null;
                      });
                     },
                     )).toList()
                ],
              ), error: (err, stack) => Text('Error: $err'), loading: () => const CircularProgressIndicator()),

              const SizedBox(
                height: 16,
              ),
              
              if (_selectedGenreId != null)
              ref.watch(subGenresByGenreProvider(_selectedGenreId!)).when(
                data: (subgenres) => 
                subgenres.isEmpty ? 
                const SizedBox.shrink() : 
                Wrap(
                  spacing: 8,
                  children: subgenres.map((s) => ChoiceChip(
                    label: Text(s.subgenrename), 
                    selected: _selectedSubgenreId == s.subgenreid,
                    onSelected: (selected) => setState(() {
                      _selectedSubgenreId = selected ? s.subgenreid : null;
                    }),
                    )).toList(),

                ), 
                error: (err, stack) => const SizedBox.shrink(), 
                loading:  () => const LinearProgressIndicator(),
                ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _confirmReassignment,
                 child: const Text('Confirm Reassignment')),
              )


          ],
        )
        ),

    );
  }

  
} 