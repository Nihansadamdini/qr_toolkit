import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/qr_item.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmt(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';

  static IconData _icon(String type) {
    switch (type) {
      case 'url':
        return Icons.link;
      case 'wifi':
        return Icons.wifi;
      default:
        return Icons.notes;
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final provider = context.read<HistoryProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DID YOU DELETE ALL?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await provider.clearAll();
  }

  void _showDetail(BuildContext context, QrItem item) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: QrImageView(data: item.content, size: 200),
              ),
              const SizedBox(height: 12),
              SelectableText(item.content, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: item.content));
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Copy una')));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  if (item.type == 'url')
                    FilledButton.icon(
                      onPressed: () async {
                        await launchUrl(Uri.parse(item.content),
                            mode: LaunchMode.externalApplication);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<HistoryProvider>().items;

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('History is empty'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Text('${items.length} items'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _confirmClear(context),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) =>
                    context.read<HistoryProvider>().remove(item.id!),
                child: ListTile(
                  leading: Icon(_icon(item.type)),
                  title: Text(item.content,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${item.source == 'scanned' ? 'Scanned' : 'Generated'} • ${_fmt(item.createdAt)}'),
                  onTap: () => _showDetail(context, item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}