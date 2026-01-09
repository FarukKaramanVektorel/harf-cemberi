import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Sosyal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.yellow,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.yellow,
          tabs: const [
            Tab(icon: Icon(Icons.leaderboard), text: 'Sıralama'),
            Tab(icon: Icon(Icons.person_add), text: 'Arkadaş Ekle'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LeaderboardTab(),
          FriendsTab(),
        ],
      ),
    );
  }
}

// --- Leaderboard Tab ---
class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab> {
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() => _isLoading = true);
    final scores = await FirestoreService.instance.getGlobalLeaderboard();
    if (mounted) {
      setState(() {
        _scores = scores;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.yellow));
    }

    if (_scores.isEmpty) {
      return const Center(child: Text('Henüz skor yok.', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scores.length,
      itemBuilder: (context, index) {
        final score = _scores[index];
        final isMe = score['userId'] == FirebaseAuth.instance.currentUser?.uid;

        return Card(
          color: isMe ? Colors.yellow.withValues(alpha: 0.2) : const Color(0xFF16213E),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            title: Text(
              score['userName'] ?? 'Bilinmeyen',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              score['category'] ?? 'Genel',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            trailing: Text(
              '${score['score']}',
              style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.yellow; // Altın
    if (index == 1) return Colors.grey;   // Gümüş
    if (index == 2) return Colors.orange; // Bronz
    return Colors.white;
  }
}

// --- Friends Tab (Search & List) ---
class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _friends = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await FirestoreService.instance.getFriends();
    if (mounted) setState(() => _friends = friends);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    final results = await FirestoreService.instance.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _addFriend(String uid) async {
    await FirestoreService.instance.addFriend(uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arkadaş eklendi!')));
    _searchController.clear();
    setState(() => _searchResults = []);
    _loadFriends(); // Listeyi yenile
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arama Çubuğu
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Arkadaş Ara (İsim)...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF16213E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Colors.yellow),
                onPressed: () => _searchUsers(_searchController.text),
              ),
            ),
            onSubmitted: _searchUsers,
          ),
        ),
        
        if (_isSearching)
           const Padding(
             padding: EdgeInsets.all(8.0),
             child: CircularProgressIndicator(color: Colors.yellow),
           ),

        // Arama Sonuçları (Varsa)
        if (_searchResults.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Arama Sonuçları', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final user = _searchResults[index];
              return ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(user['displayName'], style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.green),
                  onPressed: () => _addFriend(user['uid']),
                ),
              );
            },
          ),
          const Divider(color: Colors.white24),
        ],

        // Arkadaş Listesi
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Arkadaşlarım', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        
        Expanded(
          child: _friends.isEmpty
              ? const Center(child: Text('Henüz arkadaşın yok.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(friend['displayName'][0].toUpperCase()),
                      ),
                      title: Text(friend['displayName'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text('Skor: ${friend['bestScore'] ?? 0}', style: const TextStyle(color: Colors.white54)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
