import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/chat_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/home_page.dart';
import 'package:tafeito_flutter/src/features/profile/presentation/views/profile_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/services_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/widgets/auth_logo.dart';
import 'package:tafeito_flutter/src/features/profile/data/models/update_user_request.dart';
import 'package:tafeito_flutter/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:tafeito_flutter/src/features/quotes/domain/repositories/quotes_repository.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    required this.sessionManager,
    required this.profileRepository,
    required this.servicesRepository,
    required this.quotesRepository,
    super.key,
  });

  static const routeName = '/main';

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;
  final ServicesRepository servicesRepository;
  final QuotesRepository quotesRepository;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  bool _isProvider = false;

  @override
  void initState() {
    super.initState();
    _loadProviderStatus();
  }

  Future<void> _loadProviderStatus() async {
    final result = await widget.profileRepository.getMe();
    if (result is Success && mounted) {
      final data = (result as Success).data;
      final pixKey = data.pixKey as String?;
      final isProvider = pixKey != null && pixKey.isNotEmpty;
      if (isProvider != _isProvider) {
        setState(() => _isProvider = isProvider);
      }
    }
  }

  Future<void> _onBecomeProvider(String pixKey) async {
    final userId = widget.sessionManager.session?.user.id ?? '';
    if (userId.isEmpty || pixKey.isEmpty) return;

    final result = await widget.profileRepository.update(
      id: userId,
      request: UpdateUserRequest(pixKey: pixKey),
    );
    if (result is Success && mounted) {
      setState(() => _isProvider = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        sessionManager: widget.sessionManager,
        quotesRepository: widget.quotesRepository,
        servicesRepository: widget.servicesRepository,
        isProvider: _isProvider,
        onBecomeProvider: _onBecomeProvider,
      ),
      ServicesPage(
        servicesRepository: widget.servicesRepository,
        sessionManager: widget.sessionManager,
        quotesRepository: widget.quotesRepository,
        isProvider: _isProvider,
      ),
      const ChatPage(),
      ProfilePage(
        sessionManager: widget.sessionManager,
        profileRepository: widget.profileRepository,
        onPixKeySaved: _loadProviderStatus,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.inputBorder,
            height: 1,
          ),
        ),
        title: const AuthLogo(fontSize: 28),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Servicos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
