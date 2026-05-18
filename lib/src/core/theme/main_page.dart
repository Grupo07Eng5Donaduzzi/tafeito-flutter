import 'package:flutter/material.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/home_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/services_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/chat_page.dart';
import 'package:tafeito_flutter/src/features/auth/presentation/views/profile_page.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  static const routeName = '/main';

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // Controla qual página está sendo exibida atualmente
  int _currentIndex = 0;

  // Aqui você pode substituir por suas próprias páginas/widgets
  final List<Widget> _pages = [
    const HomePage(),
    const ServicesPage(),
    const ChatPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        // Linha divisória sutil abaixo do topo
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.inputBorder,
            height: 1.0,
          ),
        ),
        // Aqui vai a representação da Logo no topo
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.primary),
            SizedBox(width: 8),
            Text(
              'TaFeito',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      // O corpo do site muda de acordo com o index da aba inferior
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // fixed é ideal para 4 ou mais itens
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Serviços',
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