import '../../core/constants/app_constants.dart';

class DisasterModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String imageUrl;
  final String category;
  final int level; // 1-5 danger level
  final List<PhaseContent> phases;
  final DateTime? updatedAt;

  DisasterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.imageUrl,
    required this.category,
    required this.level,
    required this.phases,
    this.updatedAt,
  });

  factory DisasterModel.fromJson(Map<String, dynamic> json) {
    final rootVideos =
        (json['videos'] as List<dynamic>?)
            ?.map((v) => VideoModel.fromJson(v))
            .toList() ??
        [];

    String rawIcon = json['icon_url'] ?? '';
    String rawImage = json['image_url'] ?? '';

    rawIcon = _fixMediaUrl(rawIcon);
    rawImage = _fixMediaUrl(rawImage);

    return DisasterModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: rawIcon,
      imageUrl: rawImage,
      category: json['category'] ?? '',
      level: json['level'] ?? 1,
      phases:
          (json['phases'] as List<dynamic>?)
              ?.map((p) => PhaseContent.fromJson(p, rootVideos))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'category': category,
      'level': level,
      'phases': phases.map((p) => p.toJson()).toList(),
    };
  }

  /// Resolve a media URL from the API.
  /// - Absolute URLs (https://...) are returned as-is.
  /// - Relative paths (/uploads/...) are prepended with cdnBaseUrl.
  /// - Legacy hardcoded local IPs are replaced with cdnBaseUrl.
  static String _fixMediaUrl(String url) {
    if (url.isEmpty) return url;

    // Replace any hardcoded local dev IPs with the production CDN
    final localIpPattern = RegExp(r'https?://192\.168\.\d+\.\d+:\d+');
    if (localIpPattern.hasMatch(url)) {
      return url.replaceFirst(localIpPattern, AppConstants.cdnBaseUrl);
    }

    // Relative path → prepend base
    if (url.startsWith('/')) {
      return '${AppConstants.cdnBaseUrl}$url';
    }

    return url;
  }
}

class PhaseContent {
  final String phase; // pra, saat, pasca
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<VideoModel> videos;
  final List<ArticleItem> articles;

  PhaseContent({
    required this.phase,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.videos,
    required this.articles,
  });

  factory PhaseContent.fromJson(
    Map<String, dynamic> json, [
    List<VideoModel> rootVideos = const [],
  ]) {
    final phaseName = json['phase'] ?? '';

    List<String> rawImages =
        (json['images'] as List<dynamic>?)
            ?.where((img) => img['image_url'] != null)
            .map((img) => img['image_url'].toString())
            .toList() ??
        [];

    List<String> fixedImages =
        rawImages.map((url) => DisasterModel._fixMediaUrl(url)).toList();

    // App design expects videos to always be in the 'saat' phase.
    // The backend might mistakenly return videos with phase 'pra'.
    final phaseVideos = phaseName == 'saat' ? rootVideos : <VideoModel>[];

    return PhaseContent(
      phase: phaseName,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: fixedImages,
      videos: phaseVideos,
      articles:
          (json['articles'] as List<dynamic>?)
              ?.map((a) => ArticleItem.fromJson(a))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase,
      'title': title,
      'description': description,
      'image_urls': imageUrls,
      'videos': videos.map((v) => v.toJson()).toList(),
      'articles': articles.map((a) => a.toJson()).toList(),
    };
  }
}

class VideoModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String duration;
  final String phase;
  final String disasterId;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.phase,
    required this.disasterId,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    String rawVideoUrl = json['video_url'] ?? '';
    String rawThumbnailUrl = json['thumbnail_url'] ?? '';

    rawVideoUrl = DisasterModel._fixMediaUrl(rawVideoUrl);
    rawThumbnailUrl = DisasterModel._fixMediaUrl(rawThumbnailUrl);

    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: rawVideoUrl,
      thumbnailUrl: rawThumbnailUrl,
      duration: json['duration'] ?? '0:00',
      phase: json['phase'] ?? '',
      disasterId: json['disaster_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'phase': phase,
      'disaster_id': disasterId,
    };
  }
}

class ArticleItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String type; // tip, warning, info
  final DateTime? publishedAt;

  ArticleItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.type,
    this.publishedAt,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    String? rawImageUrl = json['image_url'];
    if (rawImageUrl != null) {
      rawImageUrl = DisasterModel._fixMediaUrl(rawImageUrl);
    }

    return ArticleItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: rawImageUrl,
      type: json['type'] ?? 'info',
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'type': type,
    };
  }
}
