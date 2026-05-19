import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/viewmodels/login_view_model.dart';
import 'features/auth/presentation/viewmodels/register_view_model.dart';
import 'features/auth/presentation/views/login_page.dart';
import 'features/auth/presentation/views/register_page.dart';

class TaFeitoApp extends StatelessWidget {
  const TaFeitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: StubAuthRemoteDataSource(),
    );

    return MaterialApp(
      title: 'TaFeito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RegisterPage.routeName,
      routes: {
        RegisterPage.routeName: (_) => RegisterPage(
              viewModel: RegisterViewModel(authRepository: authRepository),
            ),
        LoginPage.routeName: (_) => LoginPage(
              viewModel: LoginViewModel(authRepository: authRepository),
            ),
      },
    );
  }
}
