import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:togetherapp/services/api_service.dart';
import 'package:video_player/video_player.dart';

import 'favoritesscreen.dart';
import 'main.dart';
import 'notification_service.dart';

class WordToSignScreen extends StatefulWidget {
  const WordToSignScreen({super.key});

  @override
  State<WordToSignScreen> createState() => _WordToSignScreenState();
}

class _WordToSignScreenState extends State<WordToSignScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? word;
  String? description;
  List<String> howToSign = [];
  List<String> relatedSigns = [];
  bool isLoading = false;
  VideoPlayerController? _videoController;
  bool isVideoVisible = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadDefaultWord();
  }

  void _loadDefaultWord() {
    setState(() {
      word = 'Hello';
      description = 'Used as a greeting or to begin a conversation.';
      howToSign = [
        'Start with your dominant hand near your head, palm facing outward and fingers spread.',
        'Move your hand away from your head in a slight arc, as if you\'re greeting someone.',
        'Smile while signing to convey a friendly greeting.',
      ];
      relatedSigns = ['Hi', 'Greeting', 'Welcome'];
    });
  }

  Future<void> _searchWord() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      isLoading = true;
      isVideoVisible = false;
      _disposeVideo();
    });

    try {
      var result = await ApiService.lookupWord(_searchController.text.trim());

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        List<String> favorites = prefs.getStringList('favorites') ?? [];
        setState(() {
          word = _searchController.text.trim();
          description = result['description'];
          howToSign = List<String>.from(result['how_to_sign']);
          relatedSigns = List<String>.from(result['related']);
          isFavorite = favorites.contains(word);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word not found')),
        );
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _playVideo() async {
    try {
      String videoUrl = '${ApiService.baseUrl}/static/videos/${word!.toLowerCase().replaceAll(' ', '_')}.mp4';
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();
      _videoController!.play();
      setState(() {
        isVideoVisible = true;
      });
    } catch (e) {
      print('Error playing video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video not found')),
      );
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
  }


  Future<void> _downloadVideo() async {
    final path = await ApiService.downloadVideo(word!);

    if (path != null) {
      await NotificationService.show(
        title: 'Download Complete',
        body: '"$word" video has been saved to:\n$path',
      );
    } else {
      await NotificationService.show(
        title: 'Download Failed',
        body: 'Could not download video for "$word".',
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];

    final adding = !favorites.contains(word);
    if (adding) {
      favorites.add(word!);
    } else {
      favorites.remove(word);
    }

    await prefs.setStringList('favorites', favorites);
    await FavoritesScreen.syncFavorite(word!, isAdding: adding);

    setState(() {
      isFavorite = adding;
    });

    // ✅ Use the service
    await NotificationService.show(
      title: adding ? 'Added to Favorites' : 'Removed from Favorites',
      body: '"$word" has been ${adding ? 'added to' : 'removed from'} your favorites.',
    );
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Sign Language Dictionary',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator()
                      : _buildResultCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a word...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: _searchWord,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Search'),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  word ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.blue),
                    ),
                    IconButton(
                      onPressed: _downloadVideo,
                      icon: const Icon(Icons.download, color: Colors.blue),
                    ),
                  ],
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _playVideo,
                  child: Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: isVideoVisible && _videoController != null
                          ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                          : const Icon(Icons.play_arrow, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _videoController?.setPlaybackSpeed(1.0);
                        _videoController?.play();
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        _videoController?.setPlaybackSpeed(0.5);
                        _videoController?.play();
                      },
                      icon: const Icon(Icons.slow_motion_video),
                      label: const Text('Slow Motion'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: howToSign.map((step) => Text('• $step')).toList(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: relatedSigns.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blue.shade50,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
