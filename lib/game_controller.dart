import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'game_data.dart';
import 'lan_service.dart';
import 'models.dart';

class GameController extends ChangeNotifier {
  final LanService lan = LanService();
  GameSnapshot state = const GameSnapshot(roomCode: 'LOCAL', players: []);
  bool isHost = false;
  bool isClient = false;
  String myId = '';
  String myName = '';
  String? localIp;
  Timer? _timer;
  int _questionIndex = 0;
  final Set<String> _answered = {};

  GameController() {
    lan.onMessage = _handleMessage;
    lan.onClientConnected = (_) => _publish();
    lan.onClientDisconnected = (id) {
      if (!isHost) return;
      state = GameSnapshot(
        roomCode: state.roomCode,
        players: state.players.where((p) => p.id != id).toList(),
        question: state.question,
        questionNumber: state.questionNumber,
        totalQuestions: state.totalQuestions,
        secondsLeft: state.secondsLeft,
        started: state.started,
        finished: state.finished,
        lastWinner: state.lastWinner,
        feedback: state.feedback,
        revealAnswer: state.revealAnswer,
      );
      _publish();
    };
  }

  Future<String> createRoom(String name, String ip) async {
    await lan.stop();
    isHost = true;
    isClient = false;
    myName = name.trim();
    myId = 'host';
    localIp = ip;
    final code = (1000 + Random().nextInt(9000)).toString();
    state = GameSnapshot(roomCode: code, players: [Player(id: myId, name: myName, isHost: true)]);
    await lan.startHost();
    _publish();
    return code;
  }

  Future<void> joinRoom(String name, String ip) async {
    isHost = false;
    isClient = true;
    myName = name.trim();
    myId = DateTime.now().microsecondsSinceEpoch.toString();
    await lan.joinHost(ip);
    lan.sendToHost({'type': 'join', 'name': myName, 'id': myId});
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'];
    if (isHost) {
      if (type == 'join') {
        final id = msg['_clientId'] as String? ?? msg['id'] as String;
        final name = (msg['name'] as String? ?? 'Player').trim();
        if (!state.players.any((p) => p.id == id)) {
          state = _copy(players: [...state.players, Player(id: id, name: name)]);
          _publish();
        }
      } else if (type == 'answer') {
        _submitAnswer(msg['_clientId'] as String? ?? '', msg['answer'] as String? ?? '');
      }
      return;
    }
    if (type == 'snapshot') {
      state = GameSnapshot.fromJson(Map<String, dynamic>.from(msg['state'] as Map));
      final me = state.players.where((p) => p.name == myName).firstOrNull;
      if (me != null) myId = me.id;
      notifyListeners();
    } else if (type == 'private_feedback') {
      state = _copy(feedback: msg['message'] as String? ?? '');
      notifyListeners();
    }
  }

  GameSnapshot _copy({
    List<Player>? players, GameQuestion? question, int? questionNumber,
    int? secondsLeft, bool? started, bool? finished, String? lastWinner,
    String? feedback, bool? revealAnswer, bool clearFeedback = false,
  }) => GameSnapshot(
    roomCode: state.roomCode, players: players ?? state.players,
    question: question ?? state.question, questionNumber: questionNumber ?? state.questionNumber,
    totalQuestions: state.totalQuestions, secondsLeft: secondsLeft ?? state.secondsLeft,
    started: started ?? state.started, finished: finished ?? state.finished,
    lastWinner: lastWinner ?? state.lastWinner,
    feedback: clearFeedback ? null : (feedback ?? state.feedback),
    revealAnswer: revealAnswer ?? state.revealAnswer,
  );

  void startGame({int totalQuestions = 10}) {
    if (!isHost || state.players.isEmpty) return;
    _questionIndex = 0;
    state = GameSnapshot(
      roomCode: state.roomCode, players: state.players, totalQuestions: totalQuestions,
      started: true,
    );
    _nextQuestion();
  }

  void _nextQuestion() {
    _timer?.cancel();
    _answered.clear();
    if (_questionIndex >= state.totalQuestions || _questionIndex >= questionBank.length) {
      state = _copy(finished: true, started: false, question: null, secondsLeft: 0, revealAnswer: false);
      _publish();
      return;
    }
    final q = questionBank[_questionIndex];
    state = _copy(question: q, questionNumber: _questionIndex + 1, secondsLeft: 30,
      lastWinner: null, feedback: null, revealAnswer: false);
    _publish();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsLeft <= 1) {
        timer.cancel();
        state = _copy(secondsLeft: 0, revealAnswer: true, feedback: 'Time is up!');
        _publish();
        Future.delayed(const Duration(seconds: 3), () {
          if (isHost && state.started && !state.finished) {
            _questionIndex++;
            _nextQuestion();
          }
        });
      } else {
        state = _copy(secondsLeft: state.secondsLeft - 1);
        _publish();
      }
    });
  }

  void submitAnswer(String answer) {
    if (!state.started || state.finished || state.question == null || state.revealAnswer) return;
    if (isHost) {
      _submitAnswer(myId, answer);
    } else if (isClient) {
      lan.sendToHost({'type': 'answer', 'answer': answer});
    }
  }

  void _submitAnswer(String playerId, String answer) {
    if (!isHost || playerId.isEmpty || _answered.contains(playerId) || state.question == null) return;
    _answered.add(playerId);
    final normalized = answer.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ');
    final expected = state.question!.answer.toLowerCase();
    if (normalized == expected) {
      final elapsed = 30 - state.secondsLeft;
      final points = 100 + max(0, 50 - elapsed * 2).toInt();
      final updated = state.players.map((p) => p.id == playerId ? p.copyWith(score: p.score + points) : p).toList();
      final winner = updated.where((p) => p.id == playerId).firstOrNull;
      state = _copy(players: updated, lastWinner: winner?.name, feedback: '${winner?.name ?? "Player"} found it! +$points',
        revealAnswer: true);
      _timer?.cancel();
      _publish();
      Future.delayed(const Duration(seconds: 3), () {
        if (isHost && state.started && !state.finished) {
          _questionIndex++;
          _nextQuestion();
        }
      });
    } else {
      _sendPrivateFeedback(playerId, 'Not quite! Try again.');
    }
  }

  void _sendPrivateFeedback(String playerId, String message) {
    if (playerId == myId) {
      state = _copy(feedback: message);
      notifyListeners();
    } else {
      lan.sendToClient(playerId, {'type': 'private_feedback', 'message': message});
    }
  }

  void _publish() {
    notifyListeners();
    if (isHost) lan.broadcast({'type': 'snapshot', 'state': state.toJson()});
  }

  Future<void> disposeGame() async {
    _timer?.cancel();
    await lan.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    lan.stop();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
