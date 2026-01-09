import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'result_screen.dart';

/// Base points per correct answer
const int basePointsPerCorrect = 100;

/// Time bonus multiplier (faster = more points)
const int maxTimeBonusSeconds = 600; // 10 minutes max for bonus calculation

/// Turkish alphabet letters constant
const List<String> turkishAlphabet = [
  'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
  'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
  'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
];

/// Letter states for the game
enum LetterState { pending, correct, wrong, current }

class GameScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const GameScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Track state for each letter
  Map<int, LetterState> letterStates = {};
  
  // Questions from database
  List<Question> questions = [];
  bool isLoading = true;
  
  // Current question index
  int currentIndex = 0;

  // Letter pool state
  List<String> letterPool = [];
  List<bool> letterPoolUsed = [];
  List<String?> answerSlots = [];
  List<int?> slotToPoolIndex = [];

  // Animation for wrong answer shake
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Flag to prevent multiple submissions
  bool _isChecking = false;

  // Timer state (counts UP - elapsed time)
  Timer? _gameTimer;
  int _elapsedSeconds = 0;

  // Scoring - will be calculated at the end
  int correctAnswers = 0;

  // Get current question
  Question get currentQuestion => questions[currentIndex];

  // Get the alphabet index for the current question's letter
  int get currentLetterIndex => turkishAlphabet.indexOf(currentQuestion.letter);

  // Format time as MM:SS (elapsed time)
  String get formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Calculate final score with time bonus
  int calculateFinalScore() {
    if (correctAnswers == 0) return 0;
    
    // Base score: 100 points per correct answer
    final baseScore = correctAnswers * basePointsPerCorrect;
    
    // Time bonus: faster completion = higher bonus
    // Max bonus is 50% of base score if completed in under 1 minute
    // Bonus decreases as time increases, reaches 0 at maxTimeBonusSeconds
    final timeFactor = (maxTimeBonusSeconds - _elapsedSeconds).clamp(0, maxTimeBonusSeconds) / maxTimeBonusSeconds;
    final timeBonus = (baseScore * 0.5 * timeFactor).round();
    
    return baseScore + timeBonus;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
    
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final loadedQuestions = await dbHelper.getQuestionsByCategory(widget.categoryId);
      
      setState(() {
        questions = loadedQuestions;
        isLoading = false;
      });
      
      if (questions.isNotEmpty) {
        _initializeGame();
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopTimer() {
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  void _navigateToResult() {
    final correctCount = letterStates.values
        .where((state) => state == LetterState.correct)
        .length;
    final wrongCount = letterStates.values
        .where((state) => state == LetterState.wrong)
        .length;
    
    final finalScore = calculateFinalScore();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          currentScore: finalScore,
          correctCount: correctCount,
          wrongCount: wrongCount,
          totalQuestions: questions.length,
          timeUsedSeconds: _elapsedSeconds,
          categoryId: widget.categoryId,
          categoryName: widget.categoryName,
        ),
      ),
    );
  }

  void _initializeGame() {
    letterStates = {};
    for (int i = 0; i < turkishAlphabet.length; i++) {
      letterStates[i] = LetterState.pending;
    }
    _setupCurrentQuestion();
  }

  void _setupCurrentQuestion() {
    if (questions.isEmpty) return;
    
    // Update letter states
    for (int i = 0; i < turkishAlphabet.length; i++) {
      if (letterStates[i] == LetterState.current) {
        letterStates[i] = LetterState.pending;
      }
    }
    if (currentIndex < questions.length) {
      letterStates[currentLetterIndex] = LetterState.current;
    }

    // Generate letter pool for current question
    letterPool = _generateLetterPool(currentQuestion.answerText);
    letterPoolUsed = List.filled(12, false);
    answerSlots = List.filled(currentQuestion.answerText.length, null);
    slotToPoolIndex = List.filled(currentQuestion.answerText.length, null);
    _isChecking = false;
  }

  List<String> _generateLetterPool(String answer) {
    final random = Random();
    final List<String> pool = answer.toUpperCase().split('');
    
    while (pool.length < 12) {
      final randomLetter = turkishAlphabet[random.nextInt(turkishAlphabet.length)];
      pool.add(randomLetter);
    }
    
    pool.shuffle(random);
    return pool;
  }

  void _onPoolLetterTap(int poolIndex) {
    if (letterPoolUsed[poolIndex] || _isChecking) return;

    final emptySlotIndex = answerSlots.indexWhere((slot) => slot == null);
    if (emptySlotIndex == -1) return;

    setState(() {
      answerSlots[emptySlotIndex] = letterPool[poolIndex];
      slotToPoolIndex[emptySlotIndex] = poolIndex;
      letterPoolUsed[poolIndex] = true;
    });

    if (!answerSlots.contains(null)) {
      _checkAnswer();
    }
  }

  void _onSlotTap(int slotIndex) {
    if (answerSlots[slotIndex] == null || _isChecking) return;

    setState(() {
      final poolIndex = slotToPoolIndex[slotIndex];
      if (poolIndex != null) {
        letterPoolUsed[poolIndex] = false;
      }
      answerSlots[slotIndex] = null;
      slotToPoolIndex[slotIndex] = null;
    });
  }

  void _checkAnswer() async {
    final userAnswer = answerSlots.join();
    final correctAnswer = currentQuestion.answerText.toUpperCase();

    if (userAnswer == correctAnswer) {
      setState(() {
        _isChecking = true;
        letterStates[currentLetterIndex] = LetterState.correct;
        correctAnswers++;
      });

      debugPrint('🔊 Correct! Total: $correctAnswers');

      await Future.delayed(const Duration(seconds: 1));

      if (currentIndex < questions.length - 1) {
        setState(() {
          currentIndex++;
          _setupCurrentQuestion();
        });
      } else {
        _stopTimer();
        _navigateToResult();
      }
    } else {
      _shakeController.forward().then((_) => _shakeController.reset());
      debugPrint('❌ Wrong answer! Try again.');
    }
  }

  void _passQuestion() {
    setState(() {
      letterStates[currentLetterIndex] = LetterState.wrong;
      
      if (currentIndex < questions.length - 1) {
        currentIndex++;
        _setupCurrentQuestion();
      } else {
        _stopTimer();
        _navigateToResult();
      }
    });
  }

  Color _getLetterColor(LetterState state) {
    switch (state) {
      case LetterState.pending:
        return Colors.blue;
      case LetterState.correct:
        return Colors.green;
      case LetterState.wrong:
        return Colors.red;
      case LetterState.current:
        return Colors.yellow;
    }
  }

  Color _getTextColor(LetterState state) {
    switch (state) {
      case LetterState.current:
        return Colors.black87;
      case LetterState.pending:
      case LetterState.correct:
      case LetterState.wrong:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF16213E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.yellow),
              SizedBox(height: 16),
              Text(
                'Sorular yükleniyor...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state if no questions
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          title: Text(widget.categoryName, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF16213E),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Bu kategoride soru bulunamadı!',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri Dön'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${currentIndex + 1}/${questions.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Circle area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final minDimension = min(availableWidth, availableHeight);
                  final circleRadius = minDimension * 0.38;
                  final letterSize = minDimension * 0.09;
                  final fontSize = letterSize * 0.5;

                  return Center(
                    child: SizedBox(
                      width: minDimension,
                      height: minDimension,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Letter circle
                          ...List.generate(turkishAlphabet.length, (index) {
                            final angle = (2 * pi * index / turkishAlphabet.length) - (pi / 2);
                            final x = circleRadius * cos(angle);
                            final y = circleRadius * sin(angle);
                            final state = letterStates[index] ?? LetterState.pending;

                            return Positioned(
                              left: (minDimension / 2) + x - (letterSize / 2),
                              top: (minDimension / 2) + y - (letterSize / 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: letterSize,
                                height: letterSize,
                                decoration: BoxDecoration(
                                  color: _getLetterColor(state),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getLetterColor(state).withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    turkishAlphabet[index],
                                    style: TextStyle(
                                      color: _getTextColor(state),
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          
                          // Center question area with progress indicator
                          SizedBox(
                            width: circleRadius * 1.3,
                            height: circleRadius * 1.3,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Circular progress indicator (question progress)
                                SizedBox(
                                  width: circleRadius * 1.3,
                                  height: circleRadius * 1.3,
                                  child: CircularProgressIndicator(
                                    value: questions.isNotEmpty 
                                        ? (currentIndex + 1) / questions.length 
                                        : 0,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                                // Question container
                                Container(
                                  width: circleRadius * 1.15,
                                  height: circleRadius * 1.15,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16213E),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Timer text (elapsed time)
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: fontSize * 0.9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white70,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      SizedBox(height: circleRadius * 0.03),
                                      // Current letter indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.yellow,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          currentQuestion.letter,
                                          style: TextStyle(
                                            fontSize: fontSize * 1.2,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: circleRadius * 0.05),
                                      // Question text
                                      Flexible(
                                        child: Text(
                                          currentQuestion.questionText,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 3,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: fontSize * 0.55,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Letter Pool Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Answer Slots Row
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value * sin(_shakeController.value * pi * 4), 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(answerSlots.length, (index) {
                        final letter = answerSlots[index];
                        return GestureDetector(
                          onTap: () => _onSlotTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: letter != null 
                                  ? Colors.blue.shade700 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: letter != null 
                                    ? Colors.blue.shade300 
                                    : Colors.white38,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Letter Pool Grid
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(letterPool.length, (index) {
                      final isUsed = letterPoolUsed[index];
                      return GestureDetector(
                        onTap: () => _onPoolLetterTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isUsed 
                                ? Colors.grey.shade800 
                                : Colors.orange.shade600,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isUsed 
                                  ? Colors.grey.shade600 
                                  : Colors.orange.shade300,
                              width: 2,
                            ),
                            boxShadow: isUsed ? [] : [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              letterPool[index],
                              style: TextStyle(
                                color: isUsed ? Colors.grey : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pass Button
                  TextButton.icon(
                    onPressed: _passQuestion,
                    icon: const Icon(
                      Icons.skip_next, 
                      color: Colors.orange,
                    ),
                    label: const Text(
                      'Pas Geç',
                      style: TextStyle(
                        color: Colors.orange, 
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      side: const BorderSide(
                        color: Colors.orange,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
