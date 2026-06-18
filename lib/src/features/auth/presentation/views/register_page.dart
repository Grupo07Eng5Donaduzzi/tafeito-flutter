import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/main_page.dart';
import '../formatters/cpf_cnpj_input_formatter.dart';
import '../viewmodels/register_view_model.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_text_field.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.viewModel, super.key});

  static const routeName = '/register';

  final RegisterViewModel viewModel;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
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
                        const AuthLogo(),
                        const SizedBox(height: 30),
                        Text(
                          'Crie sua conta',
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
                          controller: _nameController,
                          label: 'Nome',
                          hintText: 'Seu nome completo',
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _documentController,
                          label: 'CPF/CNPJ',
                          hintText: '999.999.999-99',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [CpfCnpjInputFormatter()],
                          validator: _validateDocument,
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'email@exemplo.com',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 14),
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
                          onPressed: widget.viewModel.isLoading
                              ? null
                              : _submitRegister,
                          child: widget.viewModel.isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Criar'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Text(
                              'Ja tem conta? ',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed(
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

  Future<void> _submitRegister() async {
    widget.viewModel.clearFeedback();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final didRegister = await widget.viewModel.register(
      name: _nameController.text,
      document: _documentController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || !didRegister) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(MainPage.routeName);
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Informe seu nome.';
    }
    if (name.length < 3) {
      return 'Informe um nome com pelo menos 3 caracteres.';
    }
    return null;
  }

  String? _validateDocument(String? value) {
    final onlyDigits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (onlyDigits.isEmpty) {
      return 'Informe seu CPF ou CNPJ.';
    }
    if (onlyDigits.length != 11 && onlyDigits.length != 14) {
      return 'CPF ou CNPJ deve ter 11 ou 14 digitos.';
    }
    return null;
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
      return 'Informe uma senha.';
    }
    if (password.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
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
