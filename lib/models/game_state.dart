import 'package:flutter/material.dart';
import '../models/letter_state.dart';
import '../utils/words.dart';
import '../services/word_service.dart';

enum GameStatus { loading, ready, error, inProgress, won, lost }

class GameState extends ChangeNotifier {
  // late String targetWord;
  String targetWord = '';
  final List<String> guesses;
  final List<List<LetterState>> evaluations;
  String currentGuess;
  GameStatus status;
  String? errorMessage;
  final Map<String, LetterState> letterStates;
  DateTime lastUpdated;
  bool hasPlayedToday;

  GameState()
      : guesses = [],
        evaluations = [],
        currentGuess = '',
        status = GameStatus.loading,
        letterStates = {},
        lastUpdated = DateTime.now(),
        hasPlayedToday = false {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      status = GameStatus.loading;
      notifyListeners();

      // Check if we already have today's word and it's still valid
      if (_shouldRefreshWord()) {
        targetWord = await WordService.getTodaysWord();
        lastUpdated = DateTime.now();
        hasPlayedToday = false;
        _resetGame();
      }

      // Load or refresh word list
      if (WordList.validWords.isEmpty) {
        final wordList = await WordService.getWordList();
        WordList.validWords = wordList;
      }

      status = GameStatus.ready;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing game: $e');
      // Fallback to local word list if API fails
      targetWord = WordList.getRandomWord().toUpperCase();
      status = GameStatus.ready;
      errorMessage = 'Using offline mode';
      notifyListeners();
    }
  }

  bool _shouldRefreshWord() {
    if (targetWord.isEmpty) return true;

    final now = DateTime.now();
    final lastUpdateDate = DateTime(
      lastUpdated.year,
      lastUpdated.month,
      lastUpdated.day,
    );
    final today = DateTime(now.year, now.month, now.day);

    return lastUpdateDate.isBefore(today);
  }

  void _resetGame() {
    guesses.clear();
    evaluations.clear();
    currentGuess = '';
    letterStates.clear();
    status = GameStatus.ready;
    errorMessage = null;
    notifyListeners();
  }

  bool get gameOver => status == GameStatus.won || status == GameStatus.lost;

  bool get canSubmit =>
      currentGuess.length == 5 &&
      WordList.validWords.contains(currentGuess.toLowerCase());

  Future<void> submitGuess() async {
    if (currentGuess.length != 5 || gameOver) return;

    if (!WordList.validWords.contains(currentGuess.toLowerCase())) {
      errorMessage = 'Not in word list';
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
      errorMessage = null;
      notifyListeners();
      return;
    }

    final evaluation = List<LetterState>.filled(5, LetterState.absent);
    final targetLetterCount = <String, int>{};

    // Count target letters
    for (var i = 0; i < targetWord.length; i++) {
      targetLetterCount[targetWord[i]] =
          (targetLetterCount[targetWord[i]] ?? 0) + 1;
    }

    // First pass: mark correct letters
    for (var i = 0; i < currentGuess.length; i++) {
      if (currentGuess[i] == targetWord[i]) {
        evaluation[i] = LetterState.correct;
        targetLetterCount[currentGuess[i]] =
            targetLetterCount[currentGuess[i]]! - 1;
      }
    }

    // Second pass: mark present letters
    for (var i = 0; i < currentGuess.length; i++) {
      if (evaluation[i] != LetterState.correct) {
        // if (targetLetterCount[currentGuess[i]] ?? 0 > 0) {
        //   evaluation[i] = LetterState.present;
        //   targetLetterCount[currentGuess[i]] =
        //       targetLetterCount[currentGuess[i]]! - 1;
        // }
        if ((targetLetterCount[currentGuess[i]] ?? 0) > 0) {
          evaluation[i] = LetterState.present;
          targetLetterCount[currentGuess[i]] =
              (targetLetterCount[currentGuess[i]] ?? 0) - 1;
        }
      }
    }

    // Update letter states
    for (var i = 0; i < currentGuess.length; i++) {
      final letter = currentGuess[i];
      final currentState = letterStates[letter];
      final newState = evaluation[i];

      if (currentState == null || newState.index > currentState.index) {
        letterStates[letter] = newState;
      }
    }

    guesses.add(currentGuess);
    evaluations.add(evaluation);
    currentGuess = '';

    // Update game status
    if (guesses.last == targetWord) {
      status = GameStatus.won;
      hasPlayedToday = true;
      _saveGameState();
    } else if (guesses.length >= 6) {
      status = GameStatus.lost;
      hasPlayedToday = true;
      _saveGameState();
    }

    notifyListeners();
  }

  void addLetter(String letter) {
    if (currentGuess.length < 5 && !gameOver) {
      currentGuess += letter;
      notifyListeners();
    }
  }

  void removeLetter() {
    if (currentGuess.isNotEmpty && !gameOver) {
      currentGuess = currentGuess.substring(0, currentGuess.length - 1);
      notifyListeners();
    }
  }

  Future<void> _saveGameState() async {
    // Here you can implement persistence logic
    // e.g., save to SharedPreferences or local database
  }

  String getShareableResult() {
    if (!gameOver) return '';

    final timestamp = DateTime.now().toIso8601String().split('T')[0];
    final buffer = StringBuffer();
    buffer.writeln('Wordle $timestamp ${guesses.length}/6');
    buffer.writeln();

    for (final evaluation in evaluations) {
      for (final state in evaluation) {
        switch (state) {
          case LetterState.correct:
            buffer.write('🟩');
            break;
          case LetterState.present:
            buffer.write('🟨');
            break;
          case LetterState.absent:
            buffer.write('⬜');
            break;
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<void> restartGame() async {
    if (!hasPlayedToday) {
      _resetGame();
    }
  }

  // Statistics getters
  int get currentStreak => 0; // Implement streak logic
  int get maxStreak => 0; // Implement max streak logic
  int get gamesPlayed => 0; // Implement games played logic
  int get winPercentage => 0; // Implement win percentage logic
  Map<int, int> get guessDistribution =>
      {}; // Implement guess distribution logic
}
