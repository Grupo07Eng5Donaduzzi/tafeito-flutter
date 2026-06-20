import 'package:flutter/material.dart';

import '../../../../core/result/result.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../data/models/service_dto.dart';
import '../../domain/repositories/services_repository.dart';

class ServiceDetailPage extends StatefulWidget {
  const ServiceDetailPage({
    required this.service,
    required this.servicesRepository,
    super.key,
  });

  final ServiceDto service;
  final ServicesRepository servicesRepository;

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  late ServiceDto _service;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final result = await widget.servicesRepository.findById(widget.service.id);
    if (mounted) {
      setState(() {
        if (result case Success(:final data)) _service = data;
        _loading = false;
      });
    }
  }

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
              background: _HeroImage(url: _service.imageUrl),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  if (_service.providerName != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE5E7EB),
                          child: Text(
                            _service.providerName!.isEmpty
                                ? '?'
                                : _service.providerName![0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _service.providerName!,
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
                    _service.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_service.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _service.description,
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
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    _ReviewsSection(service: _service),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _BottomBar(service: _service),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.service});

  final ServiceDto service;

  @override
  Widget build(BuildContext context) {
    final hasRating = service.rating != null;
    final hasReviews = service.reviews.isNotEmpty;

    if (!hasRating && !hasReviews) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Nenhuma avaliação ainda.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (hasRating) ...[
              const Icon(Icons.star, color: Color(0xFFF6C515), size: 16),
              const SizedBox(width: 4),
              Text(
                service.rating!,
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
          ],
        ),
        if (hasReviews) ...[
          const SizedBox(height: 12),
          ...service.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReviewCard(review: r),
              )),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ReviewDto review;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFF6C515),
                size: 15,
              );
            }),
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
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
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop('request_quote'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(148, 48),
              ),
              child: const Text('Orçamento', maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
