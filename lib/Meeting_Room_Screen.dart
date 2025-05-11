// meeting_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class MeetingRoomScreen extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final MediaStream? localStream;

  const MeetingRoomScreen({
    super.key,
    required this.roomId,
    required this.isHost,
    this.localStream,
  });

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _remoteSet = false;
  final List<RTCIceCandidate> _remoteCandidates = [];

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  final TextEditingController _chatController = TextEditingController();
  bool _showChat = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _startSignaling();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    if (widget.localStream != null) {
      _localRenderer.srcObject = widget.localStream;
    }
  }

  Future<void> _startSignaling() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(config);

    if (widget.localStream != null) {
      widget.localStream!.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, widget.localStream!);
      });
    }

    _peerConnection?.onTrack = (event) {
      if (event.track.kind == 'video') {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    final callerCandidatesCollection = roomRef.collection(widget.isHost ? 'callerCandidates' : 'calleeCandidates');
    final calleeCandidatesCollection = roomRef.collection(widget.isHost ? 'calleeCandidates' : 'callerCandidates');

    _peerConnection?.onIceCandidate = (candidate) async {
      await callerCandidatesCollection.add(candidate.toMap());
    };

    if (widget.isHost) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await roomRef.set({'offer': offer.toMap()});

      roomRef.snapshots().listen((snapshot) async {
        final data = snapshot.data();
        if (data != null && data['answer'] != null && !_remoteSet) {
          final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
          await _peerConnection!.setRemoteDescription(answer);
          _remoteSet = true;
        }
      });
    } else {
      final snapshot = await roomRef.get();
      final data = snapshot.data();

      if (data != null && data['offer'] != null) {
        final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
        await _peerConnection!.setRemoteDescription(offer);

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        await roomRef.update({'answer': answer.toMap()});
      }
    }

    calleeCandidatesCollection.snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final data = docChange.doc.data();
          if (data != null) {
            final candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );
            _peerConnection?.addCandidate(candidate);
          }
        }
      }
    });
  }

  void _toggleMic() {
    final audioTrack = widget.localStream?.getAudioTracks().first;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      setState(() => _micEnabled = audioTrack.enabled);
    }
  }

  void _toggleCamera() {
    final videoTrack = widget.localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      videoTrack.enabled = !videoTrack.enabled;
      setState(() => _cameraEnabled = videoTrack.enabled);
    }
  }

  void _endCall() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _localRenderer.dispose();
    _peerConnection?.close();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _copyRoomId() async {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    await NotificationService.show(
      title: 'Meeting Room ID.',
      body: 'Room ID copied to clipboard',

    );
  }

  void _shareRoomLink() {
    final link = 'https://yourapp.com/join?roomId=${widget.roomId}';
    Share.share('Join my video call room: $link');
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown';

    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .add({'name': userName, 'message': text, 'timestamp': FieldValue.serverTimestamp()});

    _chatController.clear();
  }

  Stream<QuerySnapshot> _messageStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _sendReaction(String emoji) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reaction: $emoji')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meeting Room: ${widget.roomId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => setState(() => _showChat = !_showChat),
            tooltip: 'Toggle Chat',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyRoomId,
            tooltip: 'Copy Room ID',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRoomLink,
            tooltip: 'Share Room',
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: RTCVideoView(_remoteRenderer)),
              SizedBox(
                height: 200,
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: Icon(_cameraEnabled ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    color: Colors.red,
                    onPressed: _endCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions),
                    onPressed: () => _sendReaction('😊'),
                  ),
                ],
              ),
            ],
          ),
          if (_showChat)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.6,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _messageStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final docs = snapshot.data!.docs;
                          return ListView(
                            reverse: true,
                            children: docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'Unknown';
                              final msg = data['message'] ?? '';
                              return ListTile(title: Text('$name: $msg'));
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              decoration: const InputDecoration(hintText: 'Type a message'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
