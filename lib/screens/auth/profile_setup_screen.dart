import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';
import '../../theme/colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  const ProfileSetupScreen({super.key, required this.userId});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final bioController = TextEditingController();
  bool isPrivate = false;
  File? _image;
  bool isLoading = false;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;

  Future<void> checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      setState(() => _isUsernameAvailable = true);
      return;
    }

    setState(() => _isCheckingUsername = true);

    final existing = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = existing.docs.isEmpty;
    });
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> saveProfile() async {
    final username = usernameController.text.trim();
    final fullName = fullNameController.text.trim();
    final bio = bioController.text.trim();

    if (username.isEmpty || fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields')),
      );
      return;
    }

    if (!_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is not available')),
      );
      return;
    }

    setState(() => isLoading = true);

    String? imageUrl;
    if (_image != null) {
      final ref =
          FirebaseStorage.instance.ref('profile_pics/${widget.userId}.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'isPrivate': isPrivate,
      'profileImageUrl': imageUrl,
      'profileSetupComplete': true,
      'friends': [],
      'friendRequests': [],
      'pendingRequests': [],
      'followers': 0,
      'following': 0,
      'createdAt': Timestamp.now(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUser', widget.userId);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Center(
                child: Text(
                  'Set Up Profile',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tell us a bit more about you.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),

              // Username
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.alternate_email),
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isUsernameAvailable ? Icons.check : Icons.close,
                          color: _isUsernameAvailable ? Colors.green : Colors.red,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    checkUsernameAvailability(value);
                  } else {
                    setState(() => _isUsernameAvailable = true);
                  }
                },
              ),
              const SizedBox(height: 8),
              if (!_isUsernameAvailable && usernameController.text.isNotEmpty)
                const Text(
                  'Username is not available',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              const SizedBox(height: 8),

              // Full Name
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextField(
                controller: bioController,
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Private toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Private Account'),
                value: isPrivate,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => isPrivate = val),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isLoading || !_isUsernameAvailable) ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Finish',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}