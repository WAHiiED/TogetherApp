import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isEditing = false;

  TextEditingController nameController = TextEditingController();
  String selectedRole = "Speaker";
  DateTime? selectedDOB;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          userData = doc.data();
          nameController.text = userData?['name'] ?? '';
          selectedRole = userData?['role'] ?? "Speaker";
          selectedDOB = DateTime.tryParse(userData?['dob'] ?? "");
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'role': selectedRole,
        'dob': selectedDOB?.toIso8601String(),
      });
      await NotificationService.show(
        title: 'Profile update.',
        body: 'Your profile has been updated ',

      );

      setState(() {
        isEditing = false;
      });
    }
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDOB ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDOB = picked;
      });
    }
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Profile",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      IconButton(
                        icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.blue),
                        onPressed: () {
                          if (isEditing) {
                            _updateUserData();
                          } else {
                            setState(() => isEditing = true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 90,
                            backgroundImage: const AssetImage("assets/images/Profile.png"),
                            backgroundColor: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            nameController.text,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileField(
                            label: "Name",
                            icon: Icons.person,
                            child: TextFormField(
                              controller: nameController,
                              readOnly: !isEditing,
                              decoration: const InputDecoration(
                                labelText: "Name",
                                border: InputBorder.none,
                              ),
                              validator: (val) => val == null || val.isEmpty ? "Enter name" : null,
                            ),
                          ),
                          _buildProfileField(
                            label: "Email",
                            icon: Icons.email,
                            child: TextFormField(
                              initialValue: userData?['email'] ?? '',
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Email",
                                suffixIcon: isEditing ?Icon(Icons.lock_outline, color: Colors.grey): null,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          _buildProfileField(
                            label: "Date of Birth",
                            icon: Icons.cake,
                            child: GestureDetector(
                              onTap: isEditing ? _pickDOB : null,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  controller: TextEditingController(
                                    text: selectedDOB?.toLocal().toString().split('T').first ?? '',
                                  ),
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Date of Birth",
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildProfileField(
                            label: "Role",
                            icon: Icons.badge,
                            child: DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: const InputDecoration(
                                labelText: "Role",
                                border: InputBorder.none,
                              ),
                              items: const [
                                DropdownMenuItem(value: "Speaker", child: Text("Speaker")),
                                DropdownMenuItem(value: "Non-Speaker", child: Text("Non-Speaker")),
                              ],
                              onChanged: isEditing ? (val) => setState(() => selectedRole = val!) : null,
                            ),
                          ),
                          const SizedBox(height: 60),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout', style: TextStyle(fontSize: 16)),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
