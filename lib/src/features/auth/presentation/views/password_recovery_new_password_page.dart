import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../viewmodels/password_recovery_new_password_view_model.dart';
import '../widgets/auth_feedback_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import 'login_page.dart';

class PasswordRecoveryNewPasswordArgs {
  const PasswordRecoveryNewPasswordArgs({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;
}

class PasswordRecoveryNewPasswordPage extends StatefulWidget {
  const PasswordRecoveryNewPasswordPage({
    required this.args,
    required this.viewModel,
    super.key,
  });

  static const routeName = '/password-recovery/new-password';

  final PasswordRecoveryNewPasswordArgs args;
  final PasswordRecoveryNewPasswordViewModel viewModel;

  @override
  State<PasswordRecoveryNewPasswordPage> createState() =>
      _PasswordRecoveryNewPasswordPageState();
}

class _PasswordRecoveryNewPasswordPageState
    extends State<PasswordRecoveryNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                          'Nova senha',
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
                          controller: _passwordController,
                          label: 'Senha',
                          hintText: '********',
                          obscureText: true,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar senha',
                          hintText: '********',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          validator: _validateConfirmPassword,
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
                          onPressed: widget.viewModel.isLoading
                              ? null
                              : _submitPassword,
                          child: widget.viewModel.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Atualizar senha'),
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

  Future<void> _submitPassword() async {
    widget.viewModel.clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final didReset = await widget.viewModel.resetPassword(
      email: widget.args.email,
      code: widget.args.code,
      newPassword: _passwordController.text,
    );

    if (!mounted || !didReset) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha atualizada com sucesso.')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (route) => false,
    );
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Informe uma senha.';
    }
    if (password.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Confirme sua senha.';
    }
    if (value != _passwordController.text) {
      return 'As senhas nao conferem.';
    }
    return null;
  }
}
