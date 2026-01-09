import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Category Model
class Category {
  final int id;
  final String name;
  final String description;
  final String iconName;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String,
      iconName: map['iconName'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
    };
  }
}

// Question Model
class Question {
  final int id;
  final String letter;
  final String questionText;
  final String answerText;
  final int categoryId;

  const Question({
    required this.id,
    required this.letter,
    required this.questionText,
    required this.answerText,
    required this.categoryId,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      letter: map['letter'] as String,
      questionText: map['questionText'] as String,
      answerText: map['answerText'] as String,
      categoryId: map['categoryId'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'letter': letter,
      'questionText': questionText,
      'answerText': answerText,
      'categoryId': categoryId,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // In-memory data for web platform
  static List<Question>? _webQuestions;
  static List<Category>? _webCategories;

  DatabaseHelper._init();

  /// Get sample categories
  static List<Category> getSampleCategories() {
    return const [
      Category(id: 1, name: 'Genel Kültür', description: 'Karma sorular, her telden', iconName: 'quiz'),
      Category(id: 2, name: 'Yeşilçam ve Sinema', description: 'Filmler, oyuncular, replikler', iconName: 'movie'),
      Category(id: 3, name: 'Spor', description: 'Futbol, efsane sporcular, branşlar', iconName: 'sports_soccer'),
      Category(id: 4, name: 'Tarih', description: 'Savaşlar, padişahlar, olaylar', iconName: 'history_edu'),
      Category(id: 5, name: 'Coğrafya', description: 'Başkentler, nehirler, şehirler', iconName: 'public'),
      Category(id: 6, name: 'Mutfak ve Yemek', description: 'Yöresel yemekler, tarifler', iconName: 'restaurant'),
      Category(id: 7, name: 'Bilim ve Teknoloji', description: 'İcatlar, uzay, elementler', iconName: 'science'),
      Category(id: 8, name: 'Müzik', description: 'Şarkıcılar, enstrümanlar', iconName: 'music_note'),
      Category(id: 9, name: 'Edebiyat ve Sanat', description: 'Şairler, yazarlar, ressamlar', iconName: 'menu_book'),
      Category(id: 10, name: 'Doğa ve Hayvanlar', description: 'Hayvan türleri, bitkiler', iconName: 'pets'),
    ];
  }

  /// Get sample questions with categories
  static List<Question> getSampleQuestions() {
    return const [
      // Genel Kültür (categoryId: 1)
      Question(id: 1, letter: 'A', questionText: 'Türkiyenin başkenti.', answerText: 'ANKARA', categoryId: 1),
      Question(id: 2, letter: 'B', questionText: 'İstanbul\'u ikiye ayıran suyolu.', answerText: 'BOĞAZ', categoryId: 1),
      Question(id: 3, letter: 'C', questionText: 'İbadet edilen dini yapı.', answerText: 'CAMİ', categoryId: 1),
      Question(id: 4, letter: 'Ç', questionText: 'Sıcak içecek.', answerText: 'ÇAY', categoryId: 1),
      Question(id: 5, letter: 'D', questionText: 'Büyük su kütlesi.', answerText: 'DENİZ', categoryId: 1),
      Question(id: 6, letter: 'E', questionText: 'Temel gıda maddesi.', answerText: 'EKMEK', categoryId: 1),
      Question(id: 7, letter: 'F', questionText: 'Hayvan bilimi.', answerText: 'FAUNA', categoryId: 1),
      Question(id: 8, letter: 'G', questionText: 'Gökyüzündeki yıldız.', answerText: 'GÜNEŞ', categoryId: 1),
      Question(id: 9, letter: 'H', questionText: 'Atmosferin durumu.', answerText: 'HAVA', categoryId: 1),
      Question(id: 10, letter: 'I', questionText: 'Güneşten gelen aydınlık.', answerText: 'IŞIK', categoryId: 1),
      Question(id: 11, letter: 'İ', questionText: 'Türkiye\'nin en kalabalık şehri.', answerText: 'İSTANBUL', categoryId: 1),
      Question(id: 12, letter: 'J', questionText: 'Kart oyunlarında figür.', answerText: 'JOKER', categoryId: 1),
      Question(id: 13, letter: 'K', questionText: 'Yazı aracı.', answerText: 'KALEM', categoryId: 1),
      Question(id: 14, letter: 'L', questionText: 'Gemi barınağı.', answerText: 'LİMAN', categoryId: 1),
      Question(id: 15, letter: 'M', questionText: 'Okul, eğitim kurumu.', answerText: 'MEKTEP', categoryId: 1),
      Question(id: 16, letter: 'N', questionText: 'Büyük akarsu.', answerText: 'NEHİR', categoryId: 1),
      Question(id: 17, letter: 'O', questionText: 'Müzikli tiyatro.', answerText: 'OPERA', categoryId: 1),
      Question(id: 18, letter: 'Ö', questionText: 'Eğitim veren kişi.', answerText: 'ÖĞRETMEN', categoryId: 1),
      Question(id: 19, letter: 'P', questionText: 'Mektup kurumu.', answerText: 'POSTA', categoryId: 1),
      Question(id: 20, letter: 'R', questionText: 'Görsel sanat eseri.', answerText: 'RESİM', categoryId: 1),
      Question(id: 21, letter: 'S', questionText: 'H2O.', answerText: 'SU', categoryId: 1),
      Question(id: 22, letter: 'Ş', questionText: 'Yerleşim yeri.', answerText: 'ŞEHİR', categoryId: 1),
      Question(id: 23, letter: 'T', questionText: 'Toprak işleme.', answerText: 'TARIM', categoryId: 1),
      Question(id: 24, letter: 'U', questionText: 'Uçan araç.', answerText: 'UÇAK', categoryId: 1),
      Question(id: 25, letter: 'Ü', questionText: 'Bağda yetişen meyve.', answerText: 'ÜZÜM', categoryId: 1),
      Question(id: 26, letter: 'V', questionText: 'İl yöneticisi.', answerText: 'VALİ', categoryId: 1),
      Question(id: 27, letter: 'Y', questionText: 'Kış yağışı.', answerText: 'KAR', categoryId: 1),
      Question(id: 28, letter: 'Z', questionText: 'Hayvan parkı.', answerText: 'ZOO', categoryId: 1),
      
      // Yeşilçam ve Sinema (categoryId: 2)
      Question(id: 29, letter: 'A', questionText: 'Kemal Sunal\'ın ünlü karakteri.', answerText: 'APTI', categoryId: 2),
      Question(id: 30, letter: 'B', questionText: 'Cem Yılmaz\'ın uzay filmi.', answerText: 'GORA', categoryId: 2),
      Question(id: 31, letter: 'C', questionText: 'Türkan Şoray\'ın lakabı: Sultan.', answerText: 'SULTAN', categoryId: 2),
      Question(id: 32, letter: 'D', questionText: 'Cüneyt Arkın\'ın aksiyon karakteri.', answerText: 'DÜNYA', categoryId: 2),
      Question(id: 33, letter: 'E', questionText: 'Hababam Sınıfı yönetmeni Ertem...', answerText: 'EĞİLMEZ', categoryId: 2),
      Question(id: 34, letter: 'F', questionText: 'Yeşilçam\'ın ünlü film şirketi.', answerText: 'FİLM', categoryId: 2),
      Question(id: 35, letter: 'G', questionText: 'Şener Şen\'in polisiye filmi.', answerText: 'GORA', categoryId: 2),
      
      // Spor (categoryId: 3)
      Question(id: 36, letter: 'A', questionText: 'Fenerbahçe\'nin eski stadı.', answerText: 'ALİSAMİYEN', categoryId: 3),
      Question(id: 37, letter: 'B', questionText: 'Futbolda en iyi oyuncu ödülü: Altın...', answerText: 'TOP', categoryId: 3),
      Question(id: 38, letter: 'C', questionText: 'Cimbom hangi takımın lakabı?', answerText: 'GALATASARAY', categoryId: 3),
      Question(id: 39, letter: 'D', questionText: 'Uzun mesafe koşusu.', answerText: 'MARATON', categoryId: 3),
      Question(id: 40, letter: 'F', questionText: 'Top oyunu.', answerText: 'FUTBOL', categoryId: 3),
      
      // Tarih (categoryId: 4)
      Question(id: 41, letter: 'A', questionText: 'Cumhuriyetin kurucusu.', answerText: 'ATATÜRK', categoryId: 4),
      Question(id: 42, letter: 'B', questionText: 'Osmanlı başkenti.', answerText: 'BURSA', categoryId: 4),
      Question(id: 43, letter: 'C', questionText: '29 Ekim\'de ilan edilen yönetim.', answerText: 'CUMHURİYET', categoryId: 4),
      Question(id: 44, letter: 'F', questionText: 'Osmanlı\'yı kuran hanedan.', answerText: 'OSMANLI', categoryId: 4),
      Question(id: 45, letter: 'İ', questionText: '1453\'te fethedilen şehir.', answerText: 'İSTANBUL', categoryId: 4),
      
      // Coğrafya (categoryId: 5)
      Question(id: 46, letter: 'A', questionText: 'Türkiye\'nin en büyük gölü.', answerText: 'VAN', categoryId: 5),
      Question(id: 47, letter: 'D', questionText: 'Türkiye\'nin en uzun nehri.', answerText: 'KIZILIRMAK', categoryId: 5),
      Question(id: 48, letter: 'E', questionText: 'Türkiye\'nin en yüksek dağı: Ağrı...', answerText: 'DAĞI', categoryId: 5),
      Question(id: 49, letter: 'K', questionText: 'Türkiye\'nin başkenti.', answerText: 'ANKARA', categoryId: 5),
      Question(id: 50, letter: 'M', questionText: 'Akdeniz\'in eski adı: Ak...', answerText: 'DENİZ', categoryId: 5),
      
      // Mutfak ve Yemek (categoryId: 6)
      Question(id: 51, letter: 'A', questionText: 'Gaziantep\'in meşhur tatlısı.', answerText: 'BAKLAVA', categoryId: 6),
      Question(id: 52, letter: 'D', questionText: 'Dönen ette pişen yemek.', answerText: 'DÖNER', categoryId: 6),
      Question(id: 53, letter: 'K', questionText: 'Kahvaltıda içilen sıcak içecek.', answerText: 'ÇAY', categoryId: 6),
      Question(id: 54, letter: 'L', questionText: 'Mercimekten yapılan çorba.', answerText: 'MERCİMEK', categoryId: 6),
      Question(id: 55, letter: 'P', questionText: 'Fırında pişen hamur işi.', answerText: 'PİDE', categoryId: 6),
      
      // Bilim ve Teknoloji (categoryId: 7)
      Question(id: 56, letter: 'A', questionText: 'Uzaydaki taş parçası.', answerText: 'ASTEROID', categoryId: 7),
      Question(id: 57, letter: 'B', questionText: 'Kişisel bilgisayar.', answerText: 'BİLGİSAYAR', categoryId: 7),
      Question(id: 58, letter: 'D', questionText: 'Bilgi depolama birimi.', answerText: 'DİSK', categoryId: 7),
      Question(id: 59, letter: 'İ', questionText: 'Dünya çapında ağ.', answerText: 'İNTERNET', categoryId: 7),
      Question(id: 60, letter: 'R', questionText: 'Otomatik makine.', answerText: 'ROBOT', categoryId: 7),
      
      // Müzik (categoryId: 8)
      Question(id: 61, letter: 'B', questionText: 'Türk pop müziğinin kralı: Tarkan\'ın lakabı: Megastar.', answerText: 'TARKAN', categoryId: 8),
      Question(id: 62, letter: 'G', questionText: 'Altı telli çalgı.', answerText: 'GİTAR', categoryId: 8),
      Question(id: 63, letter: 'K', questionText: 'Tuşlu çalgı aleti.', answerText: 'PİYANO', categoryId: 8),
      Question(id: 64, letter: 'S', questionText: 'Barış Manço\'nun grubu: Kurtalan...', answerText: 'EKSPRES', categoryId: 8),
      Question(id: 65, letter: 'Ş', questionText: 'Söz ve melodiden oluşan eser.', answerText: 'ŞARKI', categoryId: 8),
      
      // Edebiyat ve Sanat (categoryId: 9)
      Question(id: 66, letter: 'N', questionText: 'Nobel ödüllü Türk yazar.', answerText: 'PAMUK', categoryId: 9),
      Question(id: 67, letter: 'O', questionText: 'Çalıkuşu romanının yazarı: Reşat Nuri...', answerText: 'GÜNTEKİN', categoryId: 9),
      Question(id: 68, letter: 'R', questionText: 'Tuval üzerine yapılan sanat.', answerText: 'RESİM', categoryId: 9),
      Question(id: 69, letter: 'Ş', questionText: 'Şiir yazan kişi.', answerText: 'ŞAİR', categoryId: 9),
      Question(id: 70, letter: 'Y', questionText: 'Roman, hikaye yazan kişi.', answerText: 'YAZAR', categoryId: 9),
      
      // Doğa ve Hayvanlar (categoryId: 10)
      Question(id: 71, letter: 'A', questionText: 'Bal yapan böcek.', answerText: 'ARI', categoryId: 10),
      Question(id: 72, letter: 'K', questionText: 'Evcil miyavlayan hayvan.', answerText: 'KEDİ', categoryId: 10),
      Question(id: 73, letter: 'K', questionText: 'Evcil havlayan hayvan.', answerText: 'KÖPEK', categoryId: 10),
      Question(id: 74, letter: 'A', questionText: 'Ağaçlık bölge.', answerText: 'ORMAN', categoryId: 10),
      Question(id: 75, letter: 'Ç', questionText: 'Yaprak döken bitki organı.', answerText: 'ÇİÇEK', categoryId: 10),
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
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        iconName TEXT NOT NULL
      )
    ''');

    // Create questions table with categoryId
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        letter TEXT NOT NULL,
        questionText TEXT NOT NULL,
        answerText TEXT NOT NULL,
        categoryId INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Insert sample categories
    for (final cat in getSampleCategories()) {
      await db.insert('categories', {
        'name': cat.name,
        'description': cat.description,
        'iconName': cat.iconName,
      });
    }

    // Insert sample questions
    for (final q in getSampleQuestions()) {
      await db.insert('questions', {
        'letter': q.letter,
        'questionText': q.questionText,
        'answerText': q.answerText,
        'categoryId': q.categoryId,
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop old tables and recreate
      await db.execute('DROP TABLE IF EXISTS questions');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _createDB(db, newVersion);
    }
  }

  // Category methods
  Future<List<Category>> getAllCategories() async {
    if (kIsWeb) {
      _webCategories ??= getSampleCategories();
      return _webCategories!;
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    if (kIsWeb) {
      _webCategories ??= getSampleCategories();
      try {
        return _webCategories!.firstWhere((cat) => cat.id == id);
      } catch (_) {
        return null;
      }
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  // Question methods
  Future<List<Question>> getAllQuestions() async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      return _webQuestions!;
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('questions');
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestionsByCategory(int categoryId) async {
    if (kIsWeb) {
      _webQuestions ??= getSampleQuestions();
      return _webQuestions!.where((q) => q.categoryId == categoryId).toList();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
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
