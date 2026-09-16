# Changelog

## [0.1.1] - 2026-09-16

### Added
- App-start Android permission requests for camera and storage access
- Foreground permission re-check when the user enters QR-scanning or storage-sensitive flows
- Writable-directory validation before a transfer begins
- Safe fallback to an app-owned library directory when a public phone path is blocked
- Dialog-based transfer error messaging instead of a bare snackbar failure
- Request-level permission handling in `AppPermissions` and startup bootstrapping in `main.dart`

### Fixed
- Fixed `PathAccessException` when a transfer target folder was outside the app's writable storage scope
- Fixed the failure path caused by writing into a phone-level shared folder without Android write permission
- Fixed inconsistent permission UX by asking early instead of only when a QR scanner was tapped
- Fixed transfer failure messaging to clearly explain that the app will use a safe fallback directory if needed
- Fixed `Permission.storage` and `Permission.camera` gating for device pairing and transfers

### BUG_REPORT

#### Android transfer path fails when app tries to write into a non-writable shared folder
- Status: Fixed in `0.1.1`
- Severity: High
- Affected area: P2P transfer flow, device detail screen downloads, Android storage handling, QR pairing UX

**Summary**
The app was attempting to save downloaded books into a directory selected by the user, even when Android would not allow writes there. This often happened with a public/shared folder such as a phone-level `Books` directory, which caused a `PathAccessException` and made the transfer appear broken even though the manifest and pairing process were healthy.

**Root cause**
The download flow validated neither the target directory nor Android's storage access before attempting the file write. Additionally, the app did not prompt for camera/storage permissions at startup, so the user could enter QR-scanning or transfer flows before the required permission state was established.

**Reproduction**
1. Select a public or shared folder on the phone as a watched/download location.
2. Start a remote download or transfer.
3. Android denies the write because the folder is outside the app's allowed write scope.
4. The transfer fails with `PathAccessException`.

**Impact**
- Download failures in the transfer flow
- User confusion about why a valid paired device could not download a book
- Android permission prompts appearing too late or not at all

**Fix implemented**
- Validate storage permission before writing to an external path
- Request Android camera and storage permission on app launch
- Re-request when the user accesses permission-gated features
- Fall back to a safe app-owned storage directory if the selected shared folder is blocked
- Surface a clear dialog explaining the transfer issue instead of only a snackbar

**Verification**
- `flutter analyze lib/main.dart lib/services/app_permissions.dart lib/ui/devices/pairing_dialog.dart` returned no issues
- Runtime validation should confirm the permission dialog appears on first launch and the fallback directory is used when a shared folder is blocked

### To Be Done
- ~~Delete a paired device with `onLongPress`~~
- ~~Declare custom watched folders for scanning~~
- ~~Grid View with genre-colored borders and progress bars~~
- ~~Long press reassignment in all shelf sections~~
- ~~Drag and drop book reassignment between genres~~
- ~~Genre picker on book import~~
- ~~Reader settings sheet (Scroll mode, directional, scroll head, dark mode)~~
- ~~Quote sharing from PDF text selection~~
- ~~Device pairing and management with `DevicesScreen`, `DeviceDetailScreen`, and pairing via QR code or manual entry~~
- ~~Local device identity management with unique fingerprint generation~~
- ~~`AlmanacServer` for device communication and pairing workflows~~
- ~~`SyncService` for device synchronization and health checks~~
- ~~Watched folder support with `FolderScanner` for scanning folders and adding discovered books~~
- ~~**View persistence** — Grid/Shelf toggle survives app restarts via `shared_preferences`; loaded before first frame, no flicker~~
- ~~**Chapter extraction** — on first PDF open, bookmark tree parsed into chapter records with correct start/end pages (two-pass); fails silently if no bookmarks present~~
- ~~Updated dependencies and Android permissions for device pairing, networking, and folder scanning support~~

### Fixed V0.1.0
- Duplicate book entries on shared/reopened files
- White GenreDivider rendering bug
- Debounced DB writes on page change
- `PdfDestination.pageIndex` undefined getter — replaced with correct `document.pages.indexOf(dest.page)` lookup
- `rethrow` in chapter extraction catch block replaced with silent log
- `fts5` is disabled in the lightweight sqlite therefore reverted to fts4 in db_helper
