// meeting_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'meeting_room_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

class MeetingSetupScreen extends StatefulWidget {
  final bool isHost;
  final String roomId;

  const MeetingSetupScreen({super.key, required this.isHost, required this.roomId});

  @override
  State<MeetingSetupScreen> createState() => _MeetingSetupScreenState();
}

class _MeetingSetupScreenState extends State<MeetingSetupScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _micOn = true;
  bool _camOn = true;

  @override
  void initState() {
    super.initState();
    _initLocalMedia();
    if (widget.isHost) {
      _createRoom();
    }
  }

  Future<void> _initLocalMedia() async {
    await _localRenderer.initialize();
    final mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };
    final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream = stream;
    _localRenderer.srcObject = stream;
    setState(() {});
  }

  Future<void> _createRoom() async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    await roomRef.set({
      'created': Timestamp.now(),
      'isHost': widget.isHost,
    });
  }

  void _toggleMic() {
    setState(() {
      _micOn = !_micOn;
    });
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = _micOn;
    });
  }

  void _toggleCam() {
    setState(() {
      _camOn = !_camOn;
    });
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _camOn;
    });
  }

  void _goToMeetingRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeetingRoomScreen(
          roomId: widget.roomId,
          isHost: widget.isHost,
          localStream: _localStream,
        ),
      ),
    );
  }

  Future<void> _copyRoomId() async {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    await NotificationService.show(
      title: 'Meeting Room ID.',
      body: 'Room ID copied to clipboard',

    );
  }

  void _shareRoom() {
    final message = 'Join my video meeting using this Room ID: ${widget.roomId}';
    Share.share(message);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
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
        appBar: AppBar(title: const Text('Meeting Setup',style: TextStyle(
          color:Colors.blueAccent
        ),),
        centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
                  onPressed: _toggleMic,
                ),
                IconButton(
                  icon: Icon(_camOn ? Icons.videocam : Icons.videocam_off),
                  onPressed: _toggleCam,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyRoomId,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareRoom,
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _goToMeetingRoom,
              child: const Text('Enter Meeting',style: TextStyle(color: Colors.blueAccent),),
            ),
          ],
        ),
      ),
    );
  }
}