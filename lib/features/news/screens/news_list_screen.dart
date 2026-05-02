import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../data/models/news_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final ApiClient _client = ApiClient.instance;
  List<NewsModel> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _client.get('/news');
      if (response.data['status'] == 'success') {
        final list = response.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _newsList = list.map((e) => NewsModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      // Ignore error for now, keep empty list
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Berita Terkini',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),

      ),
      body: RefreshIndicator(
        onRefresh: _fetchNews,
        color: AppColors.primary,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _newsList.isEmpty
            ? CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Belum ada berita',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: _newsList.length,
                itemBuilder: (context, index) {
                  final news = _newsList[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        context.push('/news/${news.id}', extra: news);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CachedNetworkImage(
                            imageUrl: news.thumbnail,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  news.title,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  news.shortDescription,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      news.date,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const Text(
                                      'Baca Selengkapnya',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
