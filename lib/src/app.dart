import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/network/api_paths.dart';
import 'core/session/session_guard.dart';
import 'core/session/session_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/main_page.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/viewmodels/login_view_model.dart';
import 'features/auth/presentation/viewmodels/register_view_model.dart';
import 'features/auth/presentation/views/login_page.dart';
import 'features/auth/presentation/views/register_page.dart';
import 'features/auth/presentation/widgets/auth_logo.dart';
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/profile/data/datasources/profile_remote_data_source.dart';
import 'features/profile/data/repositories/profile_repository_impl.dart';
import 'features/quotes/data/datasources/quotes_remote_data_source.dart';
import 'features/quotes/data/repositories/quotes_repository_impl.dart';
import 'features/services/data/datasources/services_remote_data_source.dart';
import 'features/services/data/repositories/services_repository_impl.dart';

class TaFeitoApp extends StatefulWidget {
  const TaFeitoApp({
    this.apiClient,
    this.chatApiClient,
    this.authLocalDataSource,
    this.authRemoteDataSource,
    super.key,
  });

  final ApiClient? apiClient;
  final ApiClient? chatApiClient;
  final AuthLocalDataSource? authLocalDataSource;
  final AuthRemoteDataSource? authRemoteDataSource;

  @override
  State<TaFeitoApp> createState() => _TaFeitoAppState();
}

class _TaFeitoAppState extends State<TaFeitoApp> {
  late final ApiClient _apiClient;
  late final ApiClient _chatApiClient;
  late final SessionManager _sessionManager;
  late final AuthRepositoryImpl _authRepository;
  late final ProfileRepositoryImpl _profileRepository;
  late final ServicesRepositoryImpl _servicesRepository;
  late final QuotesRepositoryImpl _quotesRepository;
  late final ChatRepositoryImpl _chatRepository;
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
          baseUri: Uri.parse(ApiPaths.mainBaseUrl),
          accessTokenProvider: () => _sessionManager.session?.accessToken,
        );
    _chatApiClient = widget.chatApiClient ??
        HttpApiClient(
          baseUri: Uri.parse(ApiPaths.chatBaseUrl),
          accessTokenProvider: () => _sessionManager.session?.accessToken,
        );
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: widget.authRemoteDataSource ??
          ApiAuthRemoteDataSource(apiClient: _apiClient),
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
    _chatRepository = ChatRepositoryImpl(
      remoteDataSource: ApiChatRemoteDataSource(apiClient: _chatApiClient),
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
                      chatRepository: _chatRepository,
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
              viewModel: RegisterViewModel(
                authRepository: _authRepository,
                sessionManager: _sessionManager,
              ),
            ),
        LoginPage.routeName: (_) => LoginPage(
              viewModel: LoginViewModel(
                authRepository: _authRepository,
                sessionManager: _sessionManager,
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
                chatRepository: _chatRepository,
              ),
            ),
      },
    );
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
