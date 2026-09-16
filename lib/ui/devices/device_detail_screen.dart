import 'dart:io';

import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/services/transfer_service.dart';
import 'package:bookshelf/widget/transfer_progress_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  List<Book> _remoteBooks = [];
  bool _isLoadingManifest = false;
  String? _manifestError;

  Future<void> _fetchManifest() async {
    setState(() {
      _isLoadingManifest = true;
      _manifestError = null;
    });

    try {
      final transferService = ref.read(transferServiceProvider);
      final manifest = await transferService.fetchRemoteManifest(widget.device);

      setState(() {
        _remoteBooks = manifest;
        _isLoadingManifest = false;
        if (manifest.isEmpty) {
          _manifestError = 'No books found or device unreachable.';
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingManifest = false;
        _manifestError = 'Failed to fetch manifest: $e';
      });
    }
  }

  Future<void> _showTransferProblemDialog(String title, String message) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSingleBook(Book book) async {
    try {
      final transferService = ref.read(transferServiceProvider);
      final success = await transferService.downloadBook(
        remoteDevice: widget.device,
        remoteBook: book,
      );

      if (mounted) {
        if (success) {
          ref.invalidate(booksProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded "${book.title}" successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed for "${book.title}".'), backgroundColor: Colors.red),
          );
        }
      }
    } on NoWatchedFolderException catch (e) {
      if (mounted) {
        await _showTransferProblemDialog(
          'No writable library folder',
          e.message,
        );
      }
    } on PathAccessException catch (_) {
      if (mounted) {
        await _showTransferProblemDialog(
          'Storage permission required',
          'This folder is not writable from this app. The download will use a safe app storage folder instead.',
        );
      }
    } catch (e) {
      if (mounted) {
        await _showTransferProblemDialog(
          'Transfer failed',
          'The download could not complete.\n\nDetails: $e',
        );
      }
    }
  }

  Future<void> _downloadAllBooks() async {
    if (_remoteBooks.isEmpty) return;

    try {
      final transferService = ref.read(transferServiceProvider);
      final success = await transferService.downloadBatch(
        remoteDevice: widget.device,
        books: _remoteBooks,
      );

      if (mounted) {
        ref.invalidate(booksProvider);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All books downloaded successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Some downloads failed.'), backgroundColor: Colors.red),
          );
        }
      }
    } on NoWatchedFolderException catch (e) {
      if (mounted) {
        await _showTransferProblemDialog(
          'No writable library folder',
          e.message,
        );
      }
    } on PathAccessException catch (_) {
      if (mounted) {
        await _showTransferProblemDialog(
          'Storage permission required',
          'This folder is not writable from this app. The download will use a safe app storage folder instead.',
        );
      }
    } catch (e) {
      if (mounted) {
        await _showTransferProblemDialog(
          'Transfer failed',
          'The download could not complete.\n\nDetails: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.device;

    return Scaffold(
      appBar: AppBar(
        title: Text(dev.devicename ?? 'Device Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Fetch Remote Manifest',
            onPressed: _isLoadingManifest ? null : _fetchManifest,
          ),
        ],
      ),
      body: Column(
        children: [
          const TransferProgressBanner(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  child: Icon(Icons.devices, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dev.devicename ?? 'Device',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Platform: ${dev.platform?.toUpperCase() ?? "UNKNOWN"} • IP: ${dev.ipaddress}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                      Text(
                        'Device ID: ${dev.deviceid ?? "Unspecified"}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_remoteBooks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _downloadAllBooks,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download All'),
                ),
              ),
            ),
          Expanded(
            child: _isLoadingManifest
                ? const Center(child: CircularProgressIndicator())
                : _manifestError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_manifestError!, style: TextStyle(color: Colors.grey.shade400)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _fetchManifest,
                              icon: const Icon(Icons.sync),
                              label: const Text('Fetch Remote Manifest'),
                            ),
                          ],
                        ),
                      )
                    : _remoteBooks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_download, size: 48, color: Colors.grey.shade600),
                                const SizedBox(height: 12),
                                Text(
                                  'Tap below to inspect remote books on this device',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _fetchManifest,
                                  icon: const Icon(Icons.sync),
                                  label: const Text('Fetch Remote Manifest'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _remoteBooks.length,
                            itemBuilder: (context, index) {
                              final book = _remoteBooks[index];
                              final sizeMb = ((book.filesizebytes ?? 0) / (1024 * 1024)).toStringAsFixed(1);

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.book),
                                  ),
                                  title: Text(
                                    book.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('${book.author} • $sizeMb MB'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download_for_offline, color: Colors.blue),
                                    tooltip: 'Download Book',
                                    onPressed: () => _downloadSingleBook(book),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
