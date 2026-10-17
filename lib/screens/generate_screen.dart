import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/history_provider.dart';

enum QrType { text, url, wifi }

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  QrType _type = QrType.text;
  final _textCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _qrKey = GlobalKey();
  String _security = 'WPA';
  bool _hidePass = true;
  String? _qrData;

  @override
  void dispose() {
    _textCtrl.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // WiFi QR format eke special characters escape karanna one
  String _escape(String v) =>
      v.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

  void _generate() {
    String? data;

    switch (_type) {
      case QrType.text:
        final t = _textCtrl.text.trim();
        if (t.isNotEmpty) data = t;
        break;
      case QrType.url:
        var u = _textCtrl.text.trim();
        if (u.isNotEmpty) {
          if (!u.startsWith('http://') && !u.startsWith('https://')) {
            u = 'https://$u';
          }
          data = u;
        }
        break;
      case QrType.wifi:
        final ssid = _ssidCtrl.text.trim();
        if (ssid.isNotEmpty) {
          if (_security == 'nopass') {
            data = 'WIFI:T:nopass;S:${_escape(ssid)};;';
          } else {
            data =
            'WIFI:T:$_security;S:${_escape(ssid)};P:${_escape(_passCtrl.text)};;';
          }
        }
        break;
    }

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('first include details')),
      );
      return;
    }
    setState(() => _qrData = data);
    context.read<HistoryProvider>().add(data, 'generated');
  }

  Future<void> _share() async {
    final data = _qrData;
    if (data == null) return;
    try {
      final boundary =
      _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/qr_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: data),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SHARE*: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<QrType>(
          segments: const [
            ButtonSegment(
                value: QrType.text,
                label: Text('Text'),
                icon: Icon(Icons.notes)),
            ButtonSegment(
                value: QrType.url, label: Text('URL'), icon: Icon(Icons.link)),
            ButtonSegment(
                value: QrType.wifi,
                label: Text('WiFi'),
                icon: Icon(Icons.wifi)),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() {
            _type = s.first;
            _qrData = null;
          }),
        ),
        const SizedBox(height: 16),
        if (_type != QrType.wifi)
          TextField(
            controller: _textCtrl,
            maxLines: _type == QrType.text ? 3 : 1,
            keyboardType:
            _type == QrType.url ? TextInputType.url : TextInputType.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _type == QrType.url ? 'Website URL' : 'Text',
            ),
          )
        else ...[
          TextField(
            controller: _ssidCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'WiFi name (SSID)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _security,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Security',
            ),
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('No password')),
            ],
            onChanged: (v) => setState(() => _security = v!),
          ),
          if (_security != 'nopass') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _hidePass,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                      _hidePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Generate QR'),
        ),
        if (_qrData != null) ...[
          const SizedBox(height: 24),
          Center(
            child: RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: QrImageView(
                  data: _qrData!,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(_qrData!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('Share QR'),
            ),
          ),
        ],
      ],
    );
  }
}