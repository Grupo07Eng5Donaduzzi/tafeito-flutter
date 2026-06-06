import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/password_recovery_code_view_model.dart';
import '../widgets/auth_feedback_message.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import 'password_recovery_email_page.dart';
import 'password_recovery_new_password_page.dart';

class PasswordRecoveryCodePage extends StatefulWidget {
  const PasswordRecoveryCodePage({
    required this.email,
    required this.viewModel,
    super.key,
  });

  static const routeName = '/password-recovery/code';

  final String email;
  final PasswordRecoveryCodeViewModel viewModel;

  @override
  State<PasswordRecoveryCodePage> createState() =>
      _PasswordRecoveryCodePageState();
}

class _PasswordRecoveryCodePageState extends State<PasswordRecoveryCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
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
                          'Codigo enviado',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.email,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        AuthTextField(
                          controller: _codeController,
                          label: 'Codigo de verificacao',
                          hintText: 'Codigo recebido por email',
                          textInputAction: TextInputAction.done,
                          validator: _validateCode,
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
                              widget.viewModel.isLoading ? null : _submitCode,
                          child: widget.viewModel.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Verificar codigo'),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: widget.viewModel.isLoading
                                ? null
                                : () {
                                    Navigator.of(context).pushReplacementNamed(
                                      PasswordRecoveryEmailPage.routeName,
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Alterar email',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
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

  Future<void> _submitCode() async {
    widget.viewModel.clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final code = _codeController.text.trim();
    final didVerify = await widget.viewModel.verifyCode(
      email: widget.email,
      code: code,
    );

    if (!mounted || !didVerify) {
      return;
    }

    Navigator.of(context).pushNamed(
      PasswordRecoveryNewPasswordPage.routeName,
      arguments: PasswordRecoveryNewPasswordArgs(
        email: widget.email,
        code: code,
      ),
    );
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.isEmpty) {
      return 'Informe o codigo recebido.';
    }
    if (code.length < 4) {
      return 'Informe um codigo valido.';
    }
    return null;
  }
}
