import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';

class PredictionHistoryScreen extends StatefulWidget {
  const PredictionHistoryScreen({super.key});

  @override
  State<PredictionHistoryScreen> createState() => _PredictionHistoryScreenState();
}

class _PredictionHistoryScreenState extends State<PredictionHistoryScreen> {
  List<String> _predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final predictions = await FirebaseService().getUserPredictions(userId: userId);
      setState(() {
        _predictions = predictions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _predictions.isEmpty
          ? const Center(child: Text('No predictions yet.'))
          : ListView.builder(
        itemCount: _predictions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(_predictions[index]),
          );
        },
      ),
    );
  }
}
