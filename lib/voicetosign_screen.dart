import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:togetherapp/services/api_service.dart';

class VoiceToSignScreen extends StatefulWidget {
  const VoiceToSignScreen({super.key});

  @override
  State<VoiceToSignScreen> createState() => _VoiceToSignScreenState();
}

class _VoiceToSignScreenState extends State<VoiceToSignScreen> {
  bool isRecording = false;
  bool isUploading = false;
  bool isRecordMode = false;
  String? audioPath;
  String? serverResponse;
  Timer? _timer;
  int seconds = 0;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final List<double> _waveHeights = List.generate(30, (index) => 10);

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;
    await _recorder.openRecorder();
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        audioPath = result.files.single.path!;
        serverResponse = null;
      });
    }
  }
  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print("Microphone permission not granted");
      return;
    }

    try {
      final directory = await Directory.systemTemp.createTemp();
      final path = '${directory.path}/recorded_audio.wav';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV, // Use WAV format for easier compatibility
      );

      setState(() {
        isRecording = true;
        audioPath = path;
        seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          seconds++;
          _randomizeWaveform();
        });
      });

      print("Recording started: $audioPath");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }


  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stopRecorder();
      _timer?.cancel();

      setState(() {
        isRecording = false;
      });

      if (path != null) {
        final file = File(path);
        final length = await file.length();
        print("Recording stopped. File saved at: $path");
        print("Recorded file size: $length bytes");
      } else {
        print("Recording stopped, but path was null");
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }



  void _randomizeWaveform() {
    for (int i = 0; i < _waveHeights.length; i++) {
      _waveHeights[i] = 10 + (i % 5) * 15 * (i.isEven ? 1.0 : 0.5);
    }
  }

  Future<void> _uploadAudio() async {
    if (audioPath == null) return;
    setState(() => isUploading = true);
    final response = await ApiService.uploadAudio(File(audioPath!));
    setState(() {
      isUploading = false;
      serverResponse = response;
    });
  }

  void _copyToClipboard() {
    if (serverResponse != null) {
      Clipboard.setData(ClipboardData(text: serverResponse!));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard")));
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    'Voice to Sign Language',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload or record your voice to convert into sign language video',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => isRecordMode = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isRecordMode ? Colors.blue : Colors.white,
                          foregroundColor: !isRecordMode ? Colors.white : Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('Upload Audio'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => setState(() => isRecordMode = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRecordMode ? Colors.blue : Colors.white,
                          foregroundColor: isRecordMode ? Colors.white : Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                        child: const Text('Record Voice'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (!isRecordMode) _buildUploadSection() else _buildRecordSection(),
                  const SizedBox(height: 30),
                  if (audioPath != null)
                    ElevatedButton.icon(
                      onPressed: _uploadAudio,
                      icon: const Icon(Icons.cloud_upload),
                      label: isUploading
                          ? const Text("Uploading...")
                          : const Text("Convert to Sign Language"),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  if (serverResponse != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text("Translation Result:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            serverResponse!,
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: const Text("Copy Result"),
                          )
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 60, color: Colors.blue),
          const SizedBox(height: 10),
          const Text(
            'Drag and drop your audio file here or click the button below to select a file',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickAudio,
            icon: const Icon(Icons.upload),
            label: const Text("Upload Audio"),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        children: [
          const Icon(Icons.mic, size: 60, color: Colors.blue),
          const SizedBox(height: 10),
          const Text('Record your voice message', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 20),
          _buildWaveform(),
          const SizedBox(height: 20),
          Text(
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 20, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isRecording ? null : _startRecording,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Start Recording'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isRecording ? _stopRecording : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Stop Recording'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _waveHeights.map((height) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}
