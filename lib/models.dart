class GameQuestion {
  final String id;
  final String answer;
  final String emojis;
  final String translation;
  final String definition;
  final String example;
  final String level;
  final String category;
  final List<String> hints;

  const GameQuestion({
    required this.id,
    required this.answer,
    required this.emojis,
    required this.translation,
    required this.definition,
    required this.example,
    required this.level,
    required this.category,
    required this.hints,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'answer': answer, 'emojis': emojis, 'translation': translation,
    'definition': definition, 'example': example, 'level': level,
    'category': category, 'hints': hints,
  };

  factory GameQuestion.fromJson(Map<String, dynamic> json) => GameQuestion(
    id: json['id'] as String,
    answer: json['answer'] as String,
    emojis: json['emojis'] as String,
    translation: json['translation'] as String,
    definition: json['definition'] as String,
    example: json['example'] as String,
    level: json['level'] as String,
    category: json['category'] as String,
    hints: List<String>.from(json['hints'] as List? ?? const []),
  );
}

class Player {
  final String id;
  final String name;
  final int score;
  final bool isHost;

  const Player({required this.id, required this.name, this.score = 0, this.isHost = false});

  Player copyWith({String? name, int? score, bool? isHost}) =>
      Player(id: id, name: name ?? this.name, score: score ?? this.score, isHost: isHost ?? this.isHost);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'score': score, 'isHost': isHost};

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    score: (json['score'] as num?)?.toInt() ?? 0,
    isHost: json['isHost'] as bool? ?? false,
  );
}

class GameSnapshot {
  final String roomCode;
  final List<Player> players;
  final GameQuestion? question;
  final int questionNumber;
  final int totalQuestions;
  final int secondsLeft;
  final bool started;
  final bool finished;
  final String? lastWinner;
  final String? feedback;
  final bool revealAnswer;

  const GameSnapshot({
    required this.roomCode,
    required this.players,
    this.question,
    this.questionNumber = 0,
    this.totalQuestions = 10,
    this.secondsLeft = 30,
    this.started = false,
    this.finished = false,
    this.lastWinner,
    this.feedback,
    this.revealAnswer = false,
  });

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'players': players.map((p) => p.toJson()).toList(),
    'question': question?.toJson(),
    'questionNumber': questionNumber,
    'totalQuestions': totalQuestions,
    'secondsLeft': secondsLeft,
    'started': started,
    'finished': finished,
    'lastWinner': lastWinner,
    'feedback': feedback,
    'revealAnswer': revealAnswer,
  };

  factory GameSnapshot.fromJson(Map<String, dynamic> json) => GameSnapshot(
    roomCode: json['roomCode'] as String? ?? 'LOCAL',
    players: (json['players'] as List? ?? const [])
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    question: json['question'] == null
        ? null : GameQuestion.fromJson(Map<String, dynamic>.from(json['question'] as Map)),
    questionNumber: (json['questionNumber'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 10,
    secondsLeft: (json['secondsLeft'] as num?)?.toInt() ?? 30,
    started: json['started'] as bool? ?? false,
    finished: json['finished'] as bool? ?? false,
    lastWinner: json['lastWinner'] as String?,
    feedback: json['feedback'] as String?,
    revealAnswer: json['revealAnswer'] as bool? ?? false,
  );
}
