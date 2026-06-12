import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/session/session_guard.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/main_page.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/password_recovery_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/viewmodels/login_view_model.dart';
import 'features/auth/presentation/viewmodels/password_recovery_code_view_model.dart';
import 'features/auth/presentation/viewmodels/password_recovery_email_view_model.dart';
import 'features/auth/presentation/viewmodels/password_recovery_new_password_view_model.dart';
import 'features/auth/presentation/viewmodels/register_view_model.dart';
import 'features/auth/presentation/views/login_page.dart';
import 'features/auth/presentation/views/password_recovery_code_page.dart';
import 'features/auth/presentation/views/password_recovery_email_page.dart';
import 'features/auth/presentation/views/password_recovery_new_password_page.dart';
import 'features/auth/presentation/views/register_page.dart';
import 'features/auth/presentation/widgets/auth_logo.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/quotes/data/datasources/quotes_remote_data_source.dart';
import 'features/quotes/data/repositories/quotes_repository_impl.dart';
import 'features/services/data/datasources/services_remote_data_source.dart';
import 'features/services/data/repositories/services_repository_impl.dart';

class TaFeitoApp extends StatefulWidget {
  const TaFeitoApp({
    this.apiClient,
    this.authLocalDataSource,
    this.authRemoteDataSource,
    this.passwordRecoveryRemoteDataSource,
    super.key,
  });

  final ApiClient? apiClient;
  final AuthLocalDataSource? authLocalDataSource;
  final AuthRemoteDataSource? authRemoteDataSource;
  final PasswordRecoveryRemoteDataSource? passwordRecoveryRemoteDataSource;

  @override
  State<TaFeitoApp> createState() => _TaFeitoAppState();
}

class _TaFeitoAppState extends State<TaFeitoApp> {
  late final ApiClient _apiClient;
  late final SessionManager _sessionManager;
  late final AuthRepositoryImpl _authRepository;
  late final ProfileRepositoryImpl _profileRepository;
  late final ServicesRepositoryImpl _servicesRepository;
  late final QuotesRepositoryImpl _quotesRepository;
  late final Future<void> _sessionInitialization;

  @override
  void initState() {
    super.initState();

    _sessionManager = SessionManager(
      localDataSource:
          widget.authLocalDataSource ?? SecureAuthLocalDataSource(),
    );
    _apiClient = widget.apiClient ??
        HttpApiClient(
          accessTokenProvider: () => _sessionManager.session?.accessToken,
        );
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: widget.authRemoteDataSource ??
          ApiAuthRemoteDataSource(apiClient: _apiClient),
      passwordRecoveryRemoteDataSource:
          widget.passwordRecoveryRemoteDataSource ??
              _defaultPasswordRecoveryRemoteDataSource(),
    );
    _profileRepository = ProfileRepositoryImpl(
      remoteDataSource: ApiProfileRemoteDataSource(apiClient: _apiClient),
    );
    _servicesRepository = ServicesRepositoryImpl(
      remoteDataSource: ApiServicesRemoteDataSource(apiClient: _apiClient),
    );
    _quotesRepository = QuotesRepositoryImpl(
      remoteDataSource: ApiQuotesRemoteDataSource(apiClient: _apiClient),
    );
    _sessionInitialization = _sessionManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaFeito',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => FutureBuilder<void>(
              future: _sessionInitialization,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const _AuthSplashPage();
                }

                if (_sessionManager.isAuthenticated) {
                  return SessionGuard(
                    sessionManager: _sessionManager,
                    redirectRoute: LoginPage.routeName,
                    child: MainPage(
                      sessionManager: _sessionManager,
                      profileRepository: _profileRepository,
                      servicesRepository: _servicesRepository,
                      quotesRepository: _quotesRepository,
                    ),
                  );
                }

                return LoginPage(
                  viewModel: LoginViewModel(
                    authRepository: _authRepository,
                    sessionManager: _sessionManager,
                  ),
                );
              },
            ),
        RegisterPage.routeName: (_) => RegisterPage(
              viewModel: RegisterViewModel(authRepository: _authRepository),
            ),
        LoginPage.routeName: (_) => LoginPage(
              viewModel: LoginViewModel(
                authRepository: _authRepository,
                sessionManager: _sessionManager,
              ),
            ),
        PasswordRecoveryEmailPage.routeName: (_) => PasswordRecoveryEmailPage(
              viewModel: PasswordRecoveryEmailViewModel(
                authRepository: _authRepository,
              ),
            ),
        PasswordRecoveryCodePage.routeName: (context) =>
            PasswordRecoveryCodePage(
              email: _readEmailArgument(context),
              viewModel: PasswordRecoveryCodeViewModel(
                authRepository: _authRepository,
              ),
            ),
        PasswordRecoveryNewPasswordPage.routeName: (context) =>
            PasswordRecoveryNewPasswordPage(
              args: _readNewPasswordArguments(context),
              viewModel: PasswordRecoveryNewPasswordViewModel(
                authRepository: _authRepository,
              ),
            ),
        MainPage.routeName: (_) => SessionGuard(
              sessionManager: _sessionManager,
              redirectRoute: LoginPage.routeName,
              child: MainPage(
                sessionManager: _sessionManager,
                profileRepository: _profileRepository,
                servicesRepository: _servicesRepository,
                quotesRepository: _quotesRepository,
              ),
            ),
      },
    );
  }

  String _readEmailArgument(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String) {
      return arguments;
    }

    return '';
  }

  PasswordRecoveryNewPasswordArgs _readNewPasswordArguments(
    BuildContext context,
  ) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is PasswordRecoveryNewPasswordArgs) {
      return arguments;
    }

    return const PasswordRecoveryNewPasswordArgs(email: '', code: '');
  }

  PasswordRecoveryRemoteDataSource _defaultPasswordRecoveryRemoteDataSource() {
    if (Firebase.apps.isNotEmpty) {
      return FirebasePasswordRecoveryRemoteDataSource();
    }

    return StubPasswordRecoveryRemoteDataSource();
  }
}

class _AuthSplashPage extends StatelessWidget {
  const _AuthSplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthLogo(),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
