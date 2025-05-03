import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

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
      home: const GameScreen(),
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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<MemoryCard> cards = [];
  MemoryCard? firstSelectedCard;
  bool isBusy = false; // To prevent rapid taps

  final List<String> animalEmojis = [
    "🐶", "🐱", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁",
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
    });
  }

  void _onCardTapped(MemoryCard card) async {
    if (isBusy || card.isFaceUp || card.isMatched) return;

    setState(() {
      card.isFaceUp = true;
    });

    if (firstSelectedCard == null) {
      firstSelectedCard = card;
    } else {
      isBusy = true;

      if (firstSelectedCard!.content == card.content) {
        // Match found
        setState(() {
          firstSelectedCard!.isMatched = true;
          card.isMatched = true;
        });
      } else {
        // Not a match
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          firstSelectedCard!.isFaceUp = false;
          card.isFaceUp = false;
        });
      }

      firstSelectedCard = null;
      isBusy = false;
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
      body: Center(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return GestureDetector(
              onTap: () => _onCardTapped(card),
              child: CardTile(card: card),
            );
          },
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
    return Container(
      decoration: BoxDecoration(
        color: card.isFaceUp || card.isMatched ? Colors.white : Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      child: Center(
        child: Text(
          card.isFaceUp || card.isMatched ? card.content : '',
          style: const TextStyle(
            fontSize: 32,
          ),
        ),
      ),
    );
  }
}
