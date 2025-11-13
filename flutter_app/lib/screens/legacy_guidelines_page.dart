import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyGuidelinesPage extends StatefulWidget {
  const LegacyGuidelinesPage({super.key});

  @override
  State<LegacyGuidelinesPage> createState() => _LegacyGuidelinesPageState();
}

const _fallbackGuidelineSections = <LegacyGuidelineSection>[
  LegacyGuidelineSection(
    title: 'Respect & Confidentiality',
    bullets: [
      'Treat all members with dignity and respect.',
      'Never share personal information without consent.',
      'Maintain strict confidentiality of others’ stories.',
      'What is shared in the community stays in the community.',
    ],
  ),
  LegacyGuidelineSection(
    title: 'Responsible Communication',
    bullets: [
      'Use kind and supportive language.',
      'Avoid judgment, criticism, or dismissive comments.',
      'Listen actively and empathetically.',
      'Share personal experiences, not medical advice.',
    ],
  ),
  LegacyGuidelineSection(
    title: 'Privacy & Data Protection',
    bullets: [
      'Your data is encrypted and protected.',
      'We never sell or share personal information.',
      'You can request data deletion anytime.',
      'Anonymous usage options are available.',
    ],
  ),
];

class _LegacyGuidelinesPageState extends State<LegacyGuidelinesPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<LegacyGuidelineSection> _sections = const [];

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
      final response = await _api.fetchLegacyGuidelines();
      if (!mounted) return;
      setState(() {
        _sections = response.sections;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _sections = _fallbackGuidelineSections;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sections = _fallbackGuidelineSections;
        _error = 'Unable to load guidelines. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing cached guidelines: $_error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Guidelines'),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community & Usage Guidelines',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1B41),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our Commitment to a Safe, Supportive Environment',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B8E),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ..._sections.map(
              (section) => _GuidelineSection(
                title: section.title,
                bullets: section.bullets,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBFF),
                borderRadius: BorderRadius.circular(12),
                border: const Border(
                  left: BorderSide(color: Color(0xFF8B5FBF), width: 4),
                ),
              ),
              child: const Text(
                'Need help? Contact support@soulsupport.com or reach out via the in-app help center.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1B41),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineSection extends StatelessWidget {
  const _GuidelineSection({required this.title, required this.bullets});

  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B5FBF),
            ),
          ),
          const SizedBox(height: 8),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF1A1B41))),
                  Expanded(
                    child: Text(
                      bullet,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1B41),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

