import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:togetherapp/Meeting_Home_Screen.dart';
import 'package:togetherapp/favoritesscreen.dart';
import 'package:togetherapp/profilescreen.dart';

// Dummy screens for navigation (you can replace later)
//import 'meeting_screen.dart';
// 'favorites_screen.dart';
//import 'profile_screen.dart';
import 'signtoword_screen.dart';
import 'wordtosign_screen.dart';
import 'voicetosign_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/backgrounf.png"), // <-- your dotted background
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildNewMeeting(context),
              const SizedBox(height: 20),
              _buildAdditionalServices(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png', // Your logo
            height: 20,
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
            child: const Text('Home', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            },
            child: const Text('Favorites', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: const Text('Profile', style: TextStyle(color: Colors.blue)),
          ),

        ],
      ),
    );
  }

  Widget _buildNewMeeting(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetingHomeScreen())); // to be created later
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 180,
        decoration: BoxDecoration(
          image:DecorationImage(image: AssetImage('assets/images/meet.png'),
            fit: BoxFit.cover,
          ) ,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),

      ),
    );
  }

  Widget _buildAdditionalServices(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'additional services',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: PageView(
              controller: PageController(viewportFraction: 0.8),
              children: [
                _buildServiceCard(context, 'Word to Sign', 'assets/images/wtos.png', const WordToSignScreen()),
                _buildServiceCard(context, 'Sign to Word', 'assets/images/stow.png', const SignToWordScreen()),
                _buildServiceCard(context, 'Voice to Sign', 'assets/images/voicetosign.png', const VoiceToSignScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String imagePath, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(imagePath, height: 200),
              const SizedBox(height: 10),

              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, size: 16, color: Colors.blueAccent),
                  Icon(Icons.star, size: 16, color: Colors.blueAccent),
                  Icon(Icons.star, size: 16, color: Colors.blueAccent),
                  Icon(Icons.star, size: 16, color: Colors.blueAccent),
                  Icon(Icons.star, size: 16, color: Colors.blueAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
