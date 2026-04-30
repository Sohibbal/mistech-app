import 'package:flutter/material.dart';
import '../data/models/quiz_model.dart';
import '../data/repositories/quiz_repository.dart';

enum QuizLoadState { idle, loading, loaded, error }

class QuizProvider extends ChangeNotifier {
  final QuizRepository _repo = QuizRepository();

  QuizLoadState _listState = QuizLoadState.idle;
  QuizLoadState _detailState = QuizLoadState.idle;

  List<QuizModel> _quizzes = [];
  QuizModel? _currentQuiz;
  Map<String, QuizProgressRecord> _progressMap = {};

  // Active quiz session state
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {}; // question index → selected option index
  bool _isSubmitted = false;
  QuizResult? _lastResult;

  // Getters
  QuizLoadState get listState => _listState;
  QuizLoadState get detailState => _detailState;
  List<QuizModel> get quizzes => _quizzes;
  QuizModel? get currentQuiz => _currentQuiz;
  Map<String, QuizProgressRecord> get progressMap => _progressMap;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, int> get selectedAnswers => _selectedAnswers;
  bool get isSubmitted => _isSubmitted;
  QuizResult? get lastResult => _lastResult;

  bool get isListLoading => _listState == QuizLoadState.loading;
  bool get isDetailLoading => _detailState == QuizLoadState.loading;

  int? getSelectedAnswer(int index) => _selectedAnswers[index];
  bool get isAllAnswered =>
      _currentQuiz != null &&
      _selectedAnswers.length == _currentQuiz!.questions.length;

  // ─────────────────────────────────────────
  // Data Loading
  // ─────────────────────────────────────────

  Future<void> loadQuizList() async {
    _listState = QuizLoadState.loading;
    notifyListeners();

    try {
      _quizzes = await _repo.getAllQuizzes();
      // Load all progress records
      for (final q in _quizzes) {
        _progressMap[q.disasterId] = await _repo.getQuizProgress(q.disasterId);
      }
      _listState = QuizLoadState.loaded;
    } catch (e) {
      _listState = QuizLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadQuizDetail(String disasterId) async {
    _detailState = QuizLoadState.loading;
    resetSession();
    notifyListeners();

    try {
      _currentQuiz = await _repo.getQuizByDisaster(disasterId);
      _detailState = QuizLoadState.loaded;
    } catch (e) {
      _detailState = QuizLoadState.error;
    }
    notifyListeners();
  }

  Future<QuizProgressRecord> getProgressForDisaster(String disasterId) async {
    if (_progressMap.containsKey(disasterId)) {
      return _progressMap[disasterId]!;
    }
    final record = await _repo.getQuizProgress(disasterId);
    _progressMap[disasterId] = record;
    return record;
  }

  // ─────────────────────────────────────────
  // Phase completion tracking
  // ─────────────────────────────────────────

  Future<void> markPhaseCompleted(String disasterId, String phase) async {
    await _repo.markPhaseCompleted(disasterId, phase);
    // Refresh progress for this disaster
    _progressMap[disasterId] = await _repo.getQuizProgress(disasterId);
    notifyListeners();
  }

  Future<Map<String, bool>> getPhasesStatus(String disasterId) {
    return _repo.getPhasesStatus(disasterId);
  }

  // ─────────────────────────────────────────
  // Quiz Session
  // ─────────────────────────────────────────

  void selectAnswer(int questionIndex, int optionIndex) {
    if (_isSubmitted) return;
    _selectedAnswers[questionIndex] = optionIndex;
    notifyListeners();
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
      disasterId: _currentQuiz!.disasterId,
      totalQuestions: _currentQuiz!.questions.length,
      correctAnswers: correct,
      answers: answers,
      completedAt: DateTime.now(),
    );

    _isSubmitted = true;
    _lastResult = result;

    // Persist result
    await _repo.saveQuizResult(
      _currentQuiz!.disasterId,
      result.scorePercent,
      _currentQuiz!.version,
    );

    // Refresh progress map
    _progressMap[_currentQuiz!.disasterId] =
        await _repo.getQuizProgress(_currentQuiz!.disasterId);

    notifyListeners();
    return result;
  }

  void resetSession() {
    _currentQuestionIndex = 0;
    _selectedAnswers = {};
    _isSubmitted = false;
    _lastResult = null;
  }

  // ─────────────────────────────────────────
  // Quiz Updated Badge
  // ─────────────────────────────────────────

  /// Returns true if the quiz version has changed since last attempt
  bool isQuizUpdated(QuizModel quiz) {
    final progress = _progressMap[quiz.disasterId];
    if (progress == null || !progress.hasCompleted) return false;
    return progress.lastVersion != quiz.version;
  }
}
