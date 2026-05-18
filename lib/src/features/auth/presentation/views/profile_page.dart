import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Modelo para puxar os itens da API posteriormente
    // final userData = context.watch<ProfileViewModel>().user;
    final String userName = ''; // userData?.name ?? ''
    final String userEmail = ''; // userData?.email ?? ''

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto de Perfil com Botão de Edição
          Center(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F66F6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.edit_square, size: 16, color: Colors.white),
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

          // Seção: Informações Pessoais
          const Text(
            'Informações pessoais',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInputField(label: 'Nome', initialValue: userName),
          const SizedBox(height: 16),
          _buildInputField(label: 'Email', initialValue: userEmail),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F66F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              // Ação salvar alterações
            },
            child: const Text('Salvar alterações', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF3F4F6)),
          ),

          // Seção: Segurança
          const Text(
            'Segurança',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInputField(label: 'Senha atual', hintText: 'Digite a senha atual', isPassword: true),
          const SizedBox(height: 16),
          _buildInputField(label: 'Nova senha', hintText: 'Digite a nova senha', isPassword: true),
          const SizedBox(height: 16),
          _buildInputField(label: 'Confirmar nova senha', hintText: 'Repita a nova senha', isPassword: true),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F66F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () {
              // Ação atualizar senha
            },
            child: const Text('Atualizar senha', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF3F4F6)),
          ),

          // Seção: Pagamentos
          const Text(
            'Pagamentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Implementação do FutureBuilder para simular a requisição de API
          FutureBuilder<List<MockPayment>>(
            future: _fetchMockPaymentsFromApi(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF2F66F6)));
              }
              
              if (snapshot.hasError) {
                return const Text('Erro ao carregar os pagamentos.', style: TextStyle(color: Colors.red));
              }

              final payments = snapshot.data ?? [];
              if (payments.isEmpty) {
                return const Text('Nenhum pagamento registrado.');
              }

              return Column(
                children: payments.map((payment) => _buildPaymentItem(payment)).toList(),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 20),
            child: Divider(color: Color(0xFFF3F4F6)),
          ),

          // Seção: Opções
          const Text(
            'Opções',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Botão Sair da conta
          _buildOptionButton(
            label: 'Sair da conta',
            backgroundColor: const Color(0xFFD1D5DB),
            textColor: const Color(0xFF1F2937),
            iconColor: const Color(0xFF4B5563),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 12),
          
          // Botão Excluir conta
          _buildOptionButton(
            label: 'Excluir conta',
            backgroundColor: const Color(0xFFE55B4B),
            textColor: Colors.white,
            iconColor: Colors.white,
            onPressed: () {
              // Ação excluir
            },
          ),
        ],
      ),
    );
  }

  // Modal de edição de foto padrão de mercado
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
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1F2937)),
                title: const Text('Tirar foto', style: TextStyle(color: Color(0xFF1F2937))),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar ImagePicker com ImageSource.camera
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1F2937)),
                title: const Text('Escolher da galeria', style: TextStyle(color: Color(0xFF1F2937))),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar ImagePicker com ImageSource.gallery
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper para construir os inputs (Campos de texto)
  Widget _buildInputField({
    required String label,
    String? initialValue,
    String? hintText,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2F66F6), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper para construir os botões de Opções da parte inferior
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }

  // Helper para construir a UI de um único item de pagamento 
  // (Extraído para facilitar a replicação com os dados da API)
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              Text(
                payment.authorDate,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          Text(
            payment.amount,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }

  // Substituir por uma chamada real ao Repositório/ViewModel no futuro
  Future<List<MockPayment>> _fetchMockPaymentsFromApi() async {
    // Simulando atraso de requisição de rede de 1.5 segundos
    await Future.delayed(const Duration(milliseconds: 1500));
    
    return [
      MockPayment(title: 'Plantio de jardim', authorDate: 'Ana  •  18/03/2026', amount: 'R\$ 100,00'),
      MockPayment(title: 'Poda de árvore', authorDate: 'Carlos  •  15/03/2026', amount: 'R\$ 250,00'),
    ];
  }
}

// Modelo Fake de Pagamento para simular a resposta da API
class MockPayment {
  final String title;
  final String authorDate;
  final String amount;

  MockPayment({required this.title, required this.authorDate, required this.amount});
}