import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:togetherapp/services/firebase_service.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller?.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _captureAndPredict() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    final XFile file = await _controller!.takePicture();
    final bytes = await file.readAsBytes();

    final uri = Uri.parse('http://YOUR_FLASK_SERVER_IP:5000/predict');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'image.jpg'));

    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);
      final prediction = decoded['prediction'];

      _speak(prediction); // Speak out loud
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction: $prediction')));

      // 🔥 SAVE TO FIREBASE
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseService().savePrediction(
            userId: userId, prediction: prediction);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to predict')));
    }
  }


  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Detection'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: _captureAndPredict,
              child: const Text('Capture and Predict'),
            ),
          ),
        ],
      ),
    );
  }
}
