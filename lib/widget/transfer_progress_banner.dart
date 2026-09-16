import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/services/transfer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransferProgressBanner extends ConsumerWidget {
  const TransferProgressBanner({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(transferProgressProvider);

    return ValueListenableBuilder<TransferProgressState>(
      valueListenable: notifier,
      builder: (context, progress, child) {
        if (!progress.isTransferring) {
          return const SizedBox.shrink();
        }

        final mbLeft = (progress.bytesRemaining / (1024 * 1024)).toStringAsFixed(1);
        final speed = progress.speedKbps.toStringAsFixed(1);
        final durationStr = _formatDuration(progress.estimatedTimeRemaining);
        final currentBookIndex = (progress.completedBooksCount + 1).clamp(
          1,
          progress.totalBooksCount == 0 ? 1 : progress.totalBooksCount,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Transferring: ${progress.currentBookTitle}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Stop transfer',
                    onPressed: () => ref.read(transferServiceProvider).cancelCurrentTransfer(),
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$currentBookIndex / ${progress.totalBooksCount} books',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.totalBooksCount > 0
                    ? (progress.completedBooksCount / progress.totalBooksCount)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$speed KB/s',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    '$mbLeft MB remaining',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    '$durationStr left',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
