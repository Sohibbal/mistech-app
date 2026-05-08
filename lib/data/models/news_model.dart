import 'package:intl/intl.dart';

class NewsModel {
  final String id;
  final String title;
  final String thumbnail;
  final String content;
  final String source;
  final String date;

  NewsModel({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.content,
    required this.source,
    required this.date,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    // Parse date safely
    String formattedDate = '';
    if (json['published_at'] != null) {
      try {
        final d = DateTime.parse(json['published_at']);
        formattedDate = DateFormat('dd MMM yyyy').format(d);
      } catch (_) {}
    }

    String? rawImg = json['image_url'];
    String finalImg =
        'https://images.unsplash.com/photo-1547683905-f686c993b472?q=80&w=1000&auto=format&fit=crop';
    if (rawImg != null && rawImg.isNotEmpty) {
      if (rawImg.startsWith('/')) {
        finalImg = 'http://192.168.8.100:3000$rawImg';
      } else {
        finalImg = rawImg
            .replaceAll('192.168.1.8:3000', '192.168.8.100:3000')
            .replaceAll('localhost:3000', '192.168.8.100:3000')
            .replaceAll('127.0.0.1:3000', '192.168.8.100:3000');
      }
    }

    return NewsModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      thumbnail: finalImg,
      content: json['content'] ?? '',
      source: json['source'] ?? 'E-Disaster News',
      date: formattedDate,
    );
  }

  // Fallback getter for UI compatibility
  String get shortDescription {
    if (content.length > 80) return '${content.substring(0, 80)}...';
    return content;
  }

  String get fullDescription => content;
}
