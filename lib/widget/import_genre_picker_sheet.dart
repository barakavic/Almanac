import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportGenrePickerSheet extends ConsumerStatefulWidget{
  const ImportGenrePickerSheet({
    super.key

  });
  @override
  ConsumerState<ImportGenrePickerSheet> createState() => _ImportGenrePickerSheetState();
}

class _ImportGenrePickerSheetState extends ConsumerState<ImportGenrePickerSheet> {
  
  String? _selectedGenreId;
  String? _selectedSubgenreId;

  @override
  Widget build(BuildContext context) {
    final genreAsync = ref.watch(genreProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Genre to Imported Book',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text('Select Genre'),
            const SizedBox( height: 8,),
            genreAsync.when(data: (genres)=> Wrap(
              spacing: 8,
              children: genres.map(
                (genre) => ChoiceChip(
                  label: Text(genre.name), 
                  selected:
                   _selectedGenreId == genre.genreid, 
                  onSelected: (selected) {
                    setState(() {
                      _selectedGenreId = selected ? genre.genreid : null;
                      _selectedSubgenreId = null;
                    });
                
              },)).toList()
           
            ), 
            error: (err, stack) => Text(
              'Error, $err'), 
              loading: () => CircularProgressIndicator(),
              ),
              const SizedBox(
                height: 16,
              ),

              if (_selectedSubgenreId != null) ...[
                const Text(
                  'Select Subgenre (Optional):'
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  ref.watch(
                    subGenresByGenreProvider(_selectedSubgenreId!)).when(
                      data: (
                        subgenres) => subgenres.isEmpty ? 
                        const Text(
                          'No Subgenres Available', 
                          style: TextStyle(
                            fontStyle: FontStyle.italic),
                            ) : 
                            Wrap(
                              spacing: 8,
                              children: 
                                subgenres.map((s) => ChoiceChip(label: Text(s.subgenrename), 
                                selected: _selectedSubgenreId == s.subgenreid,
                                onSelected: (selected) {
                                  _selectedSubgenreId = selected ? s.subgenreid : null;

                                  
                                },)).toList()
                              ,
                            ), 
                            error: 
                            (error, stack) => SizedBox.shrink() , 
                            loading: ()=> CircularProgressIndicator(

                            ),
                            ),
              ],

              const SizedBox(
                height: 24,
              ),
              Row(
                children: [
                  Expanded(child: 
                  TextButton(onPressed: (){
                    Navigator.pop(context,
                    
                    {
                      'genreid' : null,
                      'subgenreid': null
                    }
                    );
                    
                  }, 
                  child: const Text('Skip'))
                  ),
                  const SizedBox(width: 16,),
                  Expanded(child: 
                  ElevatedButton(onPressed: (){
                    Navigator.pop(context, {
                      'genreid': _selectedGenreId,
                      'subgenreid': _selectedSubgenreId,
                    });
                  }, child: const Text('Confirm')
                  )
                  )

                ],
              )

            
          ],

      )),

    );
  }
}