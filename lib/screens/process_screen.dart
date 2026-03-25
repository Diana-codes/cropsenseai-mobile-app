import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'season_planning_screen.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  final _auth = AuthService();
  Map<String, dynamic>? _plan;
  bool _loading = true;
  String? _message;
  final Set<String> _pendingKeys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _plan = null;
          _message = 'Sign in to load your season process from your account.';
        });
      }
      return;
    }
    final plan = await ApiService.getActiveSeasonPlan(token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _plan = plan;
      if (plan == null) {
        _message =
            'No saved season plan yet. Use Season → Plan new season, then tap Done to save it to your account.';
      }
    });
  }

  int? get _planId {
    final id = _plan?['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse(id?.toString() ?? '');
  }

  Future<void> _toggleStage(String key, bool done) async {
    final planId = _planId;
    if (planId == null) return;
    final token = await _auth.getToken();
    if (token == null || token.isEmpty) return;

    setState(() => _pendingKeys.add(key));
    final updated = await ApiService.updateSeasonPlanStages(
      token: token,
      planId: planId,
      stages: [
        {'key': key, 'done': done},
      ],
    );
    if (!mounted) return;
    setState(() {
      _pendingKeys.remove(key);
      if (updated != null) {
        _plan = updated;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update stage. Try again.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    Expanded(
                      child: Text(
                        'Season Process',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_plan != null) ...[
                  _buildPlanHeader(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Your season stages'),
                  const SizedBox(height: 12),
                  ..._buildStageList(),
                ] else ...[
                  _buildEmptyState(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    final crop = _plan!['primary_crop']?.toString() ?? '';
    final loc =
        '${_plan!['district']?.toString() ?? ''}, ${_plan!['province']?.toString() ?? ''}'
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
            .trim();
    final season = _plan!['season']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.grass,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.isNotEmpty ? crop : 'Your crop plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [if (loc.isNotEmpty) loc, if (season.isNotEmpty) season]
                      .join(' • '),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStageList() {
    final raw = _plan!['stages'];
    if (raw is! List) {
      return [
        Text(
          'No stages on file. Save a new plan from Season planning.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ];
    }
    final widgets = <Widget>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final key = m['key']?.toString() ?? '';
      final title = m['title']?.toString() ?? key;
      final description = m['description']?.toString() ?? '';
      final done = m['done'] == true;
      final busy = _pendingKeys.contains(key);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: busy ? null : () => _toggleStage(key, !done),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(2),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Checkbox(
                              value: done,
                              onChanged: busy
                                  ? null
                                  : (v) => _toggleStage(key, v ?? false),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_message != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _message!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const SeasonPlanningScreen(),
                ),
              ).then((_) => _load());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.calendar_today_rounded),
            label: const Text('Plan new season'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
