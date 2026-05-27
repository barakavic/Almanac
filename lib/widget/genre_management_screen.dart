import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class GenreManagementScreen  extends ConsumerStatefulWidget{
  const GenreManagementScreen(
    {super.key}
  );
  @override
  ConsumerState<GenreManagementScreen> createState() => _GenreManagementScreenState();
}

class _GenreManagementScreenState extends ConsumerState<GenreManagementScreen>{
  final genreController = TextEditingController();

  @override
  void dispose(){
    genreController.dispose();

    super.dispose();
  }

  Future<void> _addGenre() async{
    final text = genreController.text.trim();
    final generatedId = const Uuid().v4();
    final defaultColorValue = Colors.teal.value;

    if( text.isEmpty ){
      return;
    }

    final newGenre = Genre(genreid: generatedId, name: text, genrecolor: defaultColorValue);

    await ref.read(genreRepositoryProvider).addGenres(newGenre);

    ref.invalidate(genreProvider);

    genreController.clear();

  }


  @override
  Widget build(BuildContext context) {

    final genreState = ref.watch(genreProvider);

    return Scaffold(

      appBar: AppBar(
        title: Text('Manage Genres'),
      ),
      body:  Column(
        children: [
          Padding(padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TextField(
                controller: genreController,
                
              ),
              
              
              ),

              IconButton(onPressed: _addGenre,
              icon: Icon(Icons.add)
              )
            ],
          ),
          
          ),
          Expanded(child: genreState.when(loading: ()=>const Center(
            child: CircularProgressIndicator(),

          ),
          error: (error, stack) => Center(
            child: Text('Error $error'),

          ),
          data: (genreList){
            if (genreList.isEmpty) {
  return const Center(child: Text('No genres yet. Add one above'),);
            }
  return ListView.builder(itemCount:  genreList.length,
  itemBuilder: (context, index){
    final genre = genreList[index];
    return ListTile(title: Text(genre.name),
    trailing: IconButton(onPressed: () async {
  await ref.read(genreRepositoryProvider).deleteGenre(genre.genreid);
  ref.invalidate(genreProvider);
            }, icon: Icon(Icons.delete)),
    );
  
  
    
  },
  );
}
          
          ),
          
          ),
          
        ],
        
      ),
      

    );
 
  }

  
}