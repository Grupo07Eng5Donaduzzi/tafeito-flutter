import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'package:tafeito_flutter/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:tafeito_flutter/src/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:tafeito_flutter/src/features/quotes/data/models/quote_dto.dart';
import 'package:tafeito_flutter/src/features/quotes/domain/repositories/quotes_repository.dart';

import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    required this.sessionManager,
    required this.profileRepository,
    this.quotesRepository,
    this.isProvider = false,
    this.onPixKeySaved,
    super.key,
  });

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;
  final QuotesRepository? quotesRepository;
  final bool isProvider;
  final VoidCallback? onPixKeySaved;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? _profileImageBytes;
  late final ProfileViewModel _viewModel;
  late Future<_PaymentData> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel(
      profileRepository: widget.profileRepository,
    )..loadMe();
    _paymentsFuture = _loadPayments();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isProvider != widget.isProvider) {
      setState(() => _paymentsFuture = _loadPayments());
    }
  }

  Future<_PaymentData> _loadPayments() async {
    final repo = widget.quotesRepository;
    if (repo == null) return const _PaymentData([], []);

    final results = await Future.wait([
      repo.getClientHistory(),
      if (widget.isProvider) repo.getProviderHistory(),
    ]);

    final clientHistory = switch (results[0]) {
      Success<List<QuoteDto>>(:final data) => data,
      _ => <QuoteDto>[],
    };
    final providerHistory = (widget.isProvider && results.length > 1)
        ? switch (results[1]) {
            Success<List<QuoteDto>>(:final data) => data,
            _ => <QuoteDto>[],
          }
        : <QuoteDto>[];

    return _PaymentData(clientHistory, providerHistory);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _profileImageBytes = bytes;
    });
    await _viewModel.uploadAvatar(bytes: bytes, fileName: picked.name);
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

  Future<void> _save() async {
    final hadPixKey = _viewModel.me?.pixKey?.isNotEmpty ?? false;
    await _viewModel.save();
    if (_viewModel.errorMessage == null && !hadPixKey) {
      final nowHasPixKey = _viewModel.me?.pixKey?.isNotEmpty ?? false;
      if (nowHasPixKey) widget.onPixKeySaved?.call();
    }
  }

  Future<void> _downloadInvoice(BuildContext context, String proposalId) async {
    final repo = widget.quotesRepository;
    if (repo == null) return;

    final result = await repo.downloadInvoice(proposalId);
    if (!context.mounted) return;

    switch (result) {
      case Success<Uint8List>(:final data):
        try {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/nota_fiscal_$proposalId.pdf');
          await file.writeAsBytes(data);
          await OpenFilex.open(file.path);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Não foi possível abrir a nota fiscal.')),
            );
          }
        }
      case Failure(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    if (_viewModel.isLoading) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Excluir conta'),
        content: const Text(
          'Tem certeza que deseja excluir sua conta? Esta acao nao pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await _viewModel.deleteAccount();
    if (!context.mounted || !deleted) {
      return;
    }

    await widget.sessionManager.logout();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginPage.routeName,
      (route) => false,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.me == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
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
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : (_viewModel.me?.avatarUrl != null
                                ? NetworkImage(_viewModel.me!.avatarUrl!)
                                : null),
                        child: _profileImageBytes == null &&
                                _viewModel.me?.avatarUrl == null
                            ? const Icon(Icons.person, size: 42)
                            : null,
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
              if (widget.isProvider) ...[
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Chave Pix',
                  hintText: 'CPF, email, celular ou chave aleatoria',
                  controller: _viewModel.pixKeyController,
                ),
              ],
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
                onPressed: _viewModel.isLoading ? null : _save,
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
                label: 'Senha atual',
                hintText: 'Digite a senha atual',
                isPassword: true,
                controller: _viewModel.currentPasswordController,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Nova senha',
                hintText: 'Digite a nova senha',
                isPassword: true,
                controller: _viewModel.newPasswordController,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                label: 'Confirmar nova senha',
                hintText: 'Repita a nova senha',
                isPassword: true,
                controller: _viewModel.confirmNewPasswordController,
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
              if (_viewModel.successMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _viewModel.successMessage!,
                  style: const TextStyle(
                    color: Color(0xFF16A34A),
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
                onPressed: _viewModel.isLoading
                    ? null
                    : () async {
                        await _viewModel.changePassword();
                      },
                child: _viewModel.isLoading
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
              FutureBuilder<_PaymentData>(
                future: _paymentsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    );
                  }
                  final data = snapshot.data ?? const _PaymentData([], []);
                  return _PaymentSections(
                    clientHistory: data.clientHistory,
                    providerHistory: data.providerHistory,
                    isProvider: widget.isProvider,
                    onDownloadInvoice: (proposalId) =>
                        _downloadInvoice(context, proposalId),
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

                  if (!context.mounted) {
                    return;
                  }

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
                onPressed: () => _deleteAccount(context),
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
}

class _PaymentData {
  const _PaymentData(this.clientHistory, this.providerHistory);
  final List<QuoteDto> clientHistory;
  final List<QuoteDto> providerHistory;
}

class _PaymentSections extends StatelessWidget {
  const _PaymentSections({
    required this.clientHistory,
    required this.providerHistory,
    required this.isProvider,
    required this.onDownloadInvoice,
  });

  final List<QuoteDto> clientHistory;
  final List<QuoteDto> providerHistory;
  final bool isProvider;
  final void Function(String proposalId) onDownloadInvoice;

  @override
  Widget build(BuildContext context) {
    if (clientHistory.isEmpty && providerHistory.isEmpty) {
      return const Text('Nenhum pagamento registrado.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isProvider) ...[
          const Text(
            'Pagamentos realizados',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
        ],
        if (clientHistory.isEmpty)
          const Text('Nenhum pagamento realizado.')
        else
          ...clientHistory.map((q) => _PaymentItem(
                quote: q,
                onDownloadInvoice: q.invoiceFile != null
                    ? () => onDownloadInvoice(q.id)
                    : null,
              )),
        if (isProvider) ...[
          const SizedBox(height: 20),
          const Text(
            'Recebimentos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (providerHistory.isEmpty)
            const Text('Nenhum recebimento registrado.')
          else
            ...providerHistory.map((q) => _PaymentItem(
                  quote: q,
                  onDownloadInvoice: null,
                )),
        ],
      ],
    );
  }
}

class _PaymentItem extends StatelessWidget {
  const _PaymentItem({
    required this.quote,
    this.onDownloadInvoice,
  });

  final QuoteDto quote;
  final VoidCallback? onDownloadInvoice;

  String get _formattedDate {
    try {
      final dt = DateTime.parse(quote.createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return quote.createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherParty = quote.otherPartyName ?? 'Contato';
    final amount = quote.proposedValue != null
        ? 'R\$ ${double.tryParse(quote.proposedValue!)?.toStringAsFixed(2) ?? quote.proposedValue}'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$otherParty · $_formattedDate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (amount.isNotEmpty)
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
            ],
          ),
          if (onDownloadInvoice != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onDownloadInvoice,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_outlined,
                      size: 16, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text(
                    'Ver nota fiscal',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
