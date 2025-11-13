import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyBreathingPage extends StatefulWidget {
  const LegacyBreathingPage({super.key});

  @override
  State<LegacyBreathingPage> createState() => _LegacyBreathingPageState();
}

const _fallbackBreathingConfig = LegacyBreathingConfig(
  cycleOptions: [4, 5, 6, 8, 10],
  tip:
      'Tip: For calm, try 6–8 second cycles. If you feel lightheaded stop and return to normal breathing.',
);

class _LegacyBreathingPageState extends State<LegacyBreathingPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();

  late AnimationController _controller;
  bool _running = false;
  int _cycleSeconds = 6;
  List<int> _cycleOptions = const [4, 5, 6, 8, 10];
  String? _tip;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _cycleSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && _running) {
        _controller.forward();
      }
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await _api.fetchLegacyBreathingConfig();
      if (!mounted) return;
      final options = config.cycleOptions.isEmpty ? _cycleOptions : config.cycleOptions;
      final defaultSeconds = options.contains(_cycleSeconds) ? _cycleSeconds : options.first;
      setState(() {
        _cycleOptions = options;
        _cycleSeconds = defaultSeconds;
        _controller.duration = Duration(seconds: _cycleSeconds);
        _tip = config.tip;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _applyFallbackConfig();
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _applyFallbackConfig();
        _error = 'Unable to load breathing guidance. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using local breathing guidance: $_error'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    setState(() => _running = true);
    _controller.duration = Duration(seconds: _cycleSeconds);
    _controller.forward(from: 0);
  }

  void _stop() {
    setState(() => _running = false);
    _controller.stop();
    _controller.reset();
  }

  void _applyFallbackConfig() {
    final options = _fallbackBreathingConfig.cycleOptions;
    final defaultSeconds = options.contains(_cycleSeconds)
        ? _cycleSeconds
        : options.first;
    _cycleOptions = options;
    _cycleSeconds = defaultSeconds;
    _controller.duration = Duration(seconds: _cycleSeconds);
    _tip = _fallbackBreathingConfig.tip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Breathing Demo'),
        backgroundColor: const Color(0xFF7B61D9),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Guided Breathing',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Follow the expanding/contracting circle to inhale and exhale. Choose a cycle length and press Start.',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final t = _controller.value;
                            final scale = 0.6 + (0.4 * t);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7FB),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _running
                                        ? (t < 0.5 ? 'Inhale' : 'Exhale')
                                        : 'Ready',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5B3EA6),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _running ? null : _start,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61D9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _running ? _stop : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cycle length',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _cycleSeconds,
                            items: _cycleOptions
                                .map(
                                  (seconds) => DropdownMenuItem(
                                    value: seconds,
                                    child: Text('$seconds s'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _cycleSeconds = value);
                              if (_running) {
                                _controller.duration =
                                    Duration(seconds: _cycleSeconds);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tip ??
                            'Tip: For calm, try 6–8 second cycles. If you feel lightheaded stop and return to normal breathing.',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_loading && _error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Working offline: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

