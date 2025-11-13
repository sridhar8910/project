import 'package:flutter/material.dart';

class LegacyJournalPage extends StatefulWidget {
  const LegacyJournalPage({super.key});

  @override
  State<LegacyJournalPage> createState() => _LegacyJournalPageState();
}

class JournalEntry {
  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    this.mood,
  });

  final String id;
  final DateTime date;
  String content;
  String? mood;
}

class _LegacyJournalPageState extends State<LegacyJournalPage> {
  final TextEditingController _journalController = TextEditingController();
  String? _selectedMood;
  DateTime _selectedDate = DateTime.now();
  JournalEntry? _editingEntry;
  bool _isEditing = false;

  final List<JournalEntry> _entries = [];

  final Map<String, String> _moods = const {
    'Happy': '😊',
    'Calm': '😌',
    'Neutral': '😐',
    'Stressed': '😓',
    'Sad': '😢',
  };

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    final content = _journalController.text.trim();
    if (content.isEmpty) {
      return;
    }

    setState(() {
      if (_isEditing && _editingEntry != null) {
        _editingEntry!.content = content;
        _editingEntry!.mood = _selectedMood;
      } else {
        _entries.insert(
          0,
          JournalEntry(
            id: DateTime.now().toIso8601String(),
            date: _selectedDate,
            content: content,
            mood: _selectedMood,
          ),
        );
      }

      _journalController.clear();
      _selectedMood = null;
      _selectedDate = DateTime.now();
      _editingEntry = null;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal entry saved (local demo)'),
        backgroundColor: Color(0xFF8B5FBF),
      ),
    );
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _isEditing = true;
      _editingEntry = entry;
      _journalController.text = entry.content;
      _selectedMood = entry.mood;
      _selectedDate = entry.date;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getPreviewText(String content) {
    final lines = content.split('\n');
    if (lines.length > 2) {
      return '${lines[0]}\n${lines[1]}...';
    }
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Legacy Journal Demo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateSelector(context),
                  const SizedBox(height: 20),
                  _buildMoodSelector(),
                  const SizedBox(height: 20),
                  _buildEditor(),
                  const SizedBox(height: 24),
                  _buildPreviousEntries(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B5FBF), Color(0xFF9E8BE3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legacy Journal Demo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This page stores entries in-memory only, showcasing the original static UI.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 12),
          Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _selectDate(context),
            child: const Text(
              'Change Date',
              style: TextStyle(color: Color(0xFF8B5FBF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How are you feeling?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _moods.entries.map((mood) {
              final selected = _selectedMood == mood.key;
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.value, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      mood.key,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? const Color(0xFF8B5FBF) : Colors.grey,
                      ),
                    ),
                  ],
                ),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    _selectedMood = value ? mood.key : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _journalController,
              maxLines: 8,
              minLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write about your day, emotions, or insights...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveEntry,
              child: Text(_isEditing ? 'Update Entry' : 'Save Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousEntries() {
    if (_entries.isEmpty) {
      return const _EmptyState(
        message: 'No journal entries yet. Add a note above to begin.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous entries',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        ..._entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                subtitle: Text(
                  _getPreviewText(entry.content),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF8B5FBF)),
                  onPressed: () => _editEntry(entry),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}

