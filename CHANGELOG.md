# Changelog

## [0.1.2] - 2026-10-04

### Added
- Book Details now checks local PDF page count and indexes chapters when opened, so users do not have to enter the in-app reader to trigger extraction.
- Chapter scanning status and a manual rescan action are available from Book Details. Rescanning asks for confirmation because a successful scan replaces the current chapter list, including manually created chapters.
- TOC discovery recognizes `Table of Contents`, `Brief Contents`, and common dot, dash, bullet, and spacing variations. It can read entries across consecutive TOC pages and scans up to 100 initial pages for a TOC, then up to 20 pages for its entries.
- Added consecutive duplicate-heading normalization to the regex fallback so repeated running headers such as `Chapter 8` do not become a separate one-page chapter on every page.
- Added generated-PDF regression tests for file and open-document crawling, multi-page contents, long prefaces, page ranges, and repeated chapter headers.

### Fixed
- Persisted PDF total-page counts discovered during Book Details scanning; returning from an external PDF reader can now show the document's actual page count once its Details screen inspects it.
- Corrected incomplete chapter lists caused by parsing only the first TOC page.
- Prevented generic repeated PDF headers from inflating the chapter list when the regex-based fallback is used.
- Added an explicit rescan path for books whose chapter list was already stored, while keeping existing records unless the user confirms replacement.

### Challenges and limitations
- PDF text extraction does not always preserve the visual layout of TOC leaders and columns. Parsing accepts several common text forms, but unusual line wrapping, column ordering, or formatting may still need a book-specific adjustment.
- TOC discovery is bounded to the first 100 PDF pages, and continuation parsing is bounded to 20 pages. A contents section beyond those limits may not be fully indexed.
- Image-only or scanned TOCs are not recognized by text extraction; OCR would be needed to support them.
- The regex fallback can still mistake non-consecutive chapter-like text for headings. Consecutive normalization addresses repeated running headers, but cannot reliably infer semantic chapter structure from every book layout.
- A confirmed rescan replaces all existing chapters for that book. Review the confirmation before proceeding if the list contains manually defined chapters.
- Android verification had a separate environment delay: Gradle built the APK in about 67 seconds, but installation over wireless ADB took about 514 seconds before ADB exited with code `-2`. This was an install/transport issue, not a chapter-scanning build failure; USB or a stable ADB connection is recommended for device verification.

### Verification
- `flutter test test/toc_crawler_test.dart test/regex_extractor_test.dart` passed.
- Targeted Flutter analysis found no errors in the chapter crawler, extractor, persistence, and details-screen changes; existing informational lints remain.

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
