[Unreleased]

### Added
- 90-second TOTP code rotation for device pairing with live countdown timer and QR/PIN mode toggle button in `PairingDialog`
- Dynamic LAN IP detection and QR JSON payload parsing (auto-extracting host IP and Port from camera scans)
- Platform-specific visual identity in `DevicesScreen` (Ubuntu Orange, Android Green, Windows Blue, Apple Slate)
- Background device health check runner (60-second periodic ping, marking offline after 3 consecutive failures)
- 2-sublayer folder hierarchy inspection modal in `DeviceDetailScreen`
- Replaced unmaintained `disk_space` dependency with AGP 8.9+ compliant `disk_space_plus: ^0.2.2`

### Fixed
- Fixed `FormatException: Invalid port` during camera QR scans by adding string parsing for JSON payloads in `SyncService.pairWithDevice`
- Fixed `SyncService` missing parameter constructor calls across UI screens
- Fixed `WatchedFolder` mock type mismatches (`bool` to `int` flags and string to `DateTime` timestamps)
- Fixed database schema migrations to be defensive and idempotent using `CREATE TABLE IF NOT EXISTS` and consolidated `_onUpgrade`

### To Be Done
- Delete a paired device with `onLongPress`
- Declare custom watched folders for scanning
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
