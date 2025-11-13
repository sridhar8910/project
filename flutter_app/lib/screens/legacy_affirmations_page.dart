import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';

class LegacyAffirmationsPage extends StatefulWidget {
  const LegacyAffirmationsPage({super.key});

  @override
  State<LegacyAffirmationsPage> createState() =>
      _LegacyAffirmationsPageState();
}

const _defaultAffirmations = [
  'I am worthy of care and respect.',
  'I breathe in calm and exhale tension.',
  'I am capable of handling what comes my way.',
  'I give myself permission to rest and heal.',
];

class _LegacyAffirmationsPageState extends State<LegacyAffirmationsPage> {
  final ApiClient _api = ApiClient();

  List<String> _affirmations = _defaultAffirmations;
  int _index = 0;
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
      final affirmations = await _api.fetchLegacyAffirmations();
      if (!mounted) return;
      setState(() {
        _affirmations =
            affirmations.isEmpty ? _defaultAffirmations : affirmations;
        _index = 0;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _affirmations = _defaultAffirmations;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _affirmations = _defaultAffirmations;
        _error = 'Unable to load affirmations. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Working offline: $_error'),
        ),
      );
    }
  }

  void _next() {
    if (_affirmations.isEmpty) return;
    setState(() => _index = (_index + 1) % _affirmations.length);
  }

  void _prev() {
    if (_affirmations.isEmpty) return;
    setState(
        () => _index = (_index - 1 + _affirmations.length) % _affirmations.length);
  }

  void _copy() {
    if (_affirmations.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _affirmations[_index]));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Affirmation copied (demo)')),
    );
  }

  void _shareMock() {
    if (_affirmations.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share (demo)'),
        content: Text('“${_affirmations[_index]}”'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final affirmation =
        _affirmations.isEmpty ? 'No affirmation available.' : _affirmations[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Affirmations Demo'),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Showing saved affirmations: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                const Text(
                                  'Daily Affirmation',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  affirmation,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: _prev,
                                      icon: const Icon(Icons.arrow_back),
                                    ),
                                    IconButton(
                                      onPressed: _copy,
                                      icon: const Icon(Icons.copy),
                                    ),
                                    IconButton(
                                      onPressed: _shareMock,
                                      icon: const Icon(Icons.share),
                                    ),
                                    IconButton(
                                      onPressed: _next,
                                      icon: const Icon(Icons.arrow_forward),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _affirmations.length,
                            itemBuilder: (context, index) => ListTile(
                              leading: index == _index
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF8B5FBF))
                                  : const Icon(Icons.circle_outlined),
                              title: Text(_affirmations[index]),
                              onTap: () => setState(() => _index = index),
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
      ),
    );
  }
}

