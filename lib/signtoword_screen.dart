import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:togetherapp/services/api_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class SignToWordScreen extends StatefulWidget {
  const SignToWordScreen({super.key});

  @override
  State<SignToWordScreen> createState() => _SignToWordScreenState();
}

class _SignToWordScreenState extends State<SignToWordScreen> {
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? translatedSentence;
  bool isVideoPlaying = false;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      _initializeVideo(File(pickedFile.path));
    }
  }

  Future<void> _recordVideo() async {
    final XFile? recordedFile = await _picker.pickVideo(source: ImageSource.camera);
    if (recordedFile != null) {
      _initializeVideo(File(recordedFile.path));
    }
  }

  void _initializeVideo(File file) async {
    _disposeControllers();
    _selectedVideo = file;
    _videoController = VideoPlayerController.file(file);
    await _videoController!.initialize();

    _videoController!.addListener(() {
      final bool isPlaying = _videoController!.value.isPlaying;
      if (isPlaying != isVideoPlaying) {
        setState(() {
          isVideoPlaying = isPlaying;
        });
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: false,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.blue,
        handleColor: Colors.blueAccent,
        bufferedColor: Colors.lightBlueAccent,
      ),
    );
    setState(() {
      translatedSentence = null;
    });
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  Future<void> _uploadVideoToServer() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video selected')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.uploadSignVideo(_selectedVideo!);
      if (result != null) {
        final data = jsonDecode(result);
        final sentence = data['sentence'] ?? '';
        final extractedWord = sentence.split(':').last.trim().replaceAll('.', '');
        setState(() {
          translatedSentence = extractedWord.isNotEmpty ? extractedWord : 'No translation found';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to translate video')),
        );
      }
    } catch (e) {
      print('Error uploading: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to translate video')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _copyTranslation() {
    if (translatedSentence != null) {
      Clipboard.setData(ClipboardData(text: translatedSentence!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _disposeControllers();
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Sign Language Translator',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Upload or record your sign language video',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildTopButtons(),
                    const SizedBox(height: 30),
                    _buildVideoPreview(),
                    if (isLoading)
                      const Column(
                        children: [
                          SizedBox(height: 20),
                          Text('Translating your sign language...', style: TextStyle(color: Colors.black54)),
                          SizedBox(height: 10),
                          LinearProgressIndicator(minHeight: 5),
                        ],
                      ),
                    if (translatedSentence != null) _buildTranslationResult(),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTopButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _pickVideo,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text('Upload Video'),
        ),
        const SizedBox(width: 20),
        OutlinedButton(
          onPressed: _recordVideo,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text('Record Video', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    if (_chewieController == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_rounded, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              'Drag and drop your sign language video here\nor click the button below to select a file',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Video'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            )
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
              if (!isVideoPlaying)
                Container(
                  color: Colors.black.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: _uploadVideoToServer,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Translate'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedVideo = null;
                    _disposeControllers();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                ),
                child: const Text('Upload New Video'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTranslationResult() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Translation Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                translatedSentence ?? '',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _copyTranslation,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Copy Text'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
