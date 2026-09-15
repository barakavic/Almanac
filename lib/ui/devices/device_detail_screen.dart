import 'package:flutter/material.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/models/watched_folder.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final List<WatchedFolder> _watchedFolders = [
    
    ];

  @override
  Widget build(BuildContext context) {
    final dev = widget.device;

    return Scaffold(
      appBar: AppBar(
        title: Text(dev.devicename ?? 'Device Details'),
      ),
      body: Column(
        children: [
          // Device Header Info Card
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
                        'Platform: ${dev.platform?.toUpperCase() ?? "UNKNOWN"} • Port: ${dev.port}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      Text(
                        'MAC / UUID: ${dev.macaddress}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Watched Folders Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Watched Folders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Folders List (2 Sublayer Navigation)
          Expanded(
            child: _watchedFolders.isEmpty
                ? Center(
                    child: Text(
                      'No watched folders declared for this device.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _watchedFolders.length,
                    itemBuilder: (context, index) {
                      final folder = _watchedFolders[index];
                      final isRecursive = folder.recursive == 1;

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ExpansionTile(
                          leading: const Icon(Icons.folder_special, color: Colors.amber),
                          title: Text(
                            folder.displayname,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Path: ${folder.absolutepath} (Recursive: ${isRecursive ? "Yes" : "No"})',
                            style: const TextStyle(fontSize: 11),
                          ),
                          children: [
                            // Sublayer Level 1: Sub-directories / Books
                            ListTile(
                              leading: const Icon(Icons.folder, size: 20),
                              title: const Text('Sublayer 1: /Computer Science'),
                              subtitle: const Text('2 Books (.pdf, .epub)'),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () {
                                _showSublayerDialog(context, 'Computer Science', [
                                  'Clean Code.pdf',
                                  'Designing Data-Intensive Applications.epub'
                                ]);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.folder, size: 20),
                              title: const Text('Sublayer 1: /Fiction & Classics'),
                              subtitle: const Text('1 Book (.epub)'),
                              trailing: const Icon(Icons.chevron_right, size: 18),
                              onTap: () {
                                _showSublayerDialog(context, 'Fiction & Classics', [
                                  'Dune.epub'
                                ]);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSublayerDialog(BuildContext context, String folderName, List<String> books) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.folder_open, color: Colors.amber),
            const SizedBox(width: 8),
            Text(folderName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: books
              .map(
                (book) => ListTile(
                  dense: true,
                  leading: Icon(
                    book.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.menu_book,
                    color: book.endsWith('.pdf') ? Colors.red : Colors.blue,
                  ),
                  title: Text(book),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
