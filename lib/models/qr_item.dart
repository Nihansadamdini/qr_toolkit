class QrItem {
  final int? id;
  final String type; // text / url / wifi
  final String content;
  final String source; // generated / scanned
  final DateTime createdAt;

  QrItem({
    this.id,
    required this.type,
    required this.content,
    required this.source,
    required this.createdAt,
  });

  static String detectType(String content) {
    if (content.startsWith('http://') || content.startsWith('https://')) {
      return 'url';
    }
    if (content.startsWith('WIFI:')) return 'wifi';
    return 'text';
  }

  Map<String, Object?> toMap() => {
    'type': type,
    'content': content,
    'source': source,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory QrItem.fromMap(Map<String, Object?> m) => QrItem(
    id: m['id'] as int,
    type: m['type'] as String,
    content: m['content'] as String,
    source: m['source'] as String,
    createdAt:
    DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}