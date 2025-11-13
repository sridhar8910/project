import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'schedule_session_page.dart';
import 'support_groups_page.dart';
import 'wallet_page.dart';

class HistoryCenterPage extends StatefulWidget {
  const HistoryCenterPage({super.key});

  @override
  State<HistoryCenterPage> createState() => _HistoryCenterPageState();
}

class _HistoryCenterPageState extends State<HistoryCenterPage>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();

  bool _loading = true;
  bool _refreshing = false;
  bool _recharging = false;
  String? _error;

  List<SupportGroupItem> _groups = const [];
  List<UpcomingSessionItem> _sessions = const [];
  WalletInfo? _wallet;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (_loading || _refreshing) return;

    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _refreshing = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _api.fetchSupportGroups(),
        _api.fetchUpcomingSessions(),
        _api.getWallet(),
      ]);

      if (!mounted) return;
      setState(() {
        _groups = results[0] as List<SupportGroupItem>;
        _sessions = results[1] as List<UpcomingSessionItem>;
        _wallet = results[2] as WalletInfo;
        _loading = false;
        _refreshing = false;
      });
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again. ($error)';
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _recharge(int minutes) async {
    if (_recharging) return;
    setState(() => _recharging = true);
    try {
      final total = await _api.rechargeWallet(minutes);
      if (!mounted) return;
      setState(() {
        _wallet = WalletInfo(minutes: total);
        _recharging = false;
      });
      _showSnackBar('Wallet recharged with $minutes minutes.');
    } on ApiClientException catch (error) {
      if (!mounted) return;
      setState(() => _recharging = false);
      _showSnackBar(error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _recharging = false);
      _showSnackBar('Unable to recharge wallet. Please try again. ($error)');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('History Center'),
          backgroundColor: const Color(0xFF8B5FBF),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('History Center'),
          backgroundColor: const Color(0xFF8B5FBF),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _load(showLoader: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final upcoming = _sessions.where((s) => s.startTime.isAfter(now)).toList();
    final past = _sessions.where((s) => !s.startTime.isAfter(now)).toList();
    final joinedGroups = _groups.where((g) => g.isJoined).length;
    final walletMinutes = _wallet?.minutes ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'History Center',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF8B5FBF),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(
            upcomingCount: upcoming.length,
            pastCount: past.length,
            groupCount: joinedGroups,
            walletMinutes: walletMinutes,
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B5FBF),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF8B5FBF),
              tabs: const [
                Tab(text: 'Chats'),
                Tab(text: 'Calls'),
                Tab(text: 'Wallet'),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(showLoader: false),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatTab(),
                  _buildCallsTab(upcoming: upcoming, past: past),
                  _buildWalletTab(walletMinutes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader({
    required int upcomingCount,
    required int pastCount,
    required int groupCount,
    required int walletMinutes,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Track your journey across chats, calls, and wallet activity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryChip(
                label: 'Upcoming calls',
                value: upcomingCount.toString(),
                icon: Icons.call_made,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Past calls',
                value: pastCount.toString(),
                icon: Icons.history,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryChip(
                label: 'Groups joined',
                value: groupCount.toString(),
                icon: Icons.groups,
              ),
              const SizedBox(width: 12),
              _SummaryChip(
                label: 'Wallet minutes',
                value: walletMinutes.toString(),
                icon: Icons.account_balance_wallet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          _EmptyMessage(
            title: 'No support groups yet',
            message:
                'Join a support group to start connecting with others. Groups you join will appear here.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEDE7F6),
              child: Icon(
                Icons.groups,
                color: group.isJoined ? const Color(0xFF8B5FBF) : Colors.grey[700],
              ),
            ),
            title: Text(group.name),
            subtitle: Text(
              group.description.isEmpty
                  ? 'No description provided.'
                  : group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Switch(
              value: group.isJoined,
              onChanged: (value) => _toggleGroup(group, value),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportGroupsPage()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallsTab({
    required List<UpcomingSessionItem> upcoming,
    required List<UpcomingSessionItem> past,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _CallSection(
          title: 'Upcoming sessions',
          emptyMessage: 'No upcoming sessions. Book one to stay on track.',
          sessions: upcoming,
          accentColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 24),
        _CallSection(
          title: 'Past sessions',
          emptyMessage: 'Past sessions will appear here after they finish.',
          sessions: past,
          accentColor: const Color(0xFF607D8B),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScheduleSessionPage()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Schedule new session'),
        ),
      ],
    );
  }

  Widget _buildWalletTab(int walletMinutes) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current balance',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$walletMinutes minutes',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5FBF),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Use wallet minutes to connect with counsellors or book premium sessions.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick recharge',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [10, 20, 30].map((minutes) {
                    return ChoiceChip(
                      label: Text('+${minutes}m'),
                      selected: false,
                      onSelected: (_) => _recharge(minutes),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
        FilledButton(
          onPressed: _recharging
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletPage()),
                  );
                  if (mounted) {
                    _load(showLoader: false);
                  }
                },
                  child: _recharging
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Recharge from wallet page'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _EmptyMessage(
          title: 'No transactions yet',
          message:
              'Recharge history will appear here once you add wallet minutes.',
        ),
      ],
    );
  }

  Future<void> _toggleGroup(SupportGroupItem group, bool join) async {
    try {
      final updated = await _api.updateSupportGroupMembership(
        slug: group.slug,
        action: join ? SupportGroupAction.join : SupportGroupAction.leave,
      );
      if (!mounted) return;
      setState(() {
        _groups = _groups
            .map((item) => item.slug == updated.slug ? updated : item)
            .toList();
      });
    } on ApiClientException catch (error) {
      _showSnackBar(error.message);
      _load(showLoader: false);
    } catch (error) {
      _showSnackBar('Unable to update group. Please try again. ($error)');
      _load(showLoader: false);
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallSection extends StatelessWidget {
  const _CallSection({
    required this.title,
    required this.emptyMessage,
    required this.sessions,
    required this.accentColor,
  });

  final String title;
  final String emptyMessage;
  final List<UpcomingSessionItem> sessions;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          _EmptyMessage(title: 'Empty', message: emptyMessage)
        else
          ...sessions.map(
            (session) => Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.15),
                  child: Icon(Icons.calendar_today, color: accentColor),
                ),
                title: Text(session.title.isEmpty
                    ? session.sessionType.displayLabel
                    : session.title),
                subtitle: Text(
                  _formatDateTime(session.startTime),
                ),
                trailing: session.notes.isNotEmpty
                    ? const Icon(Icons.note_alt_outlined)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${_two(local.day)}/${_two(local.month)}/${local.year} • ${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int number) => number.toString().padLeft(2, '0');
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

