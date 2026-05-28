import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tafeito_flutter/src/core/theme/app_theme.dart';
import 'payment_success_feedback.dart';


class PaymentPix extends StatefulWidget {
  const PaymentPix({super.key});

  @override
  State<PaymentPix> createState() => _PaymentPixState();
}

class _PaymentPixState extends State<PaymentPix> {
  static const _pixCodePreview = '00020126580014BR.GOV.BC...';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: null,
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header (left-aligned)
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Voltar',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title principal
              Text(
                'Pagamento',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF171B2A),
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 22),

              // QR code section
              Text(
                'Qr code',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2,
                      size: 120,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Divider with text
              const _MiddleDivider(text: 'ou copie o código'),
              const SizedBox(height: 14),

              // Copy & paste section
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.inputBorder, width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pixCodePreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        // funcao teste para a tela ate que o pix esteja funcional
                        await Clipboard.setData(
                          const ClipboardData(text: _pixCodePreview),
                        );

                        if (!mounted) return;

                        // Navega para a tela de feedback de sucesso.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PaymentSuccessFeedback(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(92, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Copiar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Detalhes do pagamento
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Detalhes do pagamento',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF737B8C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _InfoCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _InfoRow(
                      left: 'Prestador',
                      right: 'Ana Lima',
                    ),
                    _InfoDivider(),
                    _InfoRow(
                      left: 'Serviço',
                      right: 'Plantio de jardim',
                    ),
                    _InfoDivider(),
                    _InfoRow(
                      left: 'Valor',
                      right: 'RS 200,00',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Como pagar
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Como pagar',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF737B8C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              _InfoCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _HowToItem(
                        '1. Abra o app do seu banco e acesse a área Pix',
                      ),
                      SizedBox(height: 10),
                      _HowToItem(
                        '2. Escolha Pagar com QR Code ou Copia e Cola',
                      ),
                      SizedBox(height: 10),
                      _HowToItem(
                        '3. Confirme o valor de RS 200,00 e finalize',
                      ),
                      SizedBox(height: 10),
                      _HowToItem(
                        '4. Volte aqui — o pagamento é confirmado automaticamente',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ));
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inputBorder, width: 1.2),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String left;
  final String right;

  const _InfoRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            right,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 0.9, color: AppTheme.inputBorder);
  }
}

class _HowToItem extends StatelessWidget {
  final String text;

  const _HowToItem(this.text);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Text(
      text,
      style: textTheme.bodyMedium?.copyWith(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
    );
  }
}

class _MiddleDivider extends StatelessWidget {
  final String text;

  const _MiddleDivider({required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Expanded(
          child: Divider(height: 1.0, thickness: 0.9, color: AppTheme.inputBorder),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(
          child: Divider(height: 1.0, thickness: 0.9, color: AppTheme.inputBorder),
        ),
      ],
    );
  }
}

