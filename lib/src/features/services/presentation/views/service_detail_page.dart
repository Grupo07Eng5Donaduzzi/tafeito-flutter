import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: service.imageUrl != null
                  ? Image.network(
                      service.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE5E7EB),
                      ),
                    )
                  : Container(color: const Color(0xFFE5E7EB)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.providerName != null) ...[
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFE5E7EB),
                          child: Icon(Icons.person, size: 18, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          service.providerName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (service.rating != null) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Avaliacoes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text(
                          service.rating!,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (service.reviewCount != null)
                          Text(
                            ' (${service.reviewCount})',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ],
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.service});

  final ServiceDto service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.inputBorder)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'a partir de',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              Text(
                'R\$ ${service.price}/${service.unit ?? "dia"}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop('request_quote'),
              child: const Text('Orcamento'),
            ),
          ),
        ],
      ),
    );
  }
}
