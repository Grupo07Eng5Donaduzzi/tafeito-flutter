import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../quotes/data/models/quote_dto.dart';
import '../../../quotes/domain/repositories/quotes_repository.dart';

class PixPaymentPage extends StatefulWidget {
  const PixPaymentPage({
    required this.quote,
    required this.quotesRepository,
    super.key,
  });

  final QuoteDto quote;
  final QuotesRepository quotesRepository;

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  late Future<Result<PaymentCheckDto>> _paymentFuture;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _paymentFuture = widget.quotesRepository.checkPayment(widget.quote.id);
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await widget.quotesRepository.checkPayment(widget.quote.id);
      if (!mounted) return;
      if (result case Success(:final data) when data.paid) {
        _pollingTimer?.cancel();
        _navigateToSuccess();
        return;
      }
      setState(() {
        _paymentFuture = Future.value(result);
      });
    });
  }

  void _navigateToSuccess() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PaymentSuccessPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<PaymentCheckDto>>(
      future: _paymentFuture,
      builder: (context, snapshot) {
        final result = snapshot.data;
        final payment = result is Success<PaymentCheckDto> ? result.data : null;
        final quote = payment?.proposal ?? widget.quote;
        final qrCode = payment?.qrCode ?? quote.qrCode ?? '';
        final qrCodeBase64 = payment?.qrCodeBase64 ?? quote.qrCodeBase64;
        final amount = quote.proposedValue ?? '200,00';
        final status = payment?.status ?? quote.status;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 86,
            leading: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Voltar'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.only(left: 8),
              ),
            ),
            actions: const [],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            children: [
              const Center(
                child: Text(
                  'Pagamento',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(child: _StatusChip(status: status)),
              const SizedBox(height: 18),
              const Text(
                'Qr code',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: _QrImage(
                  qrCodeBase64: qrCodeBase64,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.inputBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'ou copie o código',
                      style: TextStyle(
                        color: AppTheme.textMuted.withAlpha(210),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.inputBorder)),
                ],
              ),
              const SizedBox(height: 10),
              _CopyPixCode(code: qrCode),
              if (result is Failure<PaymentCheckDto>) ...[
                const SizedBox(height: 10),
                Text(
                  result.message,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              const Text(
                'Detalhes do pagamento',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Prestador',
                      value: quote.otherPartyName ?? 'Prestador',
                    ),
                    const Divider(height: 1, color: AppTheme.inputBorder),
                    _DetailRow(label: 'Serviço', value: quote.serviceName),
                    const Divider(height: 1, color: AppTheme.inputBorder),
                    _DetailRow(label: 'Valor', value: 'R\$ $amount'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Como pagar',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const AppCard(
                padding: EdgeInsets.all(14),
                child: Text(
                  '1. Abra o app do seu banco e acesse a área Pix\n'
                  '2. Escolha Pagar com QR Code ou Copia e Cola\n'
                  '3. Confirme o valor e finalize\n'
                  '4. Volte aqui para acompanhar a confirmação',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({
    this.title = 'Pagamento confirmado',
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16A34A),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6EF19A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF16A34A),
                      size: 54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyPixCode extends StatelessWidget {
  const _CopyPixCode({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final displayCode = code.isEmpty ? 'Aguardando código Pix...' : code;
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            width: 76,
            child: ElevatedButton(
              onPressed: code.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código Pix copiado.')),
                      );
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              child: const Text('Copiar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrImage extends StatelessWidget {
  const _QrImage({
    required this.qrCodeBase64,
    required this.isLoading,
  });

  final String? qrCodeBase64;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AppCard(
        padding: EdgeInsets.all(54),
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    final bytes = _tryDecodeBase64(qrCodeBase64);
    if (bytes != null) {
      return AppCard(
        padding: const EdgeInsets.all(10),
        child: Image.memory(bytes, width: 190, height: 190),
      );
    }

    return const _QrPlaceholder();
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      padding: EdgeInsets.all(24),
      child: SizedBox(
        width: 150,
        height: 150,
        child: Stack(
          children: [
            _QrFinder(left: 0, top: 0),
            _QrFinder(right: 0, top: 0),
            _QrFinder(left: 0, bottom: 0),
            _QrDot(left: 92, top: 86),
            _QrDot(left: 118, top: 78),
            _QrDot(left: 72, top: 112),
            _QrDot(left: 108, top: 116),
            _QrDot(left: 132, top: 105),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isPaid = normalized == 'CONFIRMED' ||
        normalized == 'RECEIVED' ||
        normalized == 'ACCEPTED' ||
        normalized == 'COMPLETED';

    return AppPill(
      label: isPaid ? 'Pagamento confirmado' : 'Aguardando pagamento',
      color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB),
      textColor: isPaid ? Colors.white : AppTheme.textPrimary,
    );
  }
}

class _QrFinder extends StatelessWidget {
  const _QrFinder({
    this.left,
    this.top,
    this.right,
    this.bottom,
  });

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrDot extends StatelessWidget {
  const _QrDot({
    required this.left,
    required this.top,
  });

  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF111827),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 18, height: 18),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Uint8List? _tryDecodeBase64(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  final clean = value.contains(',') ? value.split(',').last : value;
  try {
    return base64Decode(clean);
  } on FormatException {
    return null;
  }
}
