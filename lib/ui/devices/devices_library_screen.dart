import 'dart:async';
import 'dart:convert';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/models/pending_transfer.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:bookshelf/utils/device_identity.dart';
import 'package:bookshelf/widget/GridView/grid_view.dart';
import 'package:bookshelf/widget/book_actions_sheet.dart';
import 'package:bookshelf/widget/reader_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class DevicesLibraryScreen extends ConsumerStatefulWidget {
  const DevicesLibraryScreen({super.key});

  @override
  ConsumerState<DevicesLibraryScreen> createState() =>
      _DevicesLibraryScreenState();
}

class _DevicesLibraryScreenState extends ConsumerState<DevicesLibraryScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedDeviceId; // null = all devices
  List<Book> _allBooks = [];
  final Map<String, bool> _deviceOnline = {};
  List<Device> _pairedDevices = [];
  String? _localDeviceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllBooks();
    });
  }

  Future<void> _loadAllBooks() async {
    setState(() => _isLoading = true);

    try {
      _localDeviceId = await getDeviceFingerprint();

      final localBooks = (ref.read(booksProvider).valueOrNull ?? []).map((b) {
        if (b.deviceid == null) {
          return b.copyWith(deviceid: _localDeviceId);
        }
        return b;
      }).toList();

      final deviceRepo = ref.read(deviceRepositoryProvider);
      _pairedDevices = await deviceRepo.getAllDevices();

      final List<Book> remoteBooks = [];

      for (final device in _pairedDevices) {
        final deviceId = device.deviceid;
        if (deviceId == null || deviceId == _localDeviceId) continue;

        final host =
            (device.mdnshostname != null && device.mdnshostname!.isNotEmpty)
            ? device.mdnshostname!
            : device.ipaddress;

        bool isAlive = false;

        // Try pinging via host
        try {
          final pingRes = await http
              .get(Uri.parse('http://$host:${device.port}/ping'))
              .timeout(const Duration(milliseconds: 1500));
          isAlive = pingRes.statusCode == 200;
        } catch (_) {
          // Fallback to IP address if host differed
          if (device.ipaddress.isNotEmpty && host != device.ipaddress) {
            try {
              final pingRes = await http
                  .get(
                    Uri.parse('http://${device.ipaddress}:${device.port}/ping'),
                  )
                  .timeout(const Duration(milliseconds: 1500));
              isAlive = pingRes.statusCode == 200;
            } catch (_) {}
          }
        }

        _deviceOnline[deviceId] = isAlive;

        if (isAlive) {
          final pairingCode = device.pairingcode;
          if (pairingCode == null || pairingCode.isEmpty) {
            appLogger.w(
              'Cannot fetch books from ${device.devicename}: pairing token is missing',
            );
            continue;
          }

          try {
            final activeHost = (isAlive && device.ipaddress.isNotEmpty)
                ? device.ipaddress
                : host;
            final booksRes = await http
                .get(
                  Uri.parse('http://$activeHost:${device.port}/books'),
                  headers: {'x-almanac-token': pairingCode},
                )
                .timeout(const Duration(seconds: 5));

            if (booksRes.statusCode == 200) {
              final decoded = jsonDecode(booksRes.body) as List;
              for (final item in decoded) {
                final book = Book.fromMap(item as Map<String, dynamic>);
                remoteBooks.add(
                  book.copyWith(
                    deviceid: deviceId,
                    isremote: true,
                    remotedeviceid: deviceId,
                  ),
                );
              }
            }
          } catch (e, st) {
            appLogger.w(
              'Failed to fetch books from ${device.devicename}',
              error: e,
              stackTrace: st,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _allBooks = [...localBooks, ...remoteBooks];
          _isLoading = false;
        });
      }
    } catch (e, st) {
      appLogger.e(
        'Failed to load multi-device library',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _deviceColor(String? deviceid) {
    if (deviceid == null || deviceid == _localDeviceId) {
      return Colors.green;
    }

    final device = _pairedDevices
        .where((d) => d.deviceid == deviceid)
        .firstOrNull;
    if (device == null) return Colors.grey;

    switch (device.platform?.toLowerCase()) {
      case 'linux':
        return Colors.yellow;
      case 'windows':
        return Colors.red;
      case 'android':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _deviceIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'linux':
        return Icons.terminal;
      case 'windows':
        return Icons.desktop_windows;
      case 'android':
        return Icons.phone_android;
      case 'macos':
      case 'ios':
        return Icons.apple;
      default:
        return Icons.devices;
    }
  }

  void _showOfflineDialog(Book book, Device device) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${device.devicename ?? "Device"} is offline'),
        content: Text(
          '"${book.title}" is on ${device.devicename ?? "Device"} '
          'which is currently offline.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final transferRepo = ref.read(pendingTransferRepositoryProvider);
              final localId = _localDeviceId ?? await getDeviceFingerprint();

              final pending = PendingTransfer(
                transferid: const Uuid().v4(),
                bookid: book.bookid,
                sourcedeviceid: device.deviceid ?? '',
                targetdeviceid: localId,
                filechecksum: book.sha256 ?? '',
                filesizebytes: book.filesizebytes ?? 0,
                transfertype: TransferType.direct,
                currenthop: 1,
                priority: 1,
                status: TransferStatus.queued,
                retrycount: 0,
                lastattemptedat: DateTime.now(),
                createdat: DateTime.now(),
              );

              await transferRepo.enqueueTransfer(pending);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Queued "${book.title}" for download when online.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Download when online'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showRemoteBookSheet(Book book, Device device) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  _deviceIcon(device.platform),
                  color: _deviceColor(device.deviceid),
                  size: 32,
                ),
                title: Text(
                  book.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Available on ${device.devicename ?? "Paired Device"} (${device.platform ?? ""})',
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Download to this device'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final transferService = ref.read(transferServiceProvider);
                  final success = await transferService.downloadBook(
                    remoteDevice: device,
                    remoteBook: book,
                  );

                  if (mounted) {
                    ref.invalidate(booksProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Downloaded "${book.title}" successfully!'
                              : 'Download failed for "${book.title}".',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    _loadAllBooks();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBookTap(Book book) {
    if (book.deviceid == null || book.deviceid == _localDeviceId) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ReaderPickerSheet(book: book),
      );
      return;
    }

    final device = _pairedDevices
        .where((d) => d.deviceid == book.deviceid)
        .firstOrNull;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not found in paired devices.')),
      );
      return;
    }

    final isOnline = _deviceOnline[book.deviceid] == true;
    if (isOnline) {
      _showRemoteBookSheet(book, device);
    } else {
      _showOfflineDialog(book, device);
    }
  }

  void _showBookActions(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookActionsSheet(book: book),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genreAsync = ref.watch(genreProvider);
    final genreList = genreAsync.valueOrNull ?? [];
    final genreMap = {for (final g in genreList) g.genreid: g};

    final filteredBooks = _allBooks.where((book) {
      // Filter by selected device chip
      if (_selectedDeviceId != null) {
        if (_selectedDeviceId == _localDeviceId) {
          if (book.deviceid != null && book.deviceid != _localDeviceId) {
            return false;
          }
        } else if (book.deviceid != _selectedDeviceId) {
          return false;
        }
      }

      // Filter by search query (title, author, or devicename)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = book.title.toLowerCase().contains(query);
        final authorMatch = book.author.toLowerCase().contains(query);
        final device = _pairedDevices
            .where((d) => d.deviceid == book.deviceid)
            .firstOrNull;
        final deviceMatch =
            device?.devicename?.toLowerCase().contains(query) ?? false;
        return titleMatch || authorMatch || deviceMatch;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search books or devices...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh library',
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllBooks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Device Filter Chips Bar
          _buildDeviceFilterBar(),
          const Divider(height: 1),

          // Main Grid Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBooks.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No books match "$_searchQuery"'
                          : 'No books found on selected device(s)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookGridCard(
                        book: book,
                        genre: genreMap[book.genreid],
                        deviceColor: _deviceColor(book.deviceid),
                        onTap: () => _handleBookTap(book),
                        onLongPress: () => _showBookActions(book),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // "All Devices" chip
          ChoiceChip(
            label: const Text('All Devices'),
            selected: _selectedDeviceId == null,
            onSelected: (selected) {
              if (selected) setState(() => _selectedDeviceId = null);
            },
          ),
          const SizedBox(width: 8),

          // "This Device" chip
          ChoiceChip(
            avatar: const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 6,
            ),
            label: const Text('This Device'),
            selected: _selectedDeviceId == _localDeviceId,
            onSelected: (selected) {
              setState(() {
                _selectedDeviceId = selected ? _localDeviceId : null;
              });
            },
          ),
          const SizedBox(width: 8),

          // Chips for each remote paired device
          ..._pairedDevices.map((device) {
            final isOnline = _deviceOnline[device.deviceid] == true;
            final devColor = _deviceColor(device.deviceid);
            final isSelected = _selectedDeviceId == device.deviceid;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  _deviceIcon(device.platform),
                  size: 16,
                  color: isOnline ? devColor : Colors.grey,
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(device.devicename ?? 'Device'),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedDeviceId = selected ? device.deviceid : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
