import 'package:flutter/material.dart';

class PaymentSuccessFeedback extends StatefulWidget {
  const PaymentSuccessFeedback({super.key});

  @override
  State<PaymentSuccessFeedback> createState() => _PaymentSuccessFeedbackState();
}

class _PaymentSuccessFeedbackState extends State<PaymentSuccessFeedback> {
  @override
  void initState() {
    super.initState();
    // Retorno automático após 3 segundos.
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      // Retorna diretamente para a tela principal (aba Serviços no MainPage).
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGreen = Color(0xFF0FA14B);
    const lightGreenCircle = Color(0xFF4FE38A);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(color: backgroundGreen),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/services',
                    (r) => false,
                  );
                },
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _SuccessIcon(
                    circleColor: lightGreenCircle,
                    iconColor: backgroundGreen,
                  ),
                  SizedBox(height: 14),
                  _SuccessText(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  final Color circleColor;
  final Color iconColor;

  const _SuccessIcon({
    required this.circleColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: iconColor,
        size: 56,
        // check espesso (melhor com ícone de Material padrão)
      ),
    );
  }
}

class _SuccessText extends StatelessWidget {
  const _SuccessText();

  @override
  Widget build(BuildContext context) {
    const color = Colors.white;

    return Text(
      'Pagamento\nconfirmado',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: color,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 0.9, // line-height apertado
        fontFamily: 'sans-serif',
      ),
    );
  }
}

