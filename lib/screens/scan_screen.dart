import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';

class ScanScreen extends StatefulWidget {
  final bool active;
  const ScanScreen({super.key, required this.active});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  @override
  void didUpdateWidget(ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _start();
    if (!widget.active && oldWidget.active) _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (mounted) setState(() => _error = null);
    try {
      await _controller.start();
    } catch (e) {
      if (mounted) setState(() => _error = 'Camera start wenne na.\n$e');
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    context.read<HistoryProvider>().add(value, 'scanned');

    _busy = true;
    await _controller.stop();
    if (!mounted) return;
    await _showResult(value);
    _busy = false;
    if (mounted && widget.active) await _start();
  }

  Future<void> _showResult(String value) {
    final messenger = ScaffoldMessenger.of(context);
    final isUrl = value.startsWith('http://') || value.startsWith('https://');
    final label = isUrl
        ? 'URL'
        : value.startsWith('WIFI:')
        ? 'WiFi'
        : 'Text';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(value),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Copy una')),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                if (isUrl)
                  FilledButton.icon(
                    onPressed: () async {
                      await launchUrl(Uri.parse(value),
                          mode: LaunchMode.externalApplication);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Scan again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _start, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => _controller.switchCamera(),
                icon: const Icon(Icons.cameraswitch),
              ),
            ],
          ),
        ),
      ],
    );
  }
}