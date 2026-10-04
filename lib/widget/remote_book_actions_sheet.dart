import 'package:bookshelf/data/models/book.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom sheet shown when the user taps a book that lives on a paired device.
class RemoteBookActionsSheet extends ConsumerWidget {
  final Book book;
  final Device device;

  const RemoteBookActionsSheet({
    super.key,
    required this.book,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Book info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.book_outlined, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'On ${device.devicename ?? device.ipaddress}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Download action
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Download to this device'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final transferService = ref.read(transferServiceProvider);
                  await transferService.downloadBook(
                    remoteDevice: device,
                    remoteBook: book,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading "${book.title}"...')),
                    );
                  }
                } catch (e, st) {
                  appLogger.e('Failed to start download',
                      error: e, stackTrace: st);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Failed to start download')),
                    );
                  }
                }
              },
            ),
            // Cancel
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
