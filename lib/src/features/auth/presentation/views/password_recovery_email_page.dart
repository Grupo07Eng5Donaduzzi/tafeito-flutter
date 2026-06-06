import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../viewmodels/password_recovery_email_view_model.dart';
import '../widgets/auth_feedback_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import 'login_page.dart';
import 'password_recovery_code_page.dart';

class PasswordRecoveryEmailPage extends StatefulWidget {
  const PasswordRecoveryEmailPage({
    required this.viewModel,
    super.key,
  });

  static const routeName = '/password-recovery';

  final PasswordRecoveryEmailViewModel viewModel;

  @override
  State<PasswordRecoveryEmailPage> createState() =>
      _PasswordRecoveryEmailPageState();
}

class _PasswordRecoveryEmailPageState extends State<PasswordRecoveryEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
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
                          'Recuperar senha',
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
                          label: 'Email de cadastro',
                          hintText: 'email@exemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 18),
                        if (widget.viewModel.errorMessage != null) ...[
                          AuthFeedbackMessage(
                            message: widget.viewModel.errorMessage!,
                            isError: true,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (widget.viewModel.successMessage != null) ...[
                          AuthFeedbackMessage(
                            message: widget.viewModel.successMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 12),
                        ],
                        ElevatedButton(
                          onPressed:
                              widget.viewModel.isLoading ? null : _submitEmail,
                          child: widget.viewModel.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enviar codigo'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              'Lembrou a senha? ',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            TextButton(
                              onPressed: widget.viewModel.isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context)
                                          .pushReplacementNamed(
                                        LoginPage.routeName,
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Entrar',
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

  Future<void> _submitEmail() async {
    widget.viewModel.clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final didSend = await widget.viewModel.sendCode(email: email);

    if (!mounted || !didSend) {
      return;
    }

    Navigator.of(context).pushNamed(
      PasswordRecoveryCodePage.routeName,
      arguments: email,
    );
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
}
