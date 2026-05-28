import 'package:flutter/material.dart';

import 'paymentPix.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta é a página: SERVIÇOS',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentPix(),
                  ),
                );
              },
              icon: const Icon(Icons.payment_outlined),
              label: const Text('Pagar via PIX'),
            ),
          ),
        ],
      ),
    );
  }
}

