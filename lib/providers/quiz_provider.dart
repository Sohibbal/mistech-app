import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/quiz_repository.dart';

enum QuizLoadState { idle, loading, loaded, error }

class QuizProvider extends ChangeNotifier {
  final QuizRepository _repo = QuizRepository();
  final ApiClient _client = ApiClient.instance;

  QuizLoadState _quizState = QuizLoadState.idle;

  QuizModel? _currentQuiz;
  QuizProgressRecord? _progress;

  // Active quiz session state
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {}; // question index → selected option index
  bool _isSubmitted = false;
  QuizResult? _lastResult;
  bool _isNewsOpened = false;
  bool _isLkpdOpened = false;
  bool _isEmodulOpened = false;
  Map<String, Map<String, bool>> _missionPhases = {};
  final Set<int> _checkedQuestions = {}; // questions that have been "Checked" by user
  // Getters
  QuizLoadState get quizState => _quizState;
  QuizModel? get currentQuiz => _currentQuiz;
  QuizProgressRecord? get progress => _progress;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  bool get isSubmitted => _isSubmitted;
  QuizResult? get lastResult => _lastResult;
  Set<int> get checkedQuestions => _checkedQuestions;

  bool isQuestionChecked(int index) => _checkedQuestions.contains(index);

  bool get isLoading => _quizState == QuizLoadState.loading;

  int? getSelectedAnswer(int index) => _selectedAnswers[index];
  bool get isAllAnswered =>
      _currentQuiz != null &&
      _selectedAnswers.length == _currentQuiz!.questions.length;

  bool get hasCompleted => _progress?.hasCompleted ?? false;
  int? get lastScore => _progress?.lastScore;

  bool get isNewsOpened => _isNewsOpened;
  bool get isLkpdOpened => _isLkpdOpened;
  bool get isEmodulOpened => _isEmodulOpened;
  Map<String, Map<String, bool>> get missionPhases => _missionPhases;

  // ─────────────────────────────────────────
  // Data Loading
  // ─────────────────────────────────────────

  Future<void> loadQuiz() async {
    _quizState = QuizLoadState.loading;
    resetSession();
    notifyListeners();

    try {
      _currentQuiz = await _repo.getQuiz();
      _progress = await _repo.getQuizProgress();
      await loadMissions();
      _quizState = QuizLoadState.loaded;
    } catch (e) {
      _quizState = QuizLoadState.error;
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // Quiz Session
  Future<void> loadMissions() async {
    _isNewsOpened = await _repo.getMissionNews();
    _isLkpdOpened = await _repo.getMissionLkpd();
    _isEmodulOpened = await _repo.getMissionEmodul();
    _missionPhases = await _repo.getMissionPhases();
    notifyListeners();
  }

  Future<void> markNewsOpened() async {
    if (_isNewsOpened) return;
    await _repo.setMissionNews();
    _isNewsOpened = true;
    notifyListeners();
  }

  Future<void> markLkpdOpened() async {
    if (_isLkpdOpened) return;
    await _repo.setMissionLkpd();
    _isLkpdOpened = true;
    notifyListeners();
  }

  Future<void> markEmodulOpened() async {
    if (_isEmodulOpened) return;
    await _repo.setMissionEmodul();
    _isEmodulOpened = true;
    notifyListeners();
  }

  Future<void> markPhaseCompleted(String disasterId, String phase) async {
    await _repo.setMissionPhase(disasterId, phase);
    if (!_missionPhases.containsKey(disasterId)) {
      _missionPhases[disasterId] = {};
    }
    _missionPhases[disasterId]![phase] = true;
    notifyListeners();
  }

  // ─────────────────────────────────────────

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_isSubmitted || _checkedQuestions.contains(questionIndex)) return;
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
  }

  bool checkAnswer(int questionIndex) {
    if (_currentQuiz == null) return false;
    final q = _currentQuiz!.questions[questionIndex];
    final selected = _selectedAnswers[questionIndex];
    
    if (selected == null) return false;
    
    _checkedQuestions.add(questionIndex);
    notifyListeners();
    return selected == q.correctIndex;
  }

  void goToQuestion(int index) {
    if (_currentQuiz == null) return;
    if (index < 0 || index >= _currentQuiz!.questions.length) return;
    _currentQuestionIndex = index;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuiz == null) return;
    if (_currentQuestionIndex < _currentQuiz!.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<QuizResult> submitQuiz() async {
    if (_currentQuiz == null) throw Exception('No active quiz');

    int correct = 0;
    final answers = <QuizAnswerRecord>[];

    for (int i = 0; i < _currentQuiz!.questions.length; i++) {
      final q = _currentQuiz!.questions[i];
      final selected = _selectedAnswers[i] ?? -1;
      final isCorrect = selected == q.correctIndex;
      if (isCorrect) correct++;
      answers.add(QuizAnswerRecord(
        questionId: q.id,
        selectedIndex: selected,
        correctIndex: q.correctIndex,
        isCorrect: isCorrect,
      ));
    }

    final result = QuizResult(
      quizId: _currentQuiz!.id,
      totalQuestions: _currentQuiz!.questions.length,
      correctAnswers: correct,
      answers: answers,
      completedAt: DateTime.now(),
    );

    _isSubmitted = true;
    _lastResult = result;

    // Persist result locally
    await _repo.saveQuizResult(
      result.scorePercent,
      _currentQuiz!.version,
    );

    // Send result to API
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentName = prefs.getString('user_name') ?? 'Anonim';
      
      final answersPayload = answers.map((a) => {
        "question_id": a.questionId,
        "is_correct": a.isCorrect,
      }).toList();

      await _client.post('/quiz-attempts', data: {
        "quiz_id": _currentQuiz!.id,
        "student_name": studentName,
        "type": "evaluation",
        "score": result.scorePercent,
        "total_questions": result.totalQuestions,
        "answers": answersPayload,
      });
    } catch (e) {
      debugPrint("Failed to submit evaluation to server: $e");
    }

    // Refresh progress
    _progress = await _repo.getQuizProgress();

    notifyListeners();
    return result;
  }

  void resetSession() {
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    _checkedQuestions.clear();
    _isSubmitted = false;
    _lastResult = null;
  }

  // ─────────────────────────────────────────
  // Quiz Updated Badge
  // ─────────────────────────────────────────

  /// Returns true if the quiz version has changed since last attempt
  bool get isQuizUpdated {
    if (_progress == null || !_progress!.hasCompleted) return false;
    if (_currentQuiz == null) return false;
    return _progress!.lastVersion != _currentQuiz!.version;
  }
}
