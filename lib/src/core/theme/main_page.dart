import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/chat_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/home_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/profile_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/services_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/widgets/auth_logo.dart';
import 'package:tafeito_flutter/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    required this.sessionManager,
    required this.profileRepository,
    required this.servicesRepository,
    super.key,
  });

  static const routeName = '/main';

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;
  final ServicesRepository servicesRepository;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      ServicesPage(servicesRepository: widget.servicesRepository),
      const ChatPage(),
      ProfilePage(
        sessionManager: widget.sessionManager,
        profileRepository: widget.profileRepository,
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
