import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/service_dto.dart';

class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({required this.service, super.key});

  final ServiceDto service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 245,
            pinned: true,
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
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(url: service.imageUrl),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (service.providerName != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE5E7EB),
                          child: Text(
                            service.providerName!.isEmpty
                                ? '?'
                                : service.providerName![0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service.providerName!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      service.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppTheme.inputBorder),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'Avaliações',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF6C515),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        service.rating ?? '5.0',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (service.reviewCount != null)
                        Text(
                          ' (${service.reviewCount})',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppCard(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Color(0xFFF6C515),
                              size: 15,
                            ),
                            Icon(
                              Icons.star,
                              color: Color(0xFFF6C515),
                              size: 15,
                            ),
                            Icon(
                              Icons.star,
                              color: Color(0xFFF6C515),
                              size: 15,
                            ),
                            Icon(
                              Icons.star,
                              color: Color(0xFFF6C515),
                              size: 15,
                            ),
                            Icon(
                              Icons.star,
                              color: Color(0xFFF6C515),
                              size: 15,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Excelente profissional! Muito caprichoso e dedicado no plantio das flores e plantas. O serviço ficou lindo, organizado e deu outra vida ao jardim.',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomBar(service: service),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(color: const Color(0xFFD9DDE2));
    }

    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD9DDE2)),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.service});

  final ServiceDto service;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.inputBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'a partir de',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'R\$ ${service.price}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '/${service.unit ?? "dia"}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 128,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop('request_quote'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Orçamento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
