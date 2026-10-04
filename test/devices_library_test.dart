import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/genre.dart';
import 'package:bookshelf/widget/GridView/grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleBook = Book(
    bookid: 'test-1',
    title: 'The Pragmatic Programmer',
    author: 'Andy Hunt & Dave Thomas',
    spinecolor: Colors.blue.value,
    lastpageread: 50,
    totalpages: 350,
    isarchived: false,
    addedat: DateTime.now(),
  );

  final sampleGenre = Genre(
    genreid: 'genre-tech',
    name: 'Technology',
    genrecolor: Colors.purple.value,
  );

  testWidgets('BookGridCard renders single border when deviceColor is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookGridCard(
            book: sampleBook,
            genre: sampleGenre,
            deviceColor: null,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
    expect(find.text('Andy Hunt & Dave Thomas'), findsOneWidget);
    expect(find.text('50/350 pages'), findsOneWidget);
  });

  testWidgets('BookGridCard renders layered border when deviceColor is provided', (tester) async {
    const deviceColor = Colors.yellow;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookGridCard(
            book: sampleBook,
            genre: sampleGenre,
            deviceColor: deviceColor,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );

    expect(find.text('The Pragmatic Programmer'), findsOneWidget);

    // Verify outer container decoration contains deviceColor border
    final containers = tester.widgetList<Container>(find.byType(Container));
    final hasDeviceBorder = containers.any((c) {
      final decoration = c.decoration;
      if (decoration is BoxDecoration && decoration.border != null) {
        final top = decoration.border!.top;
        return top.color == deviceColor && top.width == 2.5;
      }
      return false;
    });

    expect(hasDeviceBorder, isTrue);
  });

  test('Book copyWith updates deviceid, isremote, and remotedeviceid', () {
    final updated = sampleBook.copyWith(
      deviceid: 'remote-dev-1',
      isremote: true,
      remotedeviceid: 'remote-dev-1',
    );

    expect(updated.deviceid, 'remote-dev-1');
    expect(updated.isremote, isTrue);
    expect(updated.remotedeviceid, 'remote-dev-1');
    expect(updated.title, sampleBook.title);
    expect(updated.bookid, sampleBook.bookid);
  });
}
