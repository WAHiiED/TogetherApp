// meeting_home_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'meeting_setup_screen.dart';

class MeetingHomeScreen extends StatelessWidget {
  const MeetingHomeScreen({super.key});

  String _generateRoomId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
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
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Image.asset('assets/images/Picture1.png'),
              ),
              const SizedBox(height: 40),
              const Text(
                'Start or Join Meeting',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.video_call,color: Colors.blueAccent,),
                label: const Text('New Meeting',
                style: TextStyle(
                  color: Colors.blueAccent
                ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  final newRoomId = _generateRoomId();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeetingSetupScreen(
                        isHost: true,
                        roomId: newRoomId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.meeting_room,color: Colors.blueAccent,),
                label: const Text('Join Meeting',
                style:TextStyle(
                  color: Colors.blueAccent
                )
                  ,),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  final controller = TextEditingController();
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Enter Room ID'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(hintText: 'Room ID'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            final roomId = controller.text.trim();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MeetingSetupScreen(
                                  isHost: false,
                                  roomId: roomId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Join'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
