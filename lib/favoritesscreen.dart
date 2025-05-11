import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  static Future<void> syncFavorite(String word, {required bool isAdding}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    List<String> localFavorites = prefs.getStringList('favorites') ?? [];

    if (isAdding) {
      if (!localFavorites.contains(word)) localFavorites.add(word);
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(word)
            .set({"timestamp": FieldValue.serverTimestamp()});
      }
    } else {
      localFavorites.remove(word);
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(word)
            .delete();
      }
    }
    await prefs.setStringList('favorites', localFavorites);
  }

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<String> allFavorites = [];
  List<String> filteredFavorites = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;

    if (uid == null) return;

    final favSnap = await firestore.collection('users').doc(uid).collection('favorites').get();
    final firestoreList = favSnap.docs.map((doc) => doc.id).toList()..sort((a, b) => a.compareTo(b));

    await prefs.setStringList('favorites', firestoreList);

    setState(() {
      allFavorites = firestoreList;
      filteredFavorites = firestoreList;
    });
  }

  Future<void> _removeFavorite(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    allFavorites.remove(word);
    await prefs.setStringList('favorites', allFavorites);

    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(word)
          .delete();
    }

    _applySearch(searchQuery);

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => const Center(
        child: Icon(Icons.favorite, color: Colors.red, size: 100),
      ),
    );
    overlay.insert(entry);
    await Future.delayed(const Duration(milliseconds: 600));
    entry.remove();

    await NotificationService.show(
      title: 'Removed from Favorites',
      body: '"$word" has been removed from your favorites.',
    );
  }

  void _applySearch(String query) {
    final result = allFavorites
        .where((word) => word.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      searchQuery = query;
      filteredFavorites = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('My Favorites'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 5),
                child: TextField(
                  onChanged: _applySearch,
                  decoration: InputDecoration(
                    hintText: 'Search favorites...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              Expanded(
                child: filteredFavorites.isEmpty
                    ? const Center(
                  child: Text(
                    'No favorites found!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final word = filteredFavorites[index];
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          word,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _removeFavorite(word),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}