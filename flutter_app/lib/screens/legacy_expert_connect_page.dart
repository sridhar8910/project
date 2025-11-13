import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyExpertConnectPage extends StatefulWidget {
  const LegacyExpertConnectPage({super.key});

  @override
  State<LegacyExpertConnectPage> createState() =>
      _LegacyExpertConnectPageState();
}

const _fallbackCounsellors = <LegacyCounsellor>[
  LegacyCounsellor(
    name: 'Dr. Aisha Khan',
    expertise: ['Stress', 'Anxiety'],
    rating: 4.8,
    languages: ['English', 'Hindi'],
    tagline: 'Helping you find calm and clarity.',
    isAvailableNow: true,
  ),
  LegacyCounsellor(
    name: 'Rahul Mehta',
    expertise: ['Career', 'Relationship'],
    rating: 4.5,
    languages: ['English', 'Hindi'],
    tagline: 'Guiding you through life’s big decisions.',
    isAvailableNow: false,
  ),
  LegacyCounsellor(
    name: 'Sofia Fernandez',
    expertise: ['Depression', 'Stress'],
    rating: 4.9,
    languages: ['English'],
    tagline: 'Compassionate support for brighter days.',
    isAvailableNow: true,
  ),
];

class _LegacyExpertConnectPageState extends State<LegacyExpertConnectPage> {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<LegacyCounsellor> _counsellors = const [];
  String _searchQuery = '';

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
      final counsellors = await _api.fetchLegacyExperts();
      if (!mounted) return;
      setState(() {
        _counsellors = counsellors;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _counsellors = _fallbackCounsellors;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _counsellors = _fallbackCounsellors;
        _error = 'Unable to load counsellors. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing cached counsellors: $_error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _counsellors.where((c) {
      return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF008D8D),
        title: const Text('Legacy Expert Connect'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search counsellor',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildBody(filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<LegacyCounsellor> filtered) {
    var displayList = List<LegacyCounsellor>.from(filtered);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      // still render list using fallback data
      if (displayList.isEmpty) {
        displayList = _fallbackCounsellors;
      }
    }
    if (displayList.isEmpty) {
      return const Center(
        child: Text('No counsellors match your filters right now.'),
      );
    }
    return ListView.separated(
      itemBuilder: (context, index) =>
          _CounsellorCard(counsellor: displayList[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: displayList.length,
    );
  }
}

class _CounsellorCard extends StatelessWidget {
  const _CounsellorCard({required this.counsellor});

  final LegacyCounsellor counsellor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              counsellor.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0B4A4A),
                                  ),
                            ),
                          ),
                          if (counsellor.isAvailableNow)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Available Now',
                                style: TextStyle(
                                  color: Color(0xFF008D8D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        counsellor.expertise.join(' • '),
                        style: const TextStyle(
                          color: Color(0xFF117575),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${counsellor.rating.toStringAsFixed(1)} / 5'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: counsellor.languages
                  .map(
                    (language) => Chip(
                      label: Text(language),
                      backgroundColor: const Color(0xFFE6F7F7),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              counsellor.tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Connecting with ${counsellor.name} (demo)…',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008D8D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

