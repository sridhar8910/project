import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyAdvancedCareSupportPage extends StatefulWidget {
  const LegacyAdvancedCareSupportPage({super.key});

  @override
  State<LegacyAdvancedCareSupportPage> createState() =>
      _LegacyAdvancedCareSupportPageState();
}

const _defaultAdvancedCareResponse = LegacyAdvancedCareResponse(
  services: [
    LegacyAdvancedCareService(
      title: 'Professional Counseling',
      description:
          'Connect with licensed therapists and counselors for personalized support.',
      benefits: [
        'One-on-one sessions',
        'Personalized treatment plans',
        'Confidential support',
        'Flexible scheduling',
      ],
    ),
    LegacyAdvancedCareService(
      title: 'Psychiatric Consultation',
      description:
          'Expert psychiatric evaluation and medication management when needed.',
      benefits: [
        'Clinical assessment',
        'Medication guidance',
        'Crisis intervention',
        'Treatment planning',
      ],
    ),
    LegacyAdvancedCareService(
      title: 'Family Therapy',
      description:
          'Strengthen relationships and improve communication with family members.',
      benefits: [
        'Family sessions',
        'Conflict resolution',
        'Communication skills',
        'Support networks',
      ],
    ),
  ],
  specialists: [
    LegacyAdvancedCareSpecialist(
      name: 'Dr. Sarah Johnson',
      specialization: 'Clinical Psychology',
      experienceYears: 15,
    ),
    LegacyAdvancedCareSpecialist(
      name: 'Dr. Rajesh Patel',
      specialization: 'Psychiatry',
      experienceYears: 12,
    ),
    LegacyAdvancedCareSpecialist(
      name: 'Emma Wilson',
      specialization: 'Family Therapy',
      experienceYears: 10,
    ),
  ],
);

class _LegacyAdvancedCareSupportPageState
    extends State<LegacyAdvancedCareSupportPage> {
  final ApiClient _api = ApiClient();

  List<LegacyAdvancedCareService> _services =
      _defaultAdvancedCareResponse.services;
  List<LegacyAdvancedCareSpecialist> _specialists =
      _defaultAdvancedCareResponse.specialists;

  bool _loading = true;
  String? _error;

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
      final response = await _api.fetchLegacyAdvancedCare();
      if (!mounted) return;
      setState(() {
        _services = response.services;
        _specialists = response.specialists;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _services = _defaultAdvancedCareResponse.services;
        _specialists = _defaultAdvancedCareResponse.specialists;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _services = _defaultAdvancedCareResponse.services;
        _specialists = _defaultAdvancedCareResponse.specialists;
        _error = 'Unable to load advanced care content. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing cached advanced care info: $_error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Advanced Care Support'),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      backgroundColor: const Color(0xFFFDFBFF),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Showing saved advanced care content: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    _buildHero(context),
                    const SizedBox(height: 24),
                    if (_services.isNotEmpty) _buildServiceList(),
                    const SizedBox(height: 24),
                    if (_specialists.isNotEmpty) _buildSpecialists(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF8B5FBF),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Professional Guidance When You Need It',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect with specialized healthcare professionals for comprehensive mental health support and treatment.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking coming soon (demo).')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8B5FBF),
                  ),
                  child: const Text('Book Appointment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Learn More'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1B41),
          ),
        ),
        const SizedBox(height: 16),
        ..._services.map(
          (service) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: service.benefits
                        .map(
                          (benefit) => Chip(
                            label: Text(benefit),
                            backgroundColor: const Color(0xFFF0EBFF),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialists() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Our Specialists',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1B41),
          ),
        ),
        const SizedBox(height: 16),
        ..._specialists.map(
          (specialist) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF8B5FBF).withOpacity(0.15),
                child: Text(
                  specialist.name
                      .split(' ')
                      .map((e) => e[0])
                      .take(2)
                      .join(),
                  style: const TextStyle(color: Color(0xFF8B5FBF)),
                ),
              ),
              title: Text(specialist.name),
              subtitle: Text(
                '${specialist.specialization}\n${specialist.experienceYears}+ years experience',
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }
}

