import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class Question {
  final int id;
  final String letter;
  final String questionText;
  final String answerText;

  const Question({
    required this.id,
    required this.letter,
    required this.questionText,
    required this.answerText,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      letter: map['letter'] as String,
      questionText: map['questionText'] as String,
      answerText: map['answerText'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'letter': letter,
      'questionText': questionText,
      'answerText': answerText,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // In-memory questions for web platform
  static List<Question>? _webQuestions;

  DatabaseHelper._init();

  /// Get sample questions (used for web and as initial data)
  static List<Question> getSampleQuestions() {
    return const [
      Question(id: 1, letter: 'A', questionText: 'Türkiye\'nin başkenti olan şehir.', answerText: 'ANKARA'),
      Question(id: 2, letter: 'B', questionText: 'İstanbul\'u Asya ve Avrupa\'ya ayıran suyolu.', answerText: 'BOĞAZ'),
      Question(id: 3, letter: 'C', questionText: 'İbadet edilen dini yapı.', answerText: 'CAMİ'),
      Question(id: 4, letter: 'Ç', questionText: 'Sıcak içecek olarak tüketilen yaprak.', answerText: 'ÇAY'),
      Question(id: 5, letter: 'D', questionText: 'Büyük su kütlesi, okyanustan küçük.', answerText: 'DENİZ'),
      Question(id: 6, letter: 'E', questionText: 'Undan yapılan temel gıda maddesi.', answerText: 'EKMEK'),
      Question(id: 7, letter: 'F', questionText: 'Hayvanları inceleyen bilim dalı.', answerText: 'FAUNA'),
      Question(id: 8, letter: 'G', questionText: 'Gökyüzündeki parlak cisim, yıldız.', answerText: 'GÜNEŞ'),
      Question(id: 9, letter: 'Ğ', questionText: 'Dağların en yüksek noktası.', answerText: 'ZİRVE'),
      Question(id: 10, letter: 'H', questionText: 'Atmosferdeki su buharının durumu.', answerText: 'HAVA'),
      Question(id: 11, letter: 'I', questionText: 'Güneşten gelen aydınlık.', answerText: 'IŞIK'),
      Question(id: 12, letter: 'İ', questionText: 'Türkiye\'nin en kalabalık şehri.', answerText: 'İSTANBUL'),
      Question(id: 13, letter: 'J', questionText: 'Kart oyunlarında en değerli figür.', answerText: 'JOKER'),
      Question(id: 14, letter: 'K', questionText: 'Yazı yazmak için kullanılan nesne.', answerText: 'KALEM'),
      Question(id: 15, letter: 'L', questionText: 'Deniz kenarındaki barınak.', answerText: 'LİMAN'),
      Question(id: 16, letter: 'M', questionText: 'Eğitim verilen kurum.', answerText: 'MEKTEP'),
      Question(id: 17, letter: 'N', questionText: 'Büyük akarsu.', answerText: 'NEHİR'),
      Question(id: 18, letter: 'O', questionText: 'Tiyatro veya konser izlenen yer.', answerText: 'OPERA'),
      Question(id: 19, letter: 'Ö', questionText: 'Eğitim veren kişi.', answerText: 'ÖĞRETMEN'),
      Question(id: 20, letter: 'P', questionText: 'Mektup gönderilen kurum.', answerText: 'POSTA'),
      Question(id: 21, letter: 'R', questionText: 'Görüntülerin kaydedildiği sanat.', answerText: 'RESİM'),
      Question(id: 22, letter: 'S', questionText: 'H2O formülüne sahip sıvı.', answerText: 'SU'),
      Question(id: 23, letter: 'Ş', questionText: 'Yerleşim yeri, kent.', answerText: 'ŞEHİR'),
      Question(id: 24, letter: 'T', questionText: 'Toprak işleme faaliyeti.', answerText: 'TARIM'),
      Question(id: 25, letter: 'U', questionText: 'Gökyüzünde uçan araç.', answerText: 'UÇAK'),
      Question(id: 26, letter: 'Ü', questionText: 'Bağda yetişen meyve.', answerText: 'ÜZÜM'),
      Question(id: 27, letter: 'V', questionText: 'İl yöneticisi.', answerText: 'VALİ'),
      Question(id: 28, letter: 'Y', questionText: 'Kış mevsiminde yağan beyaz örtü.', answerText: 'KAR'),
      Question(id: 29, letter: 'Z', questionText: 'Hayvanların sergilendiği park.', answerText: 'ZOO'),
    ];
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('harf_cemberi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        letter TEXT NOT NULL,
        questionText TEXT NOT NULL,
        answerText TEXT NOT NULL
      )
    ''');

    // Insert sample questions
    for (final q in getSampleQuestions()) {
      await db.insert('questions', {
        'letter': q.letter,
        'questionText': q.questionText,
        'answerText': q.answerText,
      });
    }
  }

  Future<List<Question>> getAllQuestions() async {
    // For web platform, use in-memory questions
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      return _webQuestions!;
    }
    
    // For mobile/desktop, use SQLite
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('questions');
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestionsByLetters(List<String> letters) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      return _webQuestions!.where((q) => letters.contains(q.letter)).toList();
    }
    
    final db = await database;
    final placeholders = letters.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'letter IN ($placeholders)',
      whereArgs: letters,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<Question?> getQuestionByLetter(String letter) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      try {
        return _webQuestions!.firstWhere((q) => q.letter == letter);
      } catch (_) {
        return null;
      }
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'letter = ?',
      whereArgs: [letter],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Question.fromMap(maps.first);
  }

  Future<int> insertQuestion(Question question) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      _webQuestions!.add(question);
      return question.id;
    }
    
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<int> updateQuestion(Question question) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      final index = _webQuestions!.indexWhere((q) => q.id == question.id);
      if (index != -1) {
        _webQuestions![index] = question;
        return 1;
      }
      return 0;
    }
    
    final db = await database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      _webQuestions!.removeWhere((q) => q.id == id);
      return 1;
    }
    
    final db = await database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await database;
    db.close();
  }
}
