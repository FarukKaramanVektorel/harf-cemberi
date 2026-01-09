import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class ResultScreen extends StatefulWidget {
  final int currentScore;
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final int timeUsedSeconds;

  const ResultScreen({
    super.key,
    required this.currentScore,
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.timeUsedSeconds,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  int bestScore = 0;
  bool isNewRecord = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_animController);
    
    _loadAndCompareBestScore();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAndCompareBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBestScore = prefs.getInt('bestScore') ?? 0;
    
    setState(() {
      bestScore = savedBestScore;
    });

    // Check if new record
    if (widget.currentScore > savedBestScore) {
      await prefs.setInt('bestScore', widget.currentScore);
      setState(() {
        bestScore = widget.currentScore;
        isNewRecord = true;
      });
    }

    _animController.forward();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}dk ${secs}sn';
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalQuestions > 0
        ? ((widget.correctCount / widget.totalQuestions) * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with icon
                  if (isNewRecord) ...[
                    const Icon(Icons.emoji_events, color: Colors.amber, size: 64),
                    const SizedBox(height: 8),
                    const Text(
                      '🎉 YENİ REKOR! 🎉',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.sports_score, color: Colors.blue, size: 64),
                    const SizedBox(height: 8),
                    const Text(
                      'Oyun Bitti!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Score Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isNewRecord ? Colors.amber : Colors.blue,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isNewRecord ? Colors.amber : Colors.blue).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Current Score
                        const Text(
                          'SKORUNUZ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white54,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.currentScore}',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: isNewRecord ? Colors.amber : Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        
                        // Best Score
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'En İyi Skor: $bestScore',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.amber,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        icon: Icons.check_circle,
                        color: Colors.green,
                        label: 'Doğru',
                        value: '${widget.correctCount}',
                      ),
                      _buildStatCard(
                        icon: Icons.cancel,
                        color: Colors.red,
                        label: 'Yanlış',
                        value: '${widget.wrongCount}',
                      ),
                      _buildStatCard(
                        icon: Icons.percent,
                        color: Colors.blue,
                        label: 'Başarı',
                        value: '$accuracy%',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16213E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white54),
                        const SizedBox(width: 8),
                        Text(
                          'Süre: ${_formatTime(widget.timeUsedSeconds)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Play Again Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const GameScreen()),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 28),
                      label: const Text(
                        'Tekrar Oyna',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
