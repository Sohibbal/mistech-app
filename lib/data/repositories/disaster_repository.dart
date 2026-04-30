import '../models/disaster_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class DisasterRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<DisasterModel>> getDisasters({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        AppConstants.disastersEndpoint,
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'limit': limit,
        },
      );

      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((json) => DisasterModel.fromJson(json)).toList();
    } catch (e) {
      // Return mock data for development/offline
      return _getMockDisasters();
    }
  }

  // Get single disaster detail with phases
  Future<DisasterModel> getDisasterDetail(String id) async {
    try {
      final response = await _client.get(
        '${AppConstants.disastersEndpoint}/$id',
      );
      return DisasterModel.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      return _getMockDisasters().firstWhere(
        (d) => d.id == id,
        orElse: () => _getMockDisasters().first,
      );
    }
  }

  // Get videos by disaster and phase
  Future<List<VideoModel>> getVideos({
    String? disasterId,
    String? phase,
  }) async {
    try {
      final response = await _client.get(
        AppConstants.videosEndpoint,
        queryParameters: {
          if (disasterId != null) 'disaster_id': disasterId,
          if (phase != null) 'phase': phase,
        },
      );
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((json) => VideoModel.fromJson(json)).toList();
    } catch (e) {
      return _getMockVideos();
    }
  }

  // Mock data for development / API unavailable
  List<DisasterModel> _getMockDisasters() {
    return [
      DisasterModel(
        id: '1',
        name: 'Gempa Bumi',
        description:
            'Gempa bumi adalah getaran atau guncangan yang terjadi di permukaan bumi akibat pelepasan energi dari dalam bumi yang menciptakan gelombang seismik.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
        category: 'geologi',
        level: 5,
        phases: _getMockPhases('1'),
      ),
      DisasterModel(
        id: '2',
        name: 'Banjir',
        description:
            'Banjir adalah peristiwa tergenangnya suatu tempat akibat meluapnya air yang melebihi kapasitas pembuangan air.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=800',
        category: 'hidrologi',
        level: 4,
        phases: _getMockPhases('2'),
      ),
      DisasterModel(
        id: '3',
        name: 'Gunung Meletus',
        description:
            'Letusan gunung berapi adalah peristiwa keluarnya magma dari dalam bumi melalui gunung berapi.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1611273426858-450e7620370b?w=800',
        category: 'geologi',
        level: 5,
        phases: _getMockPhases('3'),
      ),
      DisasterModel(
        id: '4',
        name: 'Tsunami',
        description:
            'Tsunami adalah serangkaian gelombang laut yang sangat besar yang dihasilkan oleh gangguan di dasar laut.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?w=800',
        category: 'hidrologi',
        level: 5,
        phases: _getMockPhases('4'),
      ),
      DisasterModel(
        id: '5',
        name: 'Tanah Longsor',
        description:
            'Tanah longsor adalah gerakan masa tanah, batu, atau debris yang bergerak menuruni lereng bukit.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1618688722516-c06d5e68ef3b?w=800',
        category: 'geologi',
        level: 3,
        phases: _getMockPhases('5'),
      ),
      DisasterModel(
        id: '6',
        name: 'Kebakaran Hutan',
        description:
            'Kebakaran hutan adalah kebakaran yang terjadi di kawasan hutan dan menyebar dengan cepat.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800',
        category: 'alam',
        level: 4,
        phases: _getMockPhases('6'),
      ),
      DisasterModel(
        id: '7',
        name: 'Putting Beliung',
        description:
            'Puting beliung adalah angin kencang berputar yang bergerak secara vertikal dan horizontal.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1516912481808-3406841bd33c?w=800',
        category: 'meteorologi',
        level: 4,
        phases: _getMockPhases('7'),
      ),
      DisasterModel(
        id: '8',
        name: 'Kekeringan',
        description:
            'Kekeringan adalah kondisi kekurangan air dalam jangka waktu panjang yang menyebabkan dampak buruk.',
        iconUrl: '',
        imageUrl:
            'https://images.unsplash.com/photo-1509909756405-be0199881695?w=800',
        category: 'iklim',
        level: 3,
        phases: _getMockPhases('8'),
      ),
    ];
  }

  List<PhaseContent> _getMockPhases(String disasterId) {
    return [
      PhaseContent(
        phase: 'pra',
        title: 'Pra Bencana',
        description:
            'Persiapan yang harus dilakukan sebelum bencana terjadi untuk meminimalisir dampak.',
        imageUrls: [
          'https://images.unsplash.com/photo-1503428593586-e225b39bddfe?w=800',
          'https://images.unsplash.com/photo-1582213782179-e0d53f98f2ca?w=800',
        ],
        videos: [],
        articles: [
          ArticleItem(
            id: 'a1',
            title: 'Kenali Tanda Bahaya',
            content:
                'Pelajari tanda-tanda awal terjadinya bencana di wilayah Anda. Setiap bencana memiliki tanda peringatan yang dapat dipelajari untuk mempersiapkan diri lebih awal.',
            type: 'warning',
          ),
          ArticleItem(
            id: 'a2',
            title: 'Siapkan Tas Siaga Bencana',
            content:
                'Tas siaga bencana berisi perlengkapan darurat yang dibutuhkan selama bencana. Pastikan tas berisi air minum, makanan tahan lama, obat-obatan, dan dokumen penting.',
            type: 'tip',
          ),
          ArticleItem(
            id: 'a3',
            title: 'Tentukan Titik Kumpul Keluarga',
            content:
                'Sepakati titik kumpul bersama anggota keluarga jika harus terpisah saat bencana terjadi. Pilih tempat yang aman dan mudah dijangkau.',
            type: 'info',
          ),
        ],
      ),
      PhaseContent(
        phase: 'saat',
        title: 'Saat Bencana',
        description:
            'Tindakan yang tepat dan cepat saat bencana berlangsung untuk keselamatan diri.',
        imageUrls: [],
        videos: [
          VideoModel(
            id: 'v1',
            title: 'Simulasi Evakuasi Bencana',
            description:
                'Video simulasi langkah-langkah evakuasi yang benar saat bencana terjadi.',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=800',
            duration: '5:30',
            phase: 'saat',
            disasterId: disasterId,
          ),
          VideoModel(
            id: 'v2',
            title: 'Pertolongan Pertama Darurat',
            description:
                'Cara memberikan pertolongan pertama saat kondisi darurat bencana.',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1585435557343-3b092031a831?w=800',
            duration: '8:15',
            phase: 'saat',
            disasterId: disasterId,
          ),
        ],
        articles: [
          ArticleItem(
            id: 'a4',
            title: 'Jangan Panik',
            content:
                'Tetap tenang dan ikuti prosedur keselamatan yang sudah dipelajari. Panik dapat membahayakan diri sendiri dan orang lain di sekitar Anda.',
            type: 'warning',
          ),
          ArticleItem(
            id: 'a5',
            title: 'Segera Evakuasi',
            content:
                'Ikuti jalur evakuasi yang sudah ditentukan menuju tempat aman. Bantu anggota keluarga dan tetangga yang membutuhkan bantuan.',
            type: 'info',
          ),
        ],
      ),
      PhaseContent(
        phase: 'pasca',
        title: 'Pasca Bencana',
        description:
            'Langkah pemulihan dan rehabilitasi setelah bencana untuk bangkit kembali.',
        imageUrls: [
          'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800',
          'https://images.unsplash.com/photo-1469571486292-0ba58a3f068b?w=800',
        ],
        videos: [],
        articles: [
          ArticleItem(
            id: 'a6',
            title: 'Periksa Kondisi Fisik dan Mental',
            content:
                'Setelah bencana, periksa kondisi kesehatan fisik dan mental Anda serta keluarga. Trauma pasca bencana adalah hal yang wajar dan perlu penanganan.',
            type: 'info',
          ),
          ArticleItem(
            id: 'a7',
            title: 'Hindari Area Berbahaya',
            content:
                'Jangan kembali ke area terdampak sebelum dinyatakan aman oleh petugas. Bangunan yang rusak dapat ambruk sewaktu-waktu.',
            type: 'warning',
          ),
          ArticleItem(
            id: 'a8',
            title: 'Bantuan dan Relawan',
            content:
                'Manfaatkan bantuan dari pemerintah dan lembaga sosial. Anda juga dapat berkontribusi sebagai relawan untuk membantu korban bencana.',
            type: 'tip',
          ),
        ],
      ),
    ];
  }

  List<VideoModel> _getMockVideos() {
    return [
      VideoModel(
        id: 'v1',
        title: 'Simulasi Evakuasi Gempa Bumi',
        description: 'Langkah-langkah evakuasi yang tepat saat gempa bumi.',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1517077304055-6e89abbf09b0?w=800',
        duration: '5:30',
        phase: 'saat',
        disasterId: '1',
      ),
      VideoModel(
        id: 'v2',
        title: 'Mitigasi Banjir',
        description: 'Cara mengurangi risiko banjir di lingkungan sekitar.',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1547036967-23d11aacaee0?w=800',
        duration: '7:45',
        phase: 'pra',
        disasterId: '2',
      ),
    ];
  }
}
