import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MemoryGameApp());
}

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
      routes: {
        '/game': (context) => const GameScreen(),
        '/results': (context) => const ResultsScreen(),
      },
    );
  }
}

class MemoryCard {
  final int id;
  final String content;
  bool isFaceUp;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.content,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Memory Game',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/game'),
              child: const Text('Start New Game'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/results'),
              child: const Text('Results Table'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<MemoryCard> cards;
  MemoryCard? firstSelectedCard;
  bool isBusy = false;
  int moves = 0;
  final List<String> animalEmojis = [
    "🐶", "🐱", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐭", "🐸", "🐷", "🐮"
  ];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    List<String> contents = List.from(animalEmojis)..addAll(animalEmojis);
    contents.shuffle(Random());
    cards = List.generate(
      contents.length,
          (index) => MemoryCard(id: index, content: contents[index]),
    );
    setState(() {
      firstSelectedCard = null;
      isBusy = false;
      moves = 0;
    });
  }

  Future _saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('game_history') ?? [];
    history.insert(0, '${DateTime.now().toLocal().toString().substring(0, 16)}: $moves moves');
    if (history.length > 10) history = history.sublist(0, 10);
    await prefs.setStringList('game_history', history);
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You win 🥇'),
        content: Text('You completed in $moves moves'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('New Game'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/results');
            },
            child: const Text('Results'),
          ),
        ],
      ),
    );
  }

  void _onCardTapped(MemoryCard card) async {
    if (isBusy || card.isFaceUp || card.isMatched) return;
    setState(() => card.isFaceUp = true);

    if (firstSelectedCard == null) {
      firstSelectedCard = card;
    } else {
      isBusy = true;
      moves++;
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        if (firstSelectedCard!.content == card.content) {
          firstSelectedCard!.isMatched = true;
          card.isMatched = true;
        } else {
          firstSelectedCard!.isFaceUp = false;
          card.isFaceUp = false;
        }
        firstSelectedCard = null;
        isBusy = false;
      });
      if (cards.every((c) => c.isMatched)) {
        await _saveResult();
        _showGameOverDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewGame,
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () => _onCardTapped(cards[index]),
          child: CardTile(card: cards[index]),
        ),
      ),
    );
  }
}

class CardTile extends StatelessWidget {
  final MemoryCard card;
  const CardTile({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: card.isFaceUp || card.isMatched ? Colors.white : Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            card.isFaceUp || card.isMatched ? card.content : '',
            style: const TextStyle(fontSize: 32),
            key: ValueKey(card.isFaceUp),
          ),
        ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  Future<List<String>> _loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('game_history') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results Table')),
      body: FutureBuilder<List<String>>(
        future: _loadResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(child: Text('No saved results'));
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) => ListTile(
              leading: Text('${index + 1}.'),
              title: Text(results[index]),
            ),
          );
        },
      ),
    );
  }
}
