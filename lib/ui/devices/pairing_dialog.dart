import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

String generatePairingCode(String deviceUuid) {
  final window = DateTime.now().millisecondsSinceEpoch ~/ (90 * 1000);
  final bytes = utf8.encode('$deviceUuid-$window');
  final digest = sha256.convert(bytes);
  final code = (digest.bytes.fold<int>(0, (prev, elem) => prev + elem) % 900000) + 100000;
  return code.toString();
}

int getSecondsRemainingInWindow() {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final windowMs = 90 * 1000;
  return 90 - ((nowMs % windowMs) ~/ 1000);
}

class PairingDialog extends StatefulWidget {
  final String deviceUuid;
  final String deviceName;
  final String localIp;
  final int port;
  final Function(String codeOrIp)? onPairRequested;

  const PairingDialog({
    super.key,
    required this.deviceUuid,
    required this.deviceName,
    required this.localIp,
    this.port = 8765,
    this.onPairRequested,
  });

  @override
  State<PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<PairingDialog> {
  late Timer _timer;
  int _secondsRemaining = 90;
  String _currentCode = '';
  int _selectedTab = 0; // 0: QR, 1: Code, 2: Enter Code, 3: Scan (Mobile)
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCode();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining = getSecondsRemainingInWindow();
        if (_secondsRemaining >= 90 || _secondsRemaining == 0) {
          _refreshCode();
        }
      });
    });
  }

  void _refreshCode() {
    _currentCode = generatePairingCode(widget.deviceUuid);
    _secondsRemaining = getSecondsRemainingInWindow();
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String get _qrPayload {
    return jsonEncode({
      'id': widget.deviceUuid,
      'name': widget.deviceName,
      'ip': widget.localIp,
      'port': widget.port,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isLinux
              ? 'linux'
              : 'windows',
      'code': _currentCode,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Countdown Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.phonelink_ring, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 10),
                    const Text(
                      'Pair New Device',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: _secondsRemaining / 90.0,
                        strokeWidth: 3,
                        color: _secondsRemaining < 15 ? Colors.red : Theme.of(context).primaryColor,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    ),
                    Text(
                      '$_secondsRemaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 15 ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented View Toggle
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('QR Code'),
                    selected: _selectedTab == 0,
                    onSelected: (_) => setState(() => _selectedTab = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('PIN Code'),
                    selected: _selectedTab == 1,
                    onSelected: (_) => setState(() => _selectedTab = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Enter Code'),
                    selected: _selectedTab == 2,
                    onSelected: (_) => setState(() => _selectedTab = 2),
                  ),
                  if (isMobile) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Scan QR'),
                      selected: _selectedTab == 3,
                      onSelected: (_) => setState(() => _selectedTab = 3),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Content
            if (_selectedTab == 0) ...[
              // QR Code View
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Scan this QR code from your mobile device',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else if (_selectedTab == 1) ...[
              // 6-digit Code View
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _currentCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pairing code copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy Code'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter this code on the remote device',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ] else if (_selectedTab == 2) ...[
              // Manual Entry View
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '6-Digit Code or Device IP',
                  hintText: 'e.g. 482910 or 10.153.30.118',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (_codeController.text.isNotEmpty) {
                        widget.onPairRequested?.call(_codeController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ] else if (_selectedTab == 3 && isMobile) ...[
              // Mobile Camera QR Scanner
              SizedBox(
                height: 220,
                width: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          widget.onPairRequested?.call(barcode.rawValue!);
                          Navigator.of(context).pop();
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
