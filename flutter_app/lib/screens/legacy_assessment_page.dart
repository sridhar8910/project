import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';

class LegacyAssessmentPage extends StatefulWidget {
  const LegacyAssessmentPage({super.key});

  @override
  State<LegacyAssessmentPage> createState() => _LegacyAssessmentPageState();
}

const _fallbackAssessmentQuestions = <LegacyAssessmentQuestion>[
  LegacyAssessmentQuestion(
    question: 'How have you been feeling lately?',
    options: [
      'Very low',
      'Low',
      'Neutral',
      'Positive',
      'Very positive',
    ],
  ),
  LegacyAssessmentQuestion(
    question: 'How is your sleep quality?',
    options: ['Poor', 'Fair', 'Average', 'Good', 'Excellent'],
  ),
  LegacyAssessmentQuestion(
    question: 'How often do you feel anxious?',
    options: ['Rarely', 'Sometimes', 'Often', 'Very often', 'Always'],
  ),
];

const _fallbackAssessmentMessage =
    'Working offline – showing built-in questions.';

class _LegacyAssessmentPageState extends State<LegacyAssessmentPage> {
  final ApiClient _api = ApiClient();

  List<LegacyAssessmentQuestion> _questions =
      _fallbackAssessmentQuestions;
  final Map<int, int> _selectedOptions = {};
  bool _assessmentRunning = false;
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
      _selectedOptions.clear();
    });
    try {
      final questions = await _api.fetchLegacyAssessmentQuestions();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _questions = _fallbackAssessmentQuestions;
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _questions = _fallbackAssessmentQuestions;
        _error = 'Unable to load assessment. ($error)';
        _loading = false;
      });
    }

    if (!mounted) return;
    if (_error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(_fallbackAssessmentMessage),
        ),
      );
    }
  }

  Future<void> _handleAssessment() async {
    if (_questions.isEmpty) {
      return;
    }
    if (_selectedOptions.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before continuing.'),
        ),
      );
      return;
    }

    setState(() => _assessmentRunning = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _assessmentRunning = false);

    final averageScore =
        _selectedOptions.values.reduce((a, b) => a + b) / _questions.length;
    final maxIndex = _maxOptionIndex == 0 ? 1 : _maxOptionIndex;
    final moodScore =
        (averageScore / (maxIndex) * 100).clamp(0, 100).round();
    final feedback = _generateFeedback(moodScore);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your AI Assessment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mood score: $moodScore / 100'),
            const SizedBox(height: 12),
            Text(feedback),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int get _maxOptionIndex {
    if (_questions.isEmpty) return 0;
    return _questions.first.options.length - 1;
  }

  String _generateFeedback(int score) {
    if (score >= 80) {
      return 'You appear to be in a positive and stable mood. Keep nurturing your wellbeing.';
    } else if (score >= 60) {
      return 'You seem slightly stressed but generally balanced. Try a short mindfulness break or journaling.';
    } else if (score >= 40) {
      return 'You may be experiencing some stress or low mood right now. Consider reaching out to a friend or practicing deep breathing.';
    }
    return 'Your responses suggest notable stress or low mood. It might help to speak with someone you trust or a mental health professional.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A78),
        title: const Text('Legacy Assessment Demo'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount:
                    _questions.length + 2 + (_error != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0 && _error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _fallbackAssessmentMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  final offsetIndex = _error != null ? index - 1 : index;
                  if (offsetIndex < _questions.length) {
                    final question = _questions[offsetIndex];
                    final selected = _selectedOptions[offsetIndex];
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ...question.options.asMap().entries.map(
                                  (entry) => RadioListTile<int>(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.value),
                                    value: entry.key,
                                    groupValue: selected,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedOptions[offsetIndex] = value;
                                      });
                                    },
                                  ),
                                ),
                          ],
                        ),
                      ),
                    );
                  } else if (offsetIndex == _questions.length) {
                    return FilledButton.icon(
                      onPressed: _assessmentRunning || _questions.isEmpty
                          ? null
                          : _handleAssessment,
                      icon: const Icon(Icons.analytics),
                      label: const Text('Get my assessment'),
                    );
                  } else {
                    return TextButton(
                      onPressed: _assessmentRunning
                          ? null
                          : () {
                              setState(() {
                                _selectedOptions.clear();
                              });
                            },
                      child: const Text('Reset answers'),
                    );
                  }
                },
              ),
            if (_assessmentRunning)
              Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

