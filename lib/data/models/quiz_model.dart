class QuizModel {
  final String id;
  final String disasterId;
  final String disasterName;
  final String description;
  final int totalQuestions;
  final int passingScore; // minimum score percentage to pass
  final List<QuizQuestion> questions;
  final DateTime? updatedAt;
  final String version; // used to detect if quiz was updated

  QuizModel({
    required this.id,
    required this.disasterId,
    required this.disasterName,
    required this.description,
    required this.totalQuestions,
    required this.passingScore,
    required this.questions,
    this.updatedAt,
    required this.version,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id']?.toString() ?? '',
      disasterId: json['disaster_id']?.toString() ?? '',
      disasterName: json['disaster']?['name'] ?? json['disaster_name'] ?? '',
      description: json['description'] ?? '',
      totalQuestions: json['total_questions'] ?? 0,
      passingScore: json['passing_score'] ?? 70,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromJson(q))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      version: json['version']?.toString() ?? '1',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'disaster_id': disasterId,
        'disaster_name': disasterName,
        'description': description,
        'total_questions': totalQuestions,
        'passing_score': passingScore,
        'questions': questions.map((q) => q.toJson()).toList(),
        'updated_at': updatedAt?.toIso8601String(),
        'version': version,
      };
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options; // A, B, C, D
  final int correctIndex; // 0 = A, 1 = B, 2 = C, 3 = D
  final String? explanation;
  final int order;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.order,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => o['option_text'] as String)
              .toList() ??
          [],
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
        'order': order,
      };
}

class QuizResult {
  final String quizId;
  final String disasterId;
  final int totalQuestions;
  final int correctAnswers;
  final List<QuizAnswerRecord> answers;
  final DateTime completedAt;

  QuizResult({
    required this.quizId,
    required this.disasterId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answers,
    required this.completedAt,
  });

  int get scorePercent =>
      totalQuestions == 0 ? 0 : (correctAnswers * 100 / totalQuestions).round();

  bool get isPassed => scorePercent >= 70;

  String get grade {
    if (scorePercent >= 90) return 'A';
    if (scorePercent >= 80) return 'B';
    if (scorePercent >= 70) return 'C';
    if (scorePercent >= 60) return 'D';
    return 'E';
  }
}

class QuizAnswerRecord {
  final String questionId;
  final int selectedIndex; // -1 = not answered
  final int correctIndex;
  final bool isCorrect;

  QuizAnswerRecord({
    required this.questionId,
    required this.selectedIndex,
    required this.correctIndex,
    required this.isCorrect,
  });
}

/// Tracks which quizzes have been seen vs their current version
/// Used to show "Quiz Updated" badge
class QuizProgressRecord {
  final String disasterId;
  final bool isUnlocked; // true if user completed all 3 phases
  final bool hasCompleted; // true if quiz was taken
  final int? lastScore;
  final String? lastVersion; // version when quiz was last taken
  final DateTime? lastAttempt;

  QuizProgressRecord({
    required this.disasterId,
    required this.isUnlocked,
    required this.hasCompleted,
    this.lastScore,
    this.lastVersion,
    this.lastAttempt,
  });
}
