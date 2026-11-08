import 'dart:io';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'game_controller.dart';
import 'game_data.dart';
import 'models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _name = TextEditingController(text: 'Player');
  final _ip = TextEditingController();
  final _controller = GameController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _ip.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String> _getIp() async {
    try {
      final info = NetworkInfo();
      final wifi = await info.getWifiIP();
      if (wifi != null && wifi.isNotEmpty) return wifi;
    } catch (_) {}
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback && address.address.startsWith('192.168.')) return address.address;
          if (!address.isLoopback && address.address.startsWith('10.')) return address.address;
        }
      }
    } catch (_) {}
    return 'IP introuvable';
  }

  Future<void> _host() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final ip = await _getIp();
      final code = await _controller.createRoom(_name.text, ip);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(controller: _controller, isHost: true, hostIp: ip)));
    } catch (e) {
      _message('Impossible de créer la salle : $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    if (_name.text.trim().isEmpty || _ip.text.trim().isEmpty) {
      _message('Saisissez un pseudonyme et l’adresse IP de l’hôte.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _controller.joinRoom(_name.text, _ip.text);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(controller: _controller, isHost: false)));
    } catch (e) {
      _message('Connexion impossible : vérifiez le Wi-Fi et l’adresse IP. ($e)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 26),
            const Icon(Icons.extension_rounded, size: 76, color: Color(0xFF6750A4)),
            const SizedBox(height: 12),
            Text('GUESS THE WORD', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('Learn English. Play together.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 34),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Votre pseudonyme', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _busy ? null : _host, icon: const Icon(Icons.wifi_tethering), label: const Text('Créer une salle Wi-Fi'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(17))),
            const SizedBox(height: 22),
            const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OU REJOINDRE')), Expanded(child: Divider())]),
            const SizedBox(height: 18),
            TextField(controller: _ip, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Adresse IP de l’hôte', hintText: 'Ex. 192.168.1.25', prefixIcon: Icon(Icons.router))),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _busy ? null : _join, icon: const Icon(Icons.login), label: const Text('Rejoindre la salle'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(17))),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 18), child: Center(child: CircularProgressIndicator())),
            const SizedBox(height: 24),
            const Text('Tous les téléphones doivent être connectés au même réseau Wi-Fi.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeScreen())), child: const Text('S’entraîner seul')),
          ],
        )),
      ))),
    );
  }
}

class GameScreen extends StatefulWidget {
  final GameController controller;
  final bool isHost;
  final String? hostIp;
  const GameScreen({super.key, required this.controller, required this.isHost, this.hostIp});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _answer = TextEditingController();
  @override
  void dispose() { _answer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final s = widget.controller.state;
        return Scaffold(
          appBar: AppBar(title: const Text('GUESS THE WORD'), actions: [
            IconButton(onPressed: () => _showRules(context), icon: const Icon(Icons.help_outline)),
          ]),
          body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
            _roomCard(s),
            const SizedBox(height: 14),
            if (!s.started && !s.finished) _lobby(s),
            if (s.started && !s.finished) _playing(s),
            if (s.finished) _results(s),
          ])),
        );
      },
    );
  }

  Widget _roomCard(GameSnapshot s) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    const Icon(Icons.wifi, color: Color(0xFF6750A4)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Salle ${s.roomCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
      if (widget.isHost) Text('IP : ${widget.hostIp ?? "inconnue"} :4040', style: const TextStyle(color: Colors.black54)),
    ])),
    Text('${s.players.length} joueur(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
  ])));

  Widget _lobby(GameSnapshot s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const SizedBox(height: 12),
    Text('Salle d’attente', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    ...s.players.map((p) => Card(child: ListTile(leading: CircleAvatar(child: Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase())), title: Text(p.name), trailing: p.isHost ? const Chip(label: Text('Hôte')) : null))),
    const SizedBox(height: 16),
    if (widget.isHost)
      FilledButton.icon(onPressed: s.players.length >= 1 ? () => widget.controller.startGame() : null, icon: const Icon(Icons.play_arrow), label: const Text('Démarrer la partie'), style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)))
    else
      const Center(child: Padding(padding: EdgeInsets.all(20), child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('En attente du démarrage par l’hôte…')]))),
  ]);

  Widget _playing(GameSnapshot s) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Question ${s.questionNumber}/${s.totalQuestions}', style: const TextStyle(fontWeight: FontWeight.bold)),
      Chip(avatar: const Icon(Icons.timer_outlined, size: 18), label: Text('${s.secondsLeft}s')),
    ]),
    const SizedBox(height: 10),
    LinearProgressIndicator(value: s.secondsLeft / 30, minHeight: 8, borderRadius: BorderRadius.circular(8)),
    const SizedBox(height: 24),
    Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 16), child: Column(children: [
      Text(s.question?.emojis ?? '❔', textAlign: TextAlign.center, style: const TextStyle(fontSize: 66)),
      const SizedBox(height: 14),
      Text('GUESS THE WORD!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      Text('${s.question?.level ?? ""} • ${s.question?.category ?? ""}', style: const TextStyle(color: Colors.black54)),
    ]))),
    const SizedBox(height: 16),
    TextField(controller: _answer, textInputAction: TextInputAction.send, onSubmitted: _send,
      enabled: !s.revealAnswer, decoration: InputDecoration(labelText: 'Votre réponse en anglais', suffixIcon: IconButton(onPressed: s.revealAnswer ? null : _send, icon: const Icon(Icons.send)))),
    const SizedBox(height: 8),
    if (s.feedback != null) Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEDE7F6), borderRadius: BorderRadius.circular(14)), child: Text(s.feedback!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
    if (s.revealAnswer && s.question != null) Padding(padding: const EdgeInsets.only(top: 12), child: Column(children: [
      Text('Réponse : ${s.question!.answer}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text('${s.question!.translation} — ${s.question!.definition}', textAlign: TextAlign.center),
      Text('Example: ${s.question!.example}', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
    ])),
    const SizedBox(height: 20),
    Text('Classement', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    ..._sorted(s.players).asMap().entries.map((e) => _scoreTile(e.key + 1, e.value)),
  ]);

  void _send([String? value]) {
    final text = value ?? _answer.text;
    if (text.trim().isEmpty) return;
    widget.controller.submitAnswer(text);
    _answer.clear();
  }

  List<Player> _sorted(List<Player> players) => [...players]..sort((a,b) => b.score.compareTo(a.score));
  Widget _scoreTile(int rank, Player p) => Card(child: ListTile(leading: CircleAvatar(child: Text('$rank')), title: Text(p.name), trailing: Text('${p.score} pts', style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _results(GameSnapshot s) {
    final players = _sorted(s.players);
    final winner = players.isEmpty ? null : players.first;
    return Column(children: [
      const SizedBox(height: 24),
      const Text('🏆', style: TextStyle(fontSize: 76)),
      Text('PARTIE TERMINÉE', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      if (winner != null) Text('Gagnant : ${winner.name}', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 18),
      ...players.asMap().entries.map((e) => _scoreTile(e.key + 1, e.value)),
      const SizedBox(height: 18),
      FilledButton(onPressed: widget.isHost ? () => widget.controller.startGame() : null, child: const Text('Rejouer')),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Quitter la salle')),
    ]);
  }

  void _showRules(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(
    title: const Text('Comment jouer ?'),
    content: const Text('Devinez le mot anglais représenté par les émojis. Le premier joueur qui trouve gagne 100 points et un bonus de rapidité. Après chaque question, découvrez la traduction et une définition en anglais.'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Compris'))],
  ));
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});
  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _index = 0;
  bool _show = false;
  final _answer = TextEditingController();
  @override
  void dispose() { _answer.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final q = questionBank[_index % questionBank.length];
    return Scaffold(appBar: AppBar(title: const Text('Entraînement solo')), body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Question ${_index + 1}', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 24),
      Card(child: Padding(padding: const EdgeInsets.all(36), child: Text(q.emojis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 68)))),
      const SizedBox(height: 16),
      TextField(controller: _answer, decoration: const InputDecoration(labelText: 'Mot en anglais')),
      const SizedBox(height: 12),
      FilledButton(onPressed: () => setState(() => _show = true), child: const Text('Vérifier')),
      if (_show) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(q.answer, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(q.translation),
        Text(q.definition, textAlign: TextAlign.center),
        Text('Example: ${q.example}', style: const TextStyle(fontStyle: FontStyle.italic)),
      ]))),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: () { setState(() { _index++; _show = false; _answer.clear(); }); }, child: const Text('Question suivante')),
    ]));
  }
}
