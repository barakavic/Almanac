import 'dart:io';

import 'package:bookshelf/data/models/watched_folder.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/processes/FolderScanner/folder_scanner.dart';
import 'package:bookshelf/utils/device_identity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

enum _FolderAction { remove }

class _FolderOptions {
  const _FolderOptions({required this.displayName, required this.recursive});

  final String displayName;
  final bool recursive;
}

class WatchedFoldersScreen extends ConsumerStatefulWidget {
  const WatchedFoldersScreen({super.key});

  @override
  ConsumerState<WatchedFoldersScreen> createState() =>
      _WatchedFoldersScreenState();
}

class _WatchedFoldersScreenState extends ConsumerState<WatchedFoldersScreen> {
  final Set<String> _scanningFolderIds = {};

  Future<void> _addFolder() async {
    final selectedPath = await FilePicker.getDirectoryPath();
    if (selectedPath == null || !mounted) return;

    final options = await _showFolderOptions(selectedPath);
    if (options == null || !mounted) return;

    final deviceId = await getDeviceFingerprint();
    final repository = ref.read(watchedFolderRepositoryProvider);
    final existing = await repository.getFolderByPath(deviceId, selectedPath);
    if (!mounted) return;

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That folder is already being watched.')),
      );
      return;
    }

    final now = DateTime.now();
    final folder = WatchedFolder(
      folderid: const Uuid().v4(),
      deviceid: deviceId,
      displayname: options.displayName,
      absolutepath: selectedPath,
      volumeserial: '',
      isremovable: 0,
      isavailable: Directory(selectedPath).existsSync() ? 1 : 0,
      autoimport: 1,
      recursive: options.recursive ? 1 : 0,
      scanstatus: 0,
      lastscannedat: now,
      lastseenat: now,
      addedat: now,
    );

    try {
      await repository.addFolder(folder);
      ref.invalidate(watchedFoldersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${folder.displayname} is now being watched.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not add this folder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<_FolderOptions?> _showFolderOptions(String selectedPath) async {
    final controller = TextEditingController(text: path.basename(selectedPath));
    var recursive = true;

    final result = await showDialog<_FolderOptions>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Watch folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Folder name'),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include subfolders'),
                value: recursive,
                onChanged: (value) => setDialogState(() => recursive = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final displayName = controller.text.trim();
                if (displayName.isEmpty) return;
                Navigator.of(dialogContext).pop(
                  _FolderOptions(
                    displayName: displayName,
                    recursive: recursive,
                  ),
                );
              },
              child: const Text('Add folder'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }

  Future<void> _scanFolder(WatchedFolder folder) async {
    if (_scanningFolderIds.contains(folder.folderid)) return;
    setState(() => _scanningFolderIds.add(folder.folderid));

    try {
      final added = await FolderScanner.scan(
        folder,
        ref.read(bookRepositoryProvider),
      );
      await ref
          .read(watchedFolderRepositoryProvider)
          .updateLastScannedTimestamp(
            folder.folderid,
            DateTime.now().toIso8601String(),
          );
      ref.invalidate(watchedFoldersProvider);
      ref.invalidate(booksProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 1 ? 'Imported 1 book.' : 'Imported $added books.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not scan ${folder.displayname}. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _scanningFolderIds.remove(folder.folderid));
      }
    }
  }

  Future<void> _removeFolder(WatchedFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stop watching folder?'),
        content: Text(
          'Books already imported from ${folder.displayname} will remain in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop watching'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(watchedFolderRepositoryProvider)
          .deleteFolder(folder.folderid);
      ref.invalidate(watchedFoldersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stopped watching ${folder.displayname}.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove this folder. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return timestamp.toLocal().toString().split('.').first;
  }

  Future<void> _refreshFolders() async {
    ref.invalidate(watchedFoldersProvider);
    await ref.read(watchedFoldersProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(watchedFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Folders'),
        actions: [
          IconButton(
            tooltip: 'Refresh folders',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(watchedFoldersProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFolders,
        child: foldersAsync.when(
          data: (folders) {
            if (folders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Text('No folders are being watched.'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: folders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final folder = folders[index];
                final isScanning = _scanningFolderIds.contains(folder.folderid);
                final isAvailable = Directory(folder.absolutepath).existsSync();

                return Card(
                  child: ListTile(
                    leading: Icon(
                      isAvailable ? Icons.folder : Icons.folder_off,
                      color: isAvailable
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    title: Text(folder.displayname),
                    subtitle: Text(
                      '${folder.absolutepath}\n'
                      '${folder.recursive == 1 ? 'Includes subfolders' : 'This folder only'} • '
                      'Last scan: ${_formatTimestamp(folder.lastscannedat)}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Scan folder',
                          onPressed: isAvailable && !isScanning
                              ? () => _scanFolder(folder)
                              : null,
                          icon: isScanning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                        ),
                        PopupMenuButton<_FolderAction>(
                          tooltip: 'Folder actions',
                          onSelected: (action) {
                            if (action == _FolderAction.remove) {
                              _removeFolder(folder);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _FolderAction.remove,
                              child: Text('Stop watching'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load folders: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add watched folder',
        onPressed: _addFolder,
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
