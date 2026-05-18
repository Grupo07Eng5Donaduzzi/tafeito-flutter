import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../viewmodels/login_view_model.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import '../../../../core/theme/main_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.viewModel, super.key});

  static const routeName = '/login';

  final LoginViewModel viewModel;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AnimatedBuilder(
                animation: widget.viewModel,
                builder: (context, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 120),
                        const AuthLogo(),
                        const SizedBox(height: 34),
                        Text(
                          'Entrar na conta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 18),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'email@exemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 18),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hintText: '********',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Esqueceu a senha?',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (widget.viewModel.errorMessage != null) ...[
                          _FeedbackMessage(
                            message: widget.viewModel.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.viewModel.successMessage != null) ...[
                          _FeedbackMessage(
                            message: widget.viewModel.successMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed:
                              widget.viewModel.isLoading ? null : _submitLogin,
                          child: widget.viewModel.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Acessar'),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Ainda nao tem conta? ',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
                                  RegisterPage.routeName,
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Registre-se',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    /*
    widget.viewModel.clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await widget.viewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    */

    Navigator.of(context).pushReplacementNamed(MainPage.routeName);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty) {
      return 'Informe seu email.';
    }
    if (!emailRegex.hasMatch(email)) {
      return 'Informe um email valido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Informe sua senha.';
    }
    return null;
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red.shade700 : Colors.green.shade700;

    return Text(
      message,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
