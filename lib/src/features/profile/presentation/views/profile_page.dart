import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:tafeito_flutter/src/features/profile/presentation/viewmodels/profile_view_model.dart';

import '../../../auth/presentation/views/login_page.dart';

import '../../domain/repositories/profile_delete_repository.dart';
import '../../data/datasources/profile_delete_remote_data_source.dart';
import '../../data/repositories/profile_delete_repository_impl.dart';
import '../../presentation/viewmodels/profile_delete_view_model.dart';
import '../../../../core/network/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.sessionManager,
    required this.profileRepository,
    super.key,
  });

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;

  late final ProfileViewModel _viewModel;
  late final Future<List<MockPayment>> _paymentsFuture;

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isUpdatingPassword = false;
  String? _passwordErrorMessage;

  @override
  void initState() {
    super.initState();

    _viewModel = ProfileViewModel(
      profileRepository: widget.profileRepository,
    )..loadMe();

    _paymentsFuture = _fetchMockPaymentsFromApi();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _profileImageBytes = bytes;
    });
  }

  void _showEditPhotoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppTheme.textPrimary,
                ),
                title: const Text(
                  'Escolher da galeria',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDeleteAccount() async {
    // Confirmação para evitar exclusão acidental.
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conta'),
          content: const Text(
            'Tem certeza que deseja excluir sua conta? Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    if (_viewModel.me == null) return;

    // Delete no backend é no controller Users: DELETE /v1/users/:id
    // Aqui não temos o ApiClient do app via DI, então instanciamos uma implementação HTTP.
    // (Se você já usa um ApiClient configurado no TaFeitoApp, o ideal é injetar o ProfileDeleteViewModel.)
    final deleteViewModel = ProfileDeleteViewModel(
      deleteRepository: ProfileDeleteRepositoryImpl(
        remoteDataSource: ApiProfileDeleteRemoteDataSource(
          apiClient: HttpApiClient(
            accessTokenProvider: () => widget.sessionManager.session?.accessToken,
          ),
        ),
      ),
    );

    final deleted = await deleteViewModel.deleteAccount(
      id: _viewModel.me!.id,
    );

    if (!mounted) return;

    if (!deleted) {
      final msg = deleteViewModel.errorMessage ?? 'Nao foi possivel excluir sua conta agora.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    await widget.sessionManager.logout();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (route) => false,
    );
  }

  Future<void> _updatePassword() async {

    setState(() {
      _passwordErrorMessage = null;
      _isUpdatingPassword = true;
    });

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Mantém a mesma lógica de validação do fluxo de recuperação de senha.
    if (newPassword.isEmpty) {
      setState(() {
        _passwordErrorMessage = 'Informe uma senha.';
        _isUpdatingPassword = false;
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _passwordErrorMessage = 'A senha deve ter pelo menos 6 caracteres.';
        _isUpdatingPassword = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _passwordErrorMessage = 'As senhas nao conferem.';
        _isUpdatingPassword = false;
      });
      return;
    }

    try {
      await _viewModel.changePassword(
        currentPassword: '',
        newPassword: newPassword,
      );

      if (!mounted) return;

      setState(() {
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _passwordErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordErrorMessage = 'Nao foi possivel atualizar a senha agora.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.me == null) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _profileImageBytes == null
                            ? const NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                              )
                            : MemoryImage(_profileImageBytes!),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          width: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.edit_square,
                              size: 16,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _showEditPhotoModal(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Informacoes pessoais',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Nome',
                controller: _viewModel.nameController,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Email',
                controller: _viewModel.emailController,
              ),
              if (_viewModel.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _viewModel.isLoading ? null : _viewModel.save,
                child: _viewModel.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar alteracoes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Seguranca',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Nova senha',
                hintText: 'Digite a nova senha',
                isPassword: true,
                controller: _newPasswordController,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Confirmar nova senha',
                hintText: 'Repita a nova senha',
                isPassword: true,
                controller: _confirmPasswordController,
              ),
              if (_passwordErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _passwordErrorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _isUpdatingPassword ? null : _updatePassword,
                child: _isUpdatingPassword
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Atualizar senha',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Pagamentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<MockPayment>>(
                future: _paymentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar os pagamentos.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  final payments = snapshot.data ?? [];
                  if (payments.isEmpty) {
                    return const Text('Nenhum pagamento registrado.');
                  }

                  return Column(
                    children: payments
                        .map((payment) => _buildPaymentItem(payment))
                        .toList(),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 20),
                child: Divider(color: Color(0xFFF3F4F6)),
              ),
              const Text(
                'Opcoes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildOptionButton(
                label: 'Sair da conta',
                backgroundColor: const Color(0xFFD1D5DB),
                textColor: AppTheme.textPrimary,
                iconColor: const Color(0xFF4B5563),
                onPressed: () async {
                  await widget.sessionManager.logout();

                  if (!context.mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginPage.routeName,
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildOptionButton(
                label: 'Excluir conta',
                backgroundColor: const Color(0xFFE55B4B),
                textColor: Colors.white,
                iconColor: Colors.white,
                onPressed: () => _confirmAndDeleteAccount(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    String? hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(MockPayment payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payment.authorDate,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Text(
            payment.amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<MockPayment>> _fetchMockPaymentsFromApi() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    return [
      MockPayment(
        title: 'Plantio de jardim',
        authorDate: 'Ana - 18/03/2026',
        amount: 'R\$ 100,00',
      ),
      MockPayment(
        title: 'Poda de arvore',
        authorDate: 'Carlos - 15/03/2026',
        amount: 'R\$ 250,00',
      ),
    ];
  }
}

class MockPayment {
  MockPayment({
    required this.title,
    required this.authorDate,
    required this.amount,
  });

  final String title;
  final String authorDate;
  final String amount;
}

