import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const VideoPlayerScreen({super.key, required this.videoData});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _loadingMessage = 'Mempersiapkan video...';

  String get videoUrl => widget.videoData['videoUrl'] ?? '';
  String get title => widget.videoData['title'] ?? 'Video Edukasi';
  String get description => widget.videoData['description'] ?? '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (videoUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    try {
      setState(() => _loadingMessage = 'Menghubungkan ke server...');

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: const {
          // Hint the server that we want streaming
          'Connection': 'keep-alive',
        },
      );

      // Listen for buffering state changes
      _videoController!.addListener(_onVideoStateChanged);

      setState(() => _loadingMessage = 'Memuat video...');

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: AppColors.primarySurface,
          bufferedColor: AppColors.primarySurface2,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat video',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _retryVideo,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _onVideoStateChanged() {
    // This listener keeps the UI in sync with buffering state
    if (mounted) {
      setState(() {});
    }
  }

  void _retryVideo() {
    _chewieController?.dispose();
    _videoController?.removeListener(_onVideoStateChanged);
    _videoController?.dispose();
    _videoController = null;
    _chewieController = null;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadingMessage = 'Mempersiapkan video...';
    });
    _initVideo();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoController?.removeListener(_onVideoStateChanged);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                _buildVideoContent(),
                // Buffering overlay
                if (!_isLoading &&
                    !_hasError &&
                    _videoController != null &&
                    _videoController!.value.isBuffering)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Buffering...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Video Info
          Expanded(
            child: Container(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Video Edukasi Bencana',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _loadingMessage,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white54,
                size: 60,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat video.\nPeriksa koneksi internet Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _retryVideo,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return const SizedBox.shrink();
  }
}
