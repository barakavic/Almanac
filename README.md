# ALMANAC

Almanac is an offline, cross-platform PDF reader and personal library manager built with Flutter. Import books from your file manager or directly from other apps, organize them into genres and subgenres, track reading progress per book, and share highlighted quotes — all without an internet connection.

---

## FEATURES

- **Import books** via the in-app file picker or directly from any PDF-capable app using Android's "Open With" intent
- **Organize** books into custom genres and subgenres
- **Drag and drop** books across genre shelves directly from the main shelf
- **Assign genre on import** — pick a genre the moment you add a book
- **Track reading progress** — the app remembers which page you left off on
- **Currently Reading shelf** — books you have opened appear in a dedicated row
- **Dark mode reader** — invert PDF colors for low-light reading with one tap
- **Share quotes** — highlight text in the reader and export it as a shareable quote card image
- **Offline first** — no account, no internet, no telemetry. Everything lives on your device

---

## TECH STACK

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | SQLite via `sqflite` |
| PDF Rendering | Syncfusion Flutter PDF Viewer |
| File Handling | `file_picker`, `uri_to_file`, `path_provider` |
| Intent Handling | `app_links`, `share_handler` |
| Sharing | `share_plus`, `screenshot` |
| Logging | `logger` |

---

## ARCHITECTURE

```
lib/
├── main.dart                          # App entry point, image cache configuration
├── theme/                             # App-wide ThemeData (dark mode)
├── utils/                             # Logger and shared utilities
├── data/
│   ├── models/                        # Book, Genre, Subgenre data models
│   ├── repository/                    # SQLite repository layer
│   ├── database/                      # Database initialization and migrations
│   └── providers.dart                 # Riverpod providers
└── widget/
    ├── shelf_screen.dart              # Root shelf screen (intent handling, FAB import)
    ├── pdf_reader_screen.dart         # PDF viewer with progress saving and quote sharing
    ├── shelf/                         # Modular shelf section widgets
    │   ├── currently_reading_section.dart
    │   ├── unsorted_books_section.dart
    │   └── genre_books_section.dart
    ├── book_spine.dart                # Individual book spine UI component
    ├── book_actions_sheet.dart        # Unified long-press action sheet
    ├── import_genre_picker_sheet.dart # Genre picker shown on book import
    ├── reassign_book_sheet.dart       # Genre reassignment bottom sheet
    ├── genre_management_screen.dart   # Create and manage genres
    └── PdfReaderComponent/            # Quote card widget for sharing
```

---

## GETTING STARTED

### Prerequisites
- Flutter SDK `^3.9.2`
- Android device or emulator (API 21+)

### Run locally

```bash
git clone <repo-url>
cd bookshelf
flutter pub get
flutter run
```

### Open With (Android)
After installing the app, open any PDF from your file manager and select **Almanac** from the "Open With" list. The book will be imported and opened automatically.

---

## SCREENSHOTS

_Coming soon_
