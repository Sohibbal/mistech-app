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
    final rootVideos = (json['videos'] as List<dynamic>?)
            ?.map((v) => VideoModel.fromJson(v))
            .toList() ??
        [];

    return DisasterModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? 1,
      phases: (json['phases'] as List<dynamic>?)
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

  factory PhaseContent.fromJson(Map<String, dynamic> json,
      [List<VideoModel> rootVideos = const []]) {
    final phaseName = json['phase'] ?? '';
    return PhaseContent(
      phase: phaseName,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: (json['images'] as List<dynamic>?)
              ?.map((img) => img['image_url'] as String)
              .toList() ??
          [],
      videos: phaseName == 'saat' ? rootVideos : [],
      articles: (json['articles'] as List<dynamic>?)
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
    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
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
    return ArticleItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
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
