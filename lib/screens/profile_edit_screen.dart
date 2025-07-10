import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _supabaseService = SupabaseService.instance;
  final _imagePicker = ImagePicker();
  
  File? _imageFile;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseService.getUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['full_name'] ?? '';
          _currentAvatarUrl = profile['avatar_url'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 로드 실패: $e')),
        );
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 실패: $e')),
      );
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      String? avatarUrl = _currentAvatarUrl;
      
      // Upload new image if selected
      if (_imageFile != null) {
        avatarUrl = await _supabaseService.uploadAvatar(_imageFile!);
      }
      
      // Update profile
      await _supabaseService.updateProfile(
        fullName: _nameController.text.trim(),
        avatarUrl: avatarUrl,
      );
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 업데이트되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 업데이트 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              '저장',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : _currentAvatarUrl != null
                            ? NetworkImage(_currentAvatarUrl!) as ImageProvider
                            : null,
                    child: (_imageFile == null && _currentAvatarUrl == null)
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20),
                        color: Colors.white,
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 16),
            
            // Email Field (Read-only)
            TextFormField(
              initialValue: _supabaseService.currentUser?.email ?? '',
              decoration: const InputDecoration(
                labelText: '이메일',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              enabled: false,
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}