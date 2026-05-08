import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../../core/network/api_client.dart';

class QuizRepository {
  final ApiClient _client = ApiClient.instance;

  static const String _prefKeyQuiz = 'quiz_progress';
  static const String _prefKeyNews = 'mission_news';
  static const String _prefKeyLkpd = 'mission_lkpd';
  static const String _prefKeyEmodul = 'mission_emodul';
  static const String _prefKeyPhases = 'mission_phases';

  // ─────────────────────────────────────────
  // API calls
  // ─────────────────────────────────────────

  /// Get the single unified quiz
  Future<QuizModel> getQuiz() async {
    try {
      final response = await _client.get('/quizzes/single');
      return QuizModel.fromJson(response.data['data'] ?? response.data);
    } catch (_) {
      return _getMockQuiz();
    }
  }

  // ─────────────────────────────────────────
  // Local progress (SharedPreferences)
  // ─────────────────────────────────────────

  /// Save quiz result after completing
  Future<void> saveQuizResult(int score, String version) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode({
      'has_completed': true,
      'last_score': score,
      'last_version': version,
      'last_attempt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefKeyQuiz, data);
  }

  /// Get saved quiz progress
  Future<QuizProgressRecord> getQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyQuiz);

    if (raw == null) {
      return QuizProgressRecord(hasCompleted: false);
    }

    final data = json.decode(raw) as Map<String, dynamic>;
    return QuizProgressRecord(
      hasCompleted: data['has_completed'] ?? false,
      lastScore: data['last_score'],
      lastVersion: data['last_version'],
      lastAttempt: data['last_attempt'] != null
          ? DateTime.tryParse(data['last_attempt'])
          : null,
    );
  }

  // ─────────────────────────────────────────
  // Mission Tracking (SharedPreferences)
  // ─────────────────────────────────────────

  Future<bool> getMissionNews() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNews) ?? false;
  }

  Future<void> setMissionNews() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNews, true);
  }

  Future<bool> getMissionLkpd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyLkpd) ?? false;
  }

  Future<void> setMissionLkpd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLkpd, true);
  }

  Future<bool> getMissionEmodul() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEmodul) ?? false;
  }

  Future<void> setMissionEmodul() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEmodul, true);
  }

  Future<Map<String, Map<String, bool>>> getMissionPhases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyPhases);
    if (raw == null) return {};

    final Map<String, dynamic> data = json.decode(raw);
    final Map<String, Map<String, bool>> result = {};
    data.forEach((dId, phasesMap) {
      if (phasesMap is Map) {
        result[dId] = phasesMap.map((k, v) => MapEntry(k.toString(), v == true));
      }
    });
    return result;
  }

  Future<void> setMissionPhase(String disasterId, String phase) async {
    final prefs = await SharedPreferences.getInstance();
    final phases = await getMissionPhases();
    
    if (!phases.containsKey(disasterId)) {
      phases[disasterId] = {};
    }
    phases[disasterId]![phase] = true;
    
    await prefs.setString(_prefKeyPhases, json.encode(phases));
  }

  // ─────────────────────────────────────────
  // Mock Data (fallback when API unavailable)
  // ─────────────────────────────────────────

  QuizModel _getMockQuiz() {
    final questions = <QuizQuestion>[];

    // 10 Objective questions
    questions.addAll([
      QuizQuestion(
        id: 'q1', order: 1,
        question: 'Apa yang harus dilakukan pertama kali saat gempa terjadi di dalam ruangan?',
        options: [
          'Berlari keluar gedung secepat mungkin',
          'Berlindung di bawah meja yang kokoh',
          'Berdiri di sudut ruangan',
          'Mengambil barang berharga terlebih dahulu',
        ],
        correctIndex: 1,
        explanation: 'Berlindung di bawah meja kokoh dapat melindungi dari reruntuhan saat gempa.',
      ),
      QuizQuestion(
        id: 'q2', order: 2,
        question: 'Apa kepanjangan dari BMKG?',
        options: [
          'Badan Meteorologi Klimatologi dan Geofisika',
          'Badan Mitigasi Kebencanaan Gempa',
          'Biro Meteorologi dan Kebencanaan Geologi',
          'Badan Manajemen Krisis dan Geofisika',
        ],
        correctIndex: 0,
        explanation: 'BMKG adalah Badan Meteorologi Klimatologi dan Geofisika.',
      ),
      QuizQuestion(
        id: 'q3', order: 3,
        question: 'Banjir termasuk dalam bencana jenis apa?',
        options: [
          'Bencana geologi',
          'Bencana hidrologi',
          'Bencana klimatologi',
          'Bencana astronomi',
        ],
        correctIndex: 1,
        explanation: 'Banjir termasuk bencana hidrologi karena berkaitan dengan air.',
      ),
      QuizQuestion(
        id: 'q4', order: 4,
        question: 'Saat kebakaran hutan terjadi, arah evakuasi yang tepat adalah?',
        options: [
          'Searah arah angin',
          'Melawan arah angin',
          'Menuju ke pusat api',
          'Tetap diam di tempat',
        ],
        correctIndex: 1,
        explanation: 'Bergerak melawan arah angin agar tidak terkena asap dan api yang menyebar.',
      ),
      QuizQuestion(
        id: 'q5', order: 5,
        question: 'Skala apa yang digunakan untuk mengukur kekuatan gempa bumi?',
        options: [
          'Skala Celcius',
          'Skala Beaufort',
          'Skala Richter / Magnitudo',
          'Skala Fujita',
        ],
        correctIndex: 2,
        explanation: 'Kekuatan gempa diukur menggunakan Skala Richter atau Magnitudo Momen (Mw).',
      ),
      QuizQuestion(
        id: 'q6', order: 6,
        question: 'Tanda alami tsunami akan datang setelah gempa di laut adalah?',
        options: [
          'Air laut naik mendadak setinggi 10 meter',
          'Air laut surut tiba-tiba jauh dari pantai',
          'Angin kencang dari arah laut',
          'Warna laut berubah menjadi merah',
        ],
        correctIndex: 1,
        explanation: 'Air laut yang surut tiba-tiba adalah tanda bahaya tsunami.',
      ),
      QuizQuestion(
        id: 'q7', order: 7,
        question: 'Wilayah yang paling rawan tanah longsor adalah?',
        options: [
          'Dataran rendah dekat sungai',
          'Lereng bukit curam dengan tanah labil',
          'Pantai berpasir',
          'Padang rumput datar',
        ],
        correctIndex: 1,
        explanation: 'Lereng curam dengan tanah labil sangat rentan longsor.',
      ),
      QuizQuestion(
        id: 'q8', order: 8,
        question: 'Tas siaga bencana sebaiknya diperiksa ulang setiap?',
        options: [
          'Setiap hari',
          'Setiap minggu',
          'Setiap 6 bulan sekali',
          'Setiap 5 tahun sekali',
        ],
        correctIndex: 2,
        explanation: 'Tas siaga harus diperiksa setiap 6 bulan agar item masih layak pakai.',
      ),
      QuizQuestion(
        id: 'q9', order: 9,
        question: 'Awan panas dari letusan gunung disebut?',
        options: [
          'Lahar dingin',
          'Wedhus gembel (awan panas)',
          'Lava basalt',
          'Fumarol',
        ],
        correctIndex: 1,
        explanation: 'Awan panas atau "wedhus gembel" sangat berbahaya.',
      ),
      QuizQuestion(
        id: 'q10', order: 10,
        question: 'Masker apa yang paling efektif melindungi dari abu vulkanik?',
        options: [
          'Masker kain biasa',
          'Masker N95 atau respirator',
          'Sapu tangan basah',
          'Tidak perlu masker',
        ],
        correctIndex: 1,
        explanation: 'Masker N95 paling efektif melawan abu vulkanik.',
      ),
    ]);

    // 5 True/False questions
    questions.addAll([
      QuizQuestion(
        id: 'tf1', order: 11,
        question: 'Banjir hanya terjadi di musim hujan.',
        options: ['Benar', 'Salah'],
        correctIndex: 1,
        explanation: 'Banjir bisa terjadi kapan saja, misalnya akibat jebolnya tanggul.',
      ),
      QuizQuestion(
        id: 'tf2', order: 12,
        question: 'Saat gempa terjadi, kita harus segera berlari keluar gedung.',
        options: ['Benar', 'Salah'],
        correctIndex: 1,
        explanation: 'Berlindung dulu di bawah meja, baru keluar setelah guncangan berhenti.',
      ),
      QuizQuestion(
        id: 'tf3', order: 13,
        question: 'Kebakaran hutan dapat menyebabkan polusi udara yang berbahaya.',
        options: ['Benar', 'Salah'],
        correctIndex: 0,
        explanation: 'Asap kebakaran hutan mengandung partikel berbahaya bagi pernapasan.',
      ),
      QuizQuestion(
        id: 'tf4', order: 14,
        question: 'Tsunami hanya bisa terjadi setelah gempa bumi.',
        options: ['Benar', 'Salah'],
        correctIndex: 1,
        explanation: 'Tsunami juga bisa disebabkan oleh longsor bawah laut atau letusan gunung.',
      ),
      QuizQuestion(
        id: 'tf5', order: 15,
        question: 'Menanam pohon di lereng bukit dapat mencegah tanah longsor.',
        options: ['Benar', 'Salah'],
        correctIndex: 0,
        explanation: 'Akar tanaman membantu mengikat tanah dan mengurangi risiko longsor.',
      ),
    ]);

    return QuizModel(
      id: 'mock_quiz_1',
      title: 'Evaluasi Bencana',
      description: 'Uji pemahamanmu tentang berbagai bencana alam dan cara menghadapinya.',
      totalQuestions: questions.length,
      passingScore: 70,
      questions: questions,
      updatedAt: DateTime(2025, 4, 20),
      version: '1.0',
    );
  }
}
