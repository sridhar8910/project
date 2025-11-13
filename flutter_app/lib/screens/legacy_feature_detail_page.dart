import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyFeatureDetailPage extends StatefulWidget {
  const LegacyFeatureDetailPage({super.key});

  @override
  State<LegacyFeatureDetailPage> createState() =>
      _LegacyFeatureDetailPageState();
}

const _fallbackFeatureDetail = LegacyFeatureDetail(
  title: 'Legacy Feature Detail',
  sections: [
    LegacyFeatureSection(
      heading: 'Overview',
      bullets: [
        'This is the original feature detail demo page.',
        'Content is static and for presentation purposes only.',
      ],
    ),
    LegacyFeatureSection(
      heading: 'Next steps',
      bullets: [
        'Review how stories were structured in the prototype.',
        'Compare against the live feature implementation.',
      ],
    ),
  ],
);

class _LegacyFeatureDetailPageState extends State<LegacyFeatureDetailPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  LegacyFeatureDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.fetchLegacyFeatureDetail();
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _detail = _fallbackFeatureDetail;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _detail = _fallbackFeatureDetail;
        _error = 'Unable to load feature detail. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing cached feature detail: $_error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final detail = _detail ?? _fallbackFeatureDetail;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.title.isEmpty ? 'Legacy Feature Detail' : detail.title),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: detail.sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final section = detail.sections[index];
            return _SectionCard(
              heading: section.heading,
              bullets: section.bullets,
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.heading, required this.bullets});

  final String heading;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 12),
            ...bullets.map((bullet) => _Bullet(text: bullet)),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1B41),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

