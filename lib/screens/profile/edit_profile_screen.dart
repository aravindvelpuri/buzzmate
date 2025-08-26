import 'dart:io';
import 'package:buzzmate/theme/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentUserData;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.currentUserData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  File? _image;
  bool _isLoading = false;
  bool _isPrivate = false;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  String? _currentProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final data = widget.currentUserData;
    _usernameController.text = data['username'] ?? '';
    _fullNameController.text = data['fullName'] ?? '';
    _bioController.text = data['bio'] ?? '';
    _isPrivate = data['isPrivate'] ?? false;
    _currentProfileImageUrl = data['profileImageUrl'];
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == widget.currentUserData['username']) {
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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _removeProfileImage() async {
    if (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(_currentProfileImageUrl!);
        await ref.delete();
      } catch (e) {
        // ignore error but keep UI responsive
        // print('Error deleting image: $e');
      }
    }

    setState(() {
      _currentProfileImageUrl = null;
      _image = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isUsernameAvailable) return;

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _currentProfileImageUrl;

      // Upload new image if selected
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref('profile_pics/${widget.userId}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }
      // Remove image if it was removed
      else if (_currentProfileImageUrl != null && imageUrl == null) {
        final ref = FirebaseStorage.instance.refFromURL(_currentProfileImageUrl!);
        await ref.delete();
        imageUrl = null;
      }

      final updates = {
        'username': _usernameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'isPrivate': _isPrivate,
        'profileImageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, updates); // Return updated data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildHeader(BuildContext context) {
    final ImageProvider? avatarImage = _image != null
        ? FileImage(_image!)
        : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
            ? NetworkImage(_currentProfileImageUrl!)
            : null);

    return Stack(
      children: [
        // Gradient banner
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Curved white card top
        Positioned.fill(
          top: 140,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset(0, -2),
                    color: Color(0x14000000),
                  )
                ],
              ),
            ),
          ),
        ),
        // Avatar + actions
        Positioned(
  left: 0,
  right: 0,
  top: 50,
  child: Column(
    mainAxisSize: MainAxisSize.min, // <-- prevents overflow
    children: [
      Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  blurRadius: 12,
                  color: Color(0x22000000),
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, size: 48, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _pickImage,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (_currentProfileImageUrl != null &&
          _currentProfileImageUrl!.isNotEmpty)
        TextButton.icon(
          onPressed: _removeProfileImage,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            'Remove Photo',
            style: TextStyle(color: Colors.red),
          ),
        ),
    ],
  ),
),

      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildUsernameAvailability() {
    if (_usernameController.text.isEmpty) return const SizedBox.shrink();
    if (_isCheckingUsername) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Checking availability...'),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: _isUsernameAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              _isUsernameAvailable ? 'Username is available' : 'Username is not available',
              style: TextStyle(
                color: _isUsernameAvailable ? Colors.green : Colors.red,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required Widget child, String? title, String? subtitle, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 18),
                    ),
                  if (icon != null) const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saveBtn = ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.save_outlined),
      label: const Text('Save Changes', style: TextStyle(fontSize: 16)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Username + Full name
                      _buildFormCard(
                        title: 'Basic Info',
                        subtitle: 'Choose how your profile appears across Buzzmate.',
                        icon: Icons.badge_outlined,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: _fieldDecoration(
                                label: 'Username',
                                hint: 'e.g. alex_21',
                                prefixIcon: const Icon(Icons.alternate_email),
                                suffixIcon: _isCheckingUsername
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(2),
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : Icon(
                                        _isUsernameAvailable ? Icons.check : Icons.close,
                                        color: _isUsernameAvailable ? Colors.green : Colors.red,
                                      ),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username is required';
                                }
                                if (value.length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                if (value.isNotEmpty && value != widget.currentUserData['username']) {
                                  _checkUsernameAvailability(value);
                                } else {
                                  setState(() => _isUsernameAvailable = true);
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            _buildUsernameAvailability(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: _fieldDecoration(
                                label: 'Full Name',
                                hint: 'Your display name',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Bio
                      _buildFormCard(
                        title: 'Bio',
                        subtitle: 'Tell people a bit about yourself.',
                        icon: Icons.info_outline,
                        child: TextFormField(
                          controller: _bioController,
                          maxLines: 4,
                          decoration: _fieldDecoration(
                            label: 'Bio (Optional)',
                            hint: "Add a short bio. Example: Coffee lover ☕ • Android dev",
                            prefixIcon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      ),

                      // Privacy
                      _buildFormCard(
                        title: 'Privacy',
                        subtitle: 'Control who can see your content.',
                        icon: Icons.lock_outline,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: SwitchListTile(
                            title: const Text('Private Account'),
                            subtitle: const Text('Only approved followers can see your content'),
                            value: _isPrivate,
                            activeColor: AppColors.primary,
                            onChanged: (value) => setState(() => _isPrivate = value),
                            secondary: const Icon(Icons.privacy_tip_outlined),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom sticky save area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: saveBtn),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
