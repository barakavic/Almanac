[Unreleased]
- Chapter Extraction from bookmarks and ordering

### To Be Done
- Delete a paired device with `onLongPress`
- Declare watched folders for folder scanning

### Added
- Grid View with genre-colored borders and progress bars
- Long press reassignment in all shelf sections
- Drag and drop book reassignment between genres
- Genre picker on book import
- Reader settings sheet (Scroll mode, directional, scroll head, dark mode)
- Quote sharing from PDF text selection
- Device pairing and management with `DevicesScreen`, `DeviceDetailScreen`, and pairing via QR code or manual entry
- Local device identity management with unique fingerprint generation
- `AlmanacServer` for device communication and pairing workflows
- `SyncService` for device synchronization and health checks
- Watched folder support with `FolderScanner` for scanning folders and adding discovered books
- **View persistence** — Grid/Shelf toggle survives app restarts via `shared_preferences`; loaded before first frame, no flicker
- **Chapter extraction** — on first PDF open, bookmark tree parsed into chapter records with correct start/end pages (two-pass); fails silently if no bookmarks present
- Updated dependencies and Android permissions for device pairing, networking, and folder scanning support

### Fixed
- Duplicate book entries on shared/reopened files
- White GenreDivider rendering bug
- Debounced DB writes on page change
- `PdfDestination.pageIndex` undefined getter — replaced with correct `document.pages.indexOf(dest.page)` lookup
- `rethrow` in chapter extraction catch block replaced with silent log
- `fts5` is disabled in the lightweight sqlite therefore reverted to fts4 in db_helper
