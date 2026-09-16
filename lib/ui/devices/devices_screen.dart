import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookshelf/data/models/device.dart';
import 'package:bookshelf/data/providers.dart';
import 'package:bookshelf/services/sync_service.dart';
import 'package:bookshelf/ui/devices/device_detail_screen.dart';
import 'package:bookshelf/ui/devices/pairing_dialog.dart';
import 'package:bookshelf/ui/folders/watched_folders_screen.dart';
import 'package:bookshelf/utils/device_identity.dart';
import 'package:bookshelf/utils/platform_utils.dart';

enum _DeviceAction { remove }

final pairedDevicesListProvider = FutureProvider<List<Device>>((ref) async {
  final repo = ref.watch(deviceRepositoryProvider);
  return repo.getAllDevices();
});

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  Timer? _healthTimer;
  final Map<String, bool> _deviceOnlineStatus = {};
  final Map<String, int> _pingFailCount = {};

  @override
  void initState() {
    super.initState();
    _startPeriodicHealthCheck();
  }

  void _startPeriodicHealthCheck() {
    // Run health check every 60s
    _healthTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkAllDevicesHealth();
    });
    // Immediate initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAllDevicesHealth();
    });
  }

  Future<void> _checkAllDevicesHealth() async {
    final deviceRepo = ref.read(deviceRepositoryProvider);
    final devices = await deviceRepo.getAllDevices();
    final syncService = SyncService(deviceRepo);

    for (final device in devices) {
      if (device.deviceid == null) continue;
      final ip = device.macaddress; // Or stored ip
      final isAlive = await syncService.pingDevice(ip);

      if (isAlive) {
        _pingFailCount[device.deviceid!] = 0;
        _deviceOnlineStatus[device.deviceid!] = true;
        ref.read(transferServiceProvider).processQueueForDevice(device);
      } else {
        final fails = (_pingFailCount[device.deviceid!] ?? 0) + 1;
        _pingFailCount[device.deviceid!] = fails;
        if (fails >= 3) {
          _deviceOnlineStatus[device.deviceid!] = false;
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _healthTimer?.cancel();
    super.dispose();
  }

  Color _getPlatformColor(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'linux':
      case 'ubuntu':
        return const Color(0xFFE95420); // Ubuntu Orange
      case 'android':
        return const Color(0xFF3DDC84); // Android Green
      case 'windows':
        return const Color(0xFF0078D4); // Fluent Blue
      case 'macos':
      case 'ios':
        return const Color(0xFFA2AAAD); // Apple Slate
      default:
        return Colors.deepPurple;
    }
  }

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'linux':
      case 'ubuntu':
        return Icons.terminal;
      case 'android':
        return Icons.android;
      case 'windows':
        return Icons.window;
      case 'macos':
      case 'ios':
        return Icons.apple;
      default:
        return Icons.devices;
    }
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  Future<void> _refreshDevices() async {
    ref.invalidate(pairedDevicesListProvider);
    await ref.read(pairedDevicesListProvider.future);
    if (mounted) {
      unawaited(_checkAllDevicesHealth());
    }
  }

  Future<void> _openPairingDialog() async {
    final uuid = await getDeviceFingerprint();
    final ip = await _getLocalIp();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => PairingDialog(
        deviceUuid: uuid,
        deviceName: Platform.isAndroid ? 'Android Phone' : 'Local Host',
        localIp: ip,
        onPairRequested: (codeOrIp) async {
          final deviceRepo = ref.read(deviceRepositoryProvider);
          final syncService = SyncService(deviceRepo);
          final pairedDevice = await syncService.pairWithDevice(codeOrIp);
          final success = pairedDevice != null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Pairing successful!'
                      : 'Pairing failed. Check network or code.',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
            ref.invalidate(pairedDevicesListProvider);
          }
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteDevice(Device device) async {
    final deviceId = device.deviceid;
    if (deviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This device cannot be removed because it has no ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final deviceName = device.devicename ?? 'this device';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove paired device?'),
        content: Text(
          'Remove $deviceName from your paired devices? Any queued transfers for it will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final deleted = await ref
          .read(deviceRepositoryProvider)
          .deleteDevices(deviceId);
      if (!mounted) return;

      if (deleted == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deviceName was already removed.')),
        );
        ref.invalidate(pairedDevicesListProvider);
        return;
      }

      setState(() {
        _deviceOnlineStatus.remove(deviceId);
        _pingFailCount.remove(deviceId);
      });
      ref.invalidate(pairedDevicesListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$deviceName removed from paired devices.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not remove $deviceName. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(pairedDevicesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired Devices'),
        actions: [
          IconButton(
            tooltip: 'Library folders',
            icon: const Icon(Icons.folder_open),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WatchedFoldersScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh devices',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(pairedDevicesListProvider);
              _checkAllDevicesHealth();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDevices,
        child: devicesAsync.when(
          data: (devices) {
            if (devices.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.devices_other,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No paired devices yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button below to pair a laptop or phone',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final isOnline = _deviceOnlineStatus[device.deviceid] ?? true;
                final platformColor = _getPlatformColor(device.platform);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: platformColor.withValues(alpha: 0.15),
                          child: Icon(
                            _getPlatformIcon(device.platform),
                            color: platformColor,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF9E9E9E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.devicename ?? 'Unknown Device',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: platformColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (device.platform ?? 'Device').toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: platformColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isOnline
                            ? 'Online • Port ${device.port}'
                            : 'Offline • Last seen: ${device.lastseenat}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOnline
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    trailing: PlatformUtils.usesOverflowDeviceMenu
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PopupMenuButton<_DeviceAction>(
                                tooltip: 'Device actions',
                                onSelected: (action) {
                                  if (action == _DeviceAction.remove) {
                                    _confirmAndDeleteDevice(device);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: _DeviceAction.remove,
                                    child: Text('Remove paired device'),
                                  ),
                                ],
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeviceDetailScreen(device: device),
                        ),
                      );
                    },
                    onLongPress: PlatformUtils.usesLongPressDeviceActions
                        ? () => _confirmAndDeleteDevice(device)
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading devices: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPairingDialog,
        icon: const Icon(Icons.add_link),
        label: const Text('Pair Device'),
      ),
    );
  }
}
