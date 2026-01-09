import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

  // Koleksiyon referansları
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _scoresCollection => _firestore.collection('scores');

  // --- Kullanıcı İşlemleri ---

  // Kullanıcıyı kaydet veya güncelle
  Future<void> saveUser(User user) async {
    try {
      final userDoc = _usersCollection.doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Yeni kullanıcı
        await userDoc.set({
          'uid': user.uid,
          'displayName': user.displayName ?? 'Misafir',
          'email': user.email,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'friendIds': [],
          'bestScore': 0, // Genel en iyi skor
        });
      } else {
        // Mevcut kullanıcı - son giriş zamanını güncelle
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
          // İsim veya fotoğraf değişmiş olabilir, güncelle
          'displayName': user.displayName ?? 'Misafir',
          'photoURL': user.photoURL,
        });
      }
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  // Kullanıcı ara (İsim veya E-posta ile)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      // Basit arama: 'displayName' alana göre
      // Not: Firestore'da substring araması zordur. 
      // Burada sadece tam eşleşme veya başlangıç eşleşmesi (>= query ve < query + 'z') yapılabilir.
      final result = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .limit(10)
          .get();

      return result.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .where((data) => data['uid'] != FirebaseAuth.instance.currentUser?.uid) // Kendini hariç tut
          .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Arkadaş ekle
  Future<void> addFriend(String friendId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await _usersCollection.doc(currentUser.uid).update({
        'friendIds': FieldValue.arrayUnion([friendId])
      });
    } catch (e) {
      debugPrint('Error adding friend: $e');
      rethrow;
    }
  }

  // Arkadaş listesini getir
  Future<List<Map<String, dynamic>>> getFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      // Önce kullanıcının arkadaş ID'lerini al
      final userDoc = await _usersCollection.doc(currentUser.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      
      if (userData == null || !userData.containsKey('friendIds')) return [];
      
      final List<dynamic> friendIds = userData['friendIds'];
      if (friendIds.isEmpty) return [];

      // ID listesine göre kullanıcıları çek
      // whereIn sorgusu en fazla 10 eleman destekler. 
      // 10'dan fazla arkadaş varsa parça parça çekmek gerekir (Basitlik için şimdilik limit 10 varsayalım veya döngüyle yapalım)
      // Şimdilik client-side join yapalım daha güvenli (veya chunked query)
      
      List<Map<String, dynamic>> friends = [];
      
      // Firestore 'whereIn' limiti 10 olduğu için 10'arlı gruplar halinde çekelim
      for (var i = 0; i < friendIds.length; i += 10) {
        var end = (i + 10 < friendIds.length) ? i + 10 : friendIds.length;
        var chunk = friendIds.sublist(i, end);
        
        final chunkResult = await _usersCollection
            .where('uid', whereIn: chunk)
            .get();
            
        friends.addAll(chunkResult.docs.map((doc) => doc.data() as Map<String, dynamic>));
      }
      
      return friends;

    } catch (e) {
      debugPrint('Error getting friends: $e');
      return [];
    }
  }

  // --- Skor İşlemleri ---

  // Skoru kaydet
  Future<void> saveScore(int score, String categoryName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. users koleksiyonunda genel 'bestScore' güncelle (eğer yeni skor daha yüksekse)
      final userRef = _usersCollection.doc(user.uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final currentBest = (userData?['bestScore'] as num?)?.toInt() ?? 0;

      if (score > currentBest) {
        await userRef.update({'bestScore': score});
      }

      // 2. scores koleksiyonuna skor kaydı ekle (Leaderboard için)
      // Her kullanıcının sadece EN İYİ skoru mu olmalı yoksa her oyun mu?
      // Genelde leaderboard'da her kullanıcının tek bir (en iyi) girişi olur.
      
      final scoreDocId = '${user.uid}_$categoryName'; // Kategori bazlı unique ID
      
      // Kategori bazlı en iyi skor kontrolü
      final scoreDoc = await _scoresCollection.doc(scoreDocId).get();
      final scoreData = scoreDoc.data() as Map<String, dynamic>?;
      final currentCategoryBest = (scoreData?['score'] as num?)?.toInt() ?? 0;

      if (score > currentCategoryBest) {
          await _scoresCollection.doc(scoreDocId).set({
            'userId': user.uid,
            'userName': user.displayName ?? 'Misafir',
            'userPhoto': user.photoURL,
            'score': score,
            'category': categoryName,
            'timestamp': FieldValue.serverTimestamp(),
          });
      }

    } catch (e) {
      debugPrint('Error saving score: $e');
      // Skor hatası oyunu durdurmasın, sessizce logla
    }
  }

  // Global Liderlik Tablosu (En yüksek 50)
  Future<List<Map<String, dynamic>>> getGlobalLeaderboard({String category = 'Global'}) async {
    try {
      Query query = _scoresCollection
          .orderBy('score', descending: true)
          .limit(50);
          
      if (category != 'Global') {
        query = query.where('category', isEqualTo: category);
      }

      final result = await query.get();
      return result.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting leaderboard: $e');
      return [];
    }
  }
}
