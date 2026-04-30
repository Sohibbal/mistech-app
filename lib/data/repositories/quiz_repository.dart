import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../../core/network/api_client.dart';

class QuizRepository {
  final ApiClient _client = ApiClient.instance;

  static const String _prefKeyPrefix = 'quiz_progress_';
  static const String _prefPhaseDonePrefix = 'phase_done_';

  // ─────────────────────────────────────────
  // API calls
  // ─────────────────────────────────────────

  /// Get all quizzes (one per disaster)
  Future<List<QuizModel>> getAllQuizzes() async {
    try {
      final response = await _client.get('/quizzes');
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((j) => QuizModel.fromJson(j)).toList();
    } catch (_) {
      return _getMockQuizzes();
    }
  }

  /// Get quiz detail (with questions) for a specific disaster
  Future<QuizModel> getQuizByDisaster(String disasterId) async {
    try {
      final response = await _client.get('/quizzes/disaster/$disasterId');
      return QuizModel.fromJson(response.data['data'] ?? response.data);
    } catch (_) {
      return _getMockQuizzes().firstWhere((q) => q.disasterId == disasterId,
          orElse: () => _getMockQuizzes().first);
    }
  }

  // ─────────────────────────────────────────
  // Local progress (SharedPreferences)
  // ─────────────────────────────────────────

  /// Mark a phase as completed for a disaster
  Future<void> markPhaseCompleted(String disasterId, String phase) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPhaseDonePrefix${disasterId}_$phase';
    await prefs.setBool(key, true);
  }

  /// Check if all 3 phases are done for a disaster → quiz unlocked
  Future<bool> isQuizUnlocked(String disasterId) async {
    final prefs = await SharedPreferences.getInstance();
    final pra =
        prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_pra') ?? false;
    final saat =
        prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_saat') ?? false;
    final pasca =
        prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_pasca') ?? false;
    return pra && saat && pasca;
  }

  /// Check which phases are done
  Future<Map<String, bool>> getPhasesStatus(String disasterId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pra': prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_pra') ?? false,
      'saat':
          prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_saat') ?? false,
      'pasca':
          prefs.getBool('${_prefPhaseDonePrefix}${disasterId}_pasca') ?? false,
    };
  }

  /// Save quiz result after completing
  Future<void> saveQuizResult(
      String disasterId, int score, String version) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefKeyPrefix$disasterId';
    final data = json.encode({
      'has_completed': true,
      'last_score': score,
      'last_version': version,
      'last_attempt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(key, data);
  }

  /// Get saved quiz progress for a disaster
  Future<QuizProgressRecord> getQuizProgress(String disasterId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefKeyPrefix$disasterId';
    final raw = prefs.getString(key);
    final isUnlocked = await isQuizUnlocked(disasterId);

    if (raw == null) {
      return QuizProgressRecord(
        disasterId: disasterId,
        isUnlocked: isUnlocked,
        hasCompleted: false,
      );
    }

    final data = json.decode(raw) as Map<String, dynamic>;
    return QuizProgressRecord(
      disasterId: disasterId,
      isUnlocked: isUnlocked,
      hasCompleted: data['has_completed'] ?? false,
      lastScore: data['last_score'],
      lastVersion: data['last_version'],
      lastAttempt: data['last_attempt'] != null
          ? DateTime.tryParse(data['last_attempt'])
          : null,
    );
  }

  // ─────────────────────────────────────────
  // Mock Data (fallback when API unavailable)
  // ─────────────────────────────────────────

  List<QuizModel> _getMockQuizzes() {
    return [
      _buildMockQuiz('1', 'Gempa Bumi', _gempaQuestions()),
      _buildMockQuiz('2', 'Banjir', _banjirQuestions()),
      _buildMockQuiz('3', 'Gunung Meletus', _gunungQuestions()),
      _buildMockQuiz('4', 'Tsunami', _tsunamiQuestions()),
      _buildMockQuiz('5', 'Tanah Longsor', _longsorQuestions()),
      _buildMockQuiz('6', 'Kebakaran Hutan', _kebakaranQuestions()),
    ];
  }

  QuizModel _buildMockQuiz(
      String disasterId, String name, List<QuizQuestion> questions) {
    return QuizModel(
      id: 'quiz_$disasterId',
      disasterId: disasterId,
      disasterName: name,
      description: 'Uji pemahamanmu tentang $name dan cara menghadapinya.',
      totalQuestions: questions.length,
      passingScore: 70,
      questions: questions,
      updatedAt: DateTime(2025, 4, 20),
      version: '1.0',
    );
  }

  List<QuizQuestion> _gempaQuestions() => [
        QuizQuestion(
          id: 'g1',
          order: 1,
          question:
              'Apa yang harus dilakukan pertama kali saat gempa terjadi di dalam ruangan?',
          options: [
            'Berlari keluar gedung secepat mungkin',
            'Berlindung di bawah meja yang kokoh',
            'Berdiri di sudut ruangan',
            'Mengambil barang berharga terlebih dahulu',
          ],
          correctIndex: 1,
          explanation:
              'Berlindung di bawah meja kokoh dapat melindungi dari reruntuhan saat gempa.',
        ),
        QuizQuestion(
          id: 'g2',
          order: 2,
          question: 'Apa kepanjangan dari BMKG?',
          options: [
            'Badan Meteorologi Klimatologi dan Geofisika',
            'Badan Mitigasi Kebencanaan Gempa',
            'Biro Meteorologi dan Kebencanaan Geologi',
            'Badan Manajemen Krisis dan Geofisika',
          ],
          correctIndex: 0,
          explanation:
              'BMKG adalah Badan Meteorologi Klimatologi dan Geofisika yang bertugas memantau gempa bumi.',
        ),
        QuizQuestion(
          id: 'g3',
          order: 3,
          question: 'Gempa bumi disebabkan oleh?',
          options: [
            'Angin kencang di lapisan atmosfer',
            'Pergerakan lempeng tektonik',
            'Hujan deras yang terus-menerus',
            'Letusan gunung berapi saja',
          ],
          correctIndex: 1,
          explanation:
              'Gempa bumi umumnya disebabkan oleh pergerakan dan gesekan lempeng tektonik di bawah bumi.',
        ),
        QuizQuestion(
          id: 'g4',
          order: 4,
          question:
              'Setelah gempa selesai, kapan waktu yang aman untuk masuk kembali ke gedung?',
          options: [
            'Segera setelah guncangan berhenti',
            'Setelah mendapat izin dari petugas yang berwenang',
            '5 menit setelah gempa berhenti',
            'Ketika tetangga sudah masuk lebih dulu',
          ],
          correctIndex: 1,
          explanation:
              'Tunggu izin dari petugas berwenang karena struktur bangunan mungkin sudah melemah.',
        ),
        QuizQuestion(
          id: 'g5',
          order: 5,
          question:
              'Skala apa yang digunakan untuk mengukur kekuatan gempa bumi?',
          options: [
            'Skala Celcius',
            'Skala Beaufort',
            'Skala Richter / Magnitudo',
            'Skala Fujita',
          ],
          correctIndex: 2,
          explanation:
              'Kekuatan gempa diukur menggunakan Skala Richter atau Magnitudo Momen (Mw).',
        ),
        QuizQuestion(
          id: 'g6',
          order: 6,
          question: 'Tas siaga bencana sebaiknya diperiksa ulang setiap?',
          options: [
            'Setiap hari',
            'Setiap minggu',
            'Setiap 6 bulan sekali',
            'Setiap 5 tahun sekali',
          ],
          correctIndex: 2,
          explanation:
              'Tas siaga harus diperiksa setiap 6 bulan agar item di dalamnya masih layak pakai.',
        ),
      ];

  List<QuizQuestion> _banjirQuestions() {
    List<QuizQuestion> q = [];
    // 10 Objective
    for (int i = 1; i <= 10; i++) {
      q.add(QuizQuestion(
        id: 'b_obj_$i',
        order: i,
        question: 'Pertanyaan Objektif Banjir $i?',
        options: ['Opsi A', 'Opsi B', 'Opsi C', 'Opsi D'],
        correctIndex: 1,
        explanation: 'Penjelasan untuk objektif $i.',
      ));
    }
    // 5 True/False
    for (int i = 11; i <= 15; i++) {
      q.add(QuizQuestion(
        id: 'b_tf_$i',
        order: i,
        question: 'Pernyataan Benar/Salah Banjir $i?',
        options: ['Benar', 'Salah'],
        correctIndex: 0,
        explanation: 'Penjelasan untuk benar/salah $i.',
      ));
    }
    return q;
  }

  List<QuizQuestion> _gunungQuestions() => [
        QuizQuestion(
          id: 'gu1',
          order: 1,
          question: 'Status gunung berapi tertinggi di Indonesia adalah?',
          options: ['Waspada', 'Siaga', 'Awas', 'Normal'],
          correctIndex: 2,
          explanation:
              'Status "Awas" adalah level tertinggi yang berarti letusan dapat terjadi sewaktu-waktu.',
        ),
        QuizQuestion(
          id: 'gu2',
          order: 2,
          question: 'Awan panas dari letusan gunung disebut?',
          options: [
            'Lahar dingin',
            'Wedhus gembel (awan panas)',
            'Lava basalt',
            'Fumarol'
          ],
          correctIndex: 1,
          explanation:
              'Awan panas atau "wedhus gembel" adalah massa gas panas dan material vulkanik yang sangat berbahaya.',
        ),
        QuizQuestion(
          id: 'gu3',
          order: 3,
          question: 'Saat status gunung "Siaga", masyarakat harus?',
          options: [
            'Tetap beraktivitas normal',
            'Mempersiapkan evakuasi dan waspada',
            'Mendekati kawah untuk memantau',
            'Mengabaikan informasi PVMBG',
          ],
          correctIndex: 1,
          explanation:
              'Pada status Siaga, masyarakat harus siap evakuasi dan terus memantau perkembangan.',
        ),
        QuizQuestion(
          id: 'gu4',
          order: 4,
          question:
              'Masker apa yang paling efektif melindungi dari abu vulkanik?',
          options: [
            'Masker kain biasa',
            'Masker N95 atau respirator',
            'Sapu tangan basah',
            'Tidak perlu masker',
          ],
          correctIndex: 1,
          explanation:
              'Masker N95 atau respirator dengan filter partikel halus paling efektif melawan abu vulkanik.',
        ),
        QuizQuestion(
          id: 'gu5',
          order: 5,
          question:
              'Radius bahaya minimum saat gunung meletus level Awas biasanya?',
          options: ['500 meter', '2 km', '5-10 km atau lebih', '100 meter'],
          correctIndex: 2,
          explanation:
              'Radius bahaya minimal 5-10 km tergantung karakteristik gunung dan intensitas letusan.',
        ),
      ];

  List<QuizQuestion> _tsunamiQuestions() => [
        QuizQuestion(
          id: 't1',
          order: 1,
          question:
              'Tanda alami tsunami akan datang setelah gempa di laut adalah?',
          options: [
            'Air laut naik mendadak setinggi 10 meter',
            'Air laut surut tiba-tiba jauh dari pantai',
            'Angin kencang dari arah laut',
            'Warna laut berubah menjadi merah',
          ],
          correctIndex: 1,
          explanation:
              'Air laut yang surut tiba-tiba adalah tanda bahaya bahwa tsunami sedang "menarik" air sebelum menghantam.',
        ),
        QuizQuestion(
          id: 't2',
          order: 2,
          question:
              'Jika merasakan gempa kuat di tepi pantai, apa yang harus dilakukan?',
          options: [
            'Menonton dari tepi pantai',
            'Segera lari ke tempat tinggi tanpa menunggu peringatan',
            'Menunggu sirine berbunyi dulu',
            'Masuk ke dalam air untuk keamanan',
          ],
          correctIndex: 1,
          explanation:
              'Jangan menunggu! Segera lari ke dataran tinggi. Tsunami bisa datang dalam hitungan menit.',
        ),
        QuizQuestion(
          id: 't3',
          order: 3,
          question:
              'Ketinggian minimum yang aman untuk mengungsi dari tsunami adalah?',
          options: [
            '5 meter di atas permukaan laut',
            '30 meter di atas permukaan laut',
            '10 meter di atas permukaan laut',
            'Cukup di dalam gedung 3 lantai'
          ],
          correctIndex: 1,
          explanation:
              'Ketinggian minimal 30 meter di atas permukaan laut atau sejauh mungkin dari pantai.',
        ),
        QuizQuestion(
          id: 't4',
          order: 4,
          question: 'Tsunami berbeda dengan gelombang laut biasa karena?',
          options: [
            'Ukurannya lebih kecil',
            'Energinya mencakup seluruh kolom air laut, bukan hanya permukaan',
            'Hanya terjadi di malam hari',
            'Bergerak lebih lambat dari gelombang biasa',
          ],
          correctIndex: 1,
          explanation:
              'Tsunami membawa energi dari dasar hingga permukaan laut, membuatnya jauh lebih dahsyat.',
        ),
        QuizQuestion(
          id: 't5',
          order: 5,
          question: 'Kapan boleh kembali ke pantai setelah tsunami?',
          options: [
            '30 menit setelah gelombang pertama',
            'Setelah pihak berwenang menyatakan aman',
            'Ketika gelombang sudah tidak terlihat',
            'Setelah 2 jam',
          ],
          correctIndex: 1,
          explanation:
              'Tunggu pernyataan resmi dari BMKG atau pihak berwenang. Tsunami bisa datang bergelombang berkali-kali.',
        ),
      ];

  List<QuizQuestion> _longsorQuestions() => [
        QuizQuestion(
          id: 'l1',
          order: 1,
          question: 'Wilayah yang paling rawan tanah longsor adalah?',
          options: [
            'Dataran rendah dekat sungai',
            'Lereng bukit curam dengan tanah labil',
            'Pantai berpasir',
            'Padang rumput datar',
          ],
          correctIndex: 1,
          explanation:
              'Lereng curam dengan tanah labil sangat rentan longsor, terutama saat hujan lebat.',
        ),
        QuizQuestion(
          id: 'l2',
          order: 2,
          question: 'Tanda bahwa lereng akan longsor antara lain?',
          options: [
            'Tanah terasa keras dan kering',
            'Muncul retakan di tanah, pohon miring, atau air keruh dari lereng',
            'Cuaca cerah dan panas',
            'Banyak burung terbang ke arah lereng',
          ],
          correctIndex: 1,
          explanation:
              'Retakan, pohon miring, dan air keruh dari lereng adalah tanda-tanda tanah tidak stabil.',
        ),
        QuizQuestion(
          id: 'l3',
          order: 3,
          question: 'Untuk mencegah longsor, salah satu caranya adalah?',
          options: [
            'Menebang semua pohon di lereng',
            'Menanam tanaman berakar kuat dan membuat terasering',
            'Membangun di puncak lereng tanpa pondasi',
            'Menyirami lereng dengan banyak air',
          ],
          correctIndex: 1,
          explanation:
              'Tanaman berakar kuat mengikat tanah dan terasering mengurangi kecepatan air mengalir.',
        ),
        QuizQuestion(
          id: 'l4',
          order: 4,
          question: 'Saat terjadi longsor, jika tidak bisa menghindar harus?',
          options: [
            'Berlari mengikuti arah longsor',
            'Berlindung di balik batu besar atau pohon besar',
            'Berdiri tegak dan berteriak',
            'Melompat ke sungai terdekat',
          ],
          correctIndex: 1,
          explanation:
              'Berlindung di balik objek kokoh dapat mengurangi terjangan material longsor.',
        ),
        QuizQuestion(
          id: 'l5',
          order: 5,
          question:
              'Pasca longsor, mengapa tidak boleh langsung masuk ke area terdampak?',
          options: [
            'Karena masih ada hewan buas',
            'Karena berisiko longsor susulan dan gas berbahaya',
            'Karena terlalu kotor',
            'Tidak ada larangan, boleh langsung masuk',
          ],
          correctIndex: 1,
          explanation:
              'Longsor susulan sangat mungkin terjadi, dan gas berbahaya bisa terperangkap di dalam material.',
        ),
      ];

  List<QuizQuestion> _kebakaranQuestions() {
    List<QuizQuestion> q = [];
    // 10 Objective
    for (int i = 1; i <= 10; i++) {
      q.add(QuizQuestion(
        id: 'k_obj_$i',
        order: i,
        question: 'Pertanyaan Objektif Kebakaran Hutan $i?',
        options: ['Opsi A', 'Opsi B', 'Opsi C', 'Opsi D'],
        correctIndex: 1,
        explanation: 'Penjelasan untuk objektif $i.',
      ));
    }
    // 5 True/False
    for (int i = 11; i <= 15; i++) {
      q.add(QuizQuestion(
        id: 'k_tf_$i',
        order: i,
        question: 'Pernyataan Benar/Salah Kebakaran Hutan $i?',
        options: ['Benar', 'Salah'],
        correctIndex: 0,
        explanation: 'Penjelasan untuk benar/salah $i.',
      ));
    }
    return q;
  }
}
