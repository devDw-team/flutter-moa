import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/supabase_service.dart';

class AccountEditScreen extends StatefulWidget {
  const AccountEditScreen({Key? key}) : super(key: key);

  @override
  State<AccountEditScreen> createState() => _AccountEditScreenState();
}

class _AccountEditScreenState extends State<AccountEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService.instance;
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _currencyController = TextEditingController();
  final _localeController = TextEditingController();
  
  String? _avatarUrl;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currencyController.dispose();
    _localeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseService.getUserProfile();
      _userEmail = _supabaseService.currentUser?.email;
      
      if (mounted) {
        setState(() {
          if (profile != null) {
            _nameController.text = profile['full_name'] ?? '';
            _usernameController.text = profile['username'] ?? '';
            _currencyController.text = profile['currency'] ?? 'KRW';
            _localeController.text = profile['locale'] ?? 'ko_KR';
            _avatarUrl = profile['avatar_url'];
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 로드 실패: $e')),
        );
        setState(() => _isLoadingData = false);
      }
    }
  }
  
  String _getValidLocaleValue(String locale) {
    // 유효한 locale 값들
    const validLocales = ['ko_KR', 'en_US', 'ja_JP', 'zh_CN'];
    
    // 빈 값이거나 유효하지 않은 값인 경우 기본값 반환
    if (locale.isEmpty || !validLocales.contains(locale)) {
      // 'ko'와 같은 축약형을 full 형태로 변환
      if (locale == 'ko') return 'ko_KR';
      if (locale == 'en') return 'en_US';
      if (locale == 'ja') return 'ja_JP';
      if (locale == 'zh') return 'zh_CN';
      return 'ko_KR'; // 기본값
    }
    
    return locale;
  }
  
  String _getValidCurrencyValue(String currency) {
    // 유효한 currency 값들
    const validCurrencies = ['KRW', 'USD', 'EUR', 'JPY', 'CNY'];
    
    // 빈 값이거나 유효하지 않은 값인 경우 기본값 반환
    if (currency.isEmpty || !validCurrencies.contains(currency)) {
      return 'KRW'; // 기본값
    }
    
    return currency;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl = _avatarUrl;
      
      // 새 이미지가 선택된 경우 업로드
      if (_imageBytes != null) {
        newAvatarUrl = await _supabaseService.uploadAvatarBytes(_imageBytes!);
      }

      // 프로필 업데이트
      await _supabaseService.supabase
          .from('profiles')
          .update({
            'full_name': _nameController.text.trim(),
            'username': _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
            'currency': _currencyController.text.trim().isEmpty ? 'KRW' : _currencyController.text.trim(),
            'locale': _localeController.text.trim().isEmpty ? 'ko_KR' : _localeController.text.trim(),
            'avatar_url': newAvatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _supabaseService.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 성공적으로 업데이트되었습니다')),
        );
        Navigator.pop(context, true);
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
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('회원정보 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원정보 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : _avatarUrl != null
                              ? NetworkImage(_avatarUrl!) as ImageProvider
                              : null,
                      child: (_imageBytes == null && _avatarUrl == null)
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
                        backgroundColor: Colors.blue,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          color: Colors.white,
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 이메일 (수정 불가)
              TextFormField(
                initialValue: _userEmail,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  helperText: '이메일은 변경할 수 없습니다',
                ),
                enabled: false,
              ),
              
              const SizedBox(height: 16),
              
              // 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '이름',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // 사용자명
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '사용자명 (선택)',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                  helperText: '프로필에 표시될 고유한 사용자명',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 통화
              DropdownButtonFormField<String>(
                value: _getValidCurrencyValue(_currencyController.text),
                decoration: const InputDecoration(
                  labelText: '통화',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'KRW', child: Text('한국 원 (KRW)')),
                  DropdownMenuItem(value: 'USD', child: Text('미국 달러 (USD)')),
                  DropdownMenuItem(value: 'EUR', child: Text('유로 (EUR)')),
                  DropdownMenuItem(value: 'JPY', child: Text('일본 엔 (JPY)')),
                  DropdownMenuItem(value: 'CNY', child: Text('중국 위안 (CNY)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currencyController.text = value ?? 'KRW';
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 언어
              DropdownButtonFormField<String>(
                value: _getValidLocaleValue(_localeController.text),
                decoration: const InputDecoration(
                  labelText: '언어',
                  prefixIcon: Icon(Icons.language),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ko_KR', child: Text('한국어')),
                  DropdownMenuItem(value: 'en_US', child: Text('English')),
                  DropdownMenuItem(value: 'ja_JP', child: Text('日本語')),
                  DropdownMenuItem(value: 'zh_CN', child: Text('中文')),
                ],
                onChanged: (value) {
                  setState(() {
                    _localeController.text = value ?? 'ko_KR';
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}