import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/supabase_service.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _userProfile;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    final profile = await _supabaseService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = _supabaseService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          InkWell(
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
              if (result == true) {
                _loadUserProfile();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _userProfile?['avatar_url'] != null
                        ? NetworkImage(_userProfile!['avatar_url'])
                        : null,
                    child: _userProfile?['avatar_url'] == null
                        ? Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userProfile?['full_name'] ?? user?.email ?? '사용자',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          
          // Settings List
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('카테고리 관리'),
            subtitle: const Text('수입/지출 카테고리를 관리합니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('카테고리 관리 기능은 준비 중입니다')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            subtitle: const Text('예산 초과 알림 등을 설정합니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 설정 기능은 준비 중입니다')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('데이터 백업'),
            subtitle: const Text('데이터를 백업하고 복원합니다'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('백업 기능은 준비 중입니다')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('보안 설정'),
            subtitle: const Text('앱 잠금 및 보안 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('보안 설정 기능은 준비 중입니다')),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            subtitle: const Text('버전 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '모아 Lite',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 모아 Lite',
                children: const [
                  Text('\n개인 가계부 앱'),
                  Text('Flutter + Supabase로 제작되었습니다.'),
                ],
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('도움말'),
            subtitle: const Text('앱 사용법 및 FAQ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('도움말은 준비 중입니다')),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('로그아웃'),
                  content: const Text('정말 로그아웃 하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && mounted) {
                final authProvider = context.read<AuthProvider>();
                try {
                  await authProvider.signOut();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃 실패: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}