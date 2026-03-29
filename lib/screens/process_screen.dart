import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'season_planning_screen.dart';
import 'login_screen.dart';

// Crop-specific guidance per stage key for common Rwanda crops.
// Falls back to generic tips for unlisted crops.
const _cropGuidance = <String, Map<String, String>>{
  'Maize': {
    'prepare': 'Plow to 20–30 cm depth. Add compost or manure and level the field.',
    'plant': 'Sow 2 seeds per hole, 5 cm deep. Space holes 25 cm apart in rows of 75 cm. Apply DAP fertilizer at planting.',
    'manage': 'Thin to 1 plant per hole after 2 weeks. Apply CAN top-dressing at knee height. Weed twice before canopy closes.',
    'harvest': 'Harvest when husks are dry and kernels dent. Twist cobs downward to detach cleanly.',
    'post': 'Dry cobs to below 13% moisture. Shell and store in hermetic bags or silos away from moisture.',
  },
  'Beans': {
    'prepare': 'Prepare a fine, well-drained seedbed. Incorporate well-rotted compost — avoid fresh manure.',
    'plant': 'Sow seeds 3–4 cm deep, 10 cm apart in rows of 40 cm. Inoculate seeds with Rhizobium for better yield.',
    'manage': 'Weed at 2 and 5 weeks after emergence. Watch for bean fly and rust. Avoid overhead irrigation.',
    'harvest': 'Harvest when pods turn yellow and rattle. Pull whole plants and dry in shade to prevent shattering.',
    'post': 'Thresh when fully dry. Winnow and store in airtight containers with ash or hermetic bags.',
  },
  'Sorghum': {
    'prepare': 'Plow early and prepare a firm seedbed. Sorghum tolerates poor soils but responds well to phosphorus.',
    'plant': 'Sow 2–3 seeds per hole, 2 cm deep. Space 20 cm apart in rows of 60–75 cm. Thin to 1 plant after emergence.',
    'manage': 'Weed early — sorghum is sensitive to competition in the first 4 weeks. Watch for stem borers and birds near harvest.',
    'harvest': 'Harvest when grain is hard and moisture is below 20%. Cut heads and dry on clean surfaces.',
    'post': 'Thresh, winnow and dry to below 12% moisture. Store in sealed bags to prevent weevil damage.',
  },
  'Sweet Potato': {
    'prepare': 'Form raised ridges or mounds 30–40 cm high. Mix compost into the ridge for better root development.',
    'plant': 'Plant vine cuttings 30–40 cm long at 30 cm intervals. Bury 2–3 nodes per cutting. Plant at the start of the rains.',
    'manage': 'Train vines away from the ridge centre. Weed once at 3 weeks. No fertilizer needed if soil is fertile.',
    'harvest': 'Harvest 3–5 months after planting when leaves turn yellow. Dig carefully to avoid wounding roots.',
    'post': 'Cure roots in a warm shaded area for 4–7 days to harden skin. Store in cool, dry, well-ventilated conditions.',
  },
  'Irish Potato': {
    'prepare': 'Plow to 30 cm depth. Apply well-rotted manure and NPK fertilizer. Form ridges 70–80 cm apart.',
    'plant': 'Plant certified seed tubers 8–10 cm deep on ridges. Space 30 cm apart. Cut large tubers, leaving 2 eyes per piece.',
    'manage': 'Earth up at 3 and 6 weeks. Apply fungicide every 7–10 days in wet weather to prevent late blight.',
    'harvest': 'Harvest 90–120 days after planting when foliage turns yellow. Lift tubers carefully to avoid bruising.',
    'post': 'Cure in shade for 2 weeks. Sort out damaged tubers. Store in dark, cool, well-ventilated conditions.',
  },
  'Cassava': {
    'prepare': 'Plow to 30 cm depth and form mounds or ridges. Cassava grows on poor soils but responds to phosphorus.',
    'plant': 'Plant stem cuttings 20–30 cm long at 45° angle. Space 1 m × 1 m. Plant at the start of the rainy season.',
    'manage': 'Weed 3 times in the first 3 months. After canopy closes, minimal weeding needed. Watch for cassava mosaic virus.',
    'harvest': 'Harvest 9–18 months after planting. Cut stem base and pull roots upward. Process or sell within 48 hours.',
    'post': 'Peel, sun-dry or ferment roots promptly. Dried chips store well in airtight bags for several months.',
  },
  'Rice': {
    'prepare': 'Level the paddy field and construct bunds. Flood and puddle soil 2 weeks before transplanting.',
    'plant': 'Transplant seedlings 25–30 days old. Space 20 × 20 cm. Apply basal fertilizer (DAP) at transplanting.',
    'manage': 'Maintain 5–10 cm water depth during vegetative stage. Apply CAN at tillering. Control weeds early.',
    'harvest': 'Harvest when 80–90% of grains are golden. Cut stalks and bundle. Thresh within 24 hours.',
    'post': 'Dry paddy to below 14% moisture. Mill and store in hermetic bags. Keep storage area cool and dry.',
  },
  'Wheat': {
    'prepare': 'Plow and harrow to a fine tilth. Apply DAP fertilizer and mix well into the top 10 cm of soil.',
    'plant': 'Broadcast or drill seeds at 120 kg/ha. Cover lightly with soil. Plant at the start of the cool rainy season.',
    'manage': 'Apply CAN top-dressing at tillering. Control rust and septoria with fungicide if rains are heavy.',
    'harvest': 'Harvest when grain is hard and straw is golden. Cut and bundle before grain moisture drops below 12%.',
    'post': 'Thresh and dry grain to below 12% moisture. Clean and store in sealed bags. Fumigate if storing >3 months.',
  },
  'Banana': {
    'prepare': 'Dig planting holes 60 × 60 × 60 cm. Fill with topsoil mixed with compost. Space holes 3 × 3 m.',
    'plant': 'Plant suckers or tissue culture plants in the rainy season. Remove dead leaves from the sucker before planting.',
    'manage': 'Desuckering: keep 1 parent + 1 follower + 1 ratoon. Mulch heavily. Apply manure every 3 months.',
    'harvest': 'Harvest when fingers are plump and angular edges round out. Cut the bunch with a sharp knife.',
    'post': 'Handle bunches carefully to avoid bruising. Ripen at room temperature. Remove mother plant and mulch stump.',
  },
};

// Generic guidance for crops not in the map above.
const _genericGuidance = <String, String>{
  'prepare': 'Prepare the field by plowing and applying organic matter. Ensure good drainage.',
  'plant': 'Sow at the recommended spacing and depth for your crop. Apply basal fertilizer at planting.',
  'manage': 'Weed regularly in the first weeks. Monitor for pests and diseases. Apply top-dressing as needed.',
  'harvest': 'Harvest at the right maturity stage to maximise quality and yield.',
  'post': 'Dry and clean the harvest before storage. Use sealed containers to prevent pest damage.',
};

String _stageTip(String crop, String stageKey) {
  final key = stageKey.toLowerCase();
  final stageSlot = key.contains('prepare') ? 'prepare'
      : key.contains('plant') ? 'plant'
      : key.contains('manage') ? 'manage'
      : key.contains('harvest') && !key.contains('post') ? 'harvest'
      : key.contains('post') ? 'post'
      : '';
  if (stageSlot.isEmpty) return '';

  // Try exact crop name, then case-insensitive partial match
  final cropKey = _cropGuidance.keys.firstWhere(
    (k) => k.toLowerCase() == crop.toLowerCase() ||
           crop.toLowerCase().contains(k.toLowerCase()),
    orElse: () => '',
  );
  if (cropKey.isNotEmpty) return _cropGuidance[cropKey]![stageSlot] ?? '';
  return _genericGuidance[stageSlot] ?? '';
}

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
    final advisorJson = _plan!['advisor_json'] as Map<String, dynamic>?;
    final bestMatch = advisorJson?['best_match'] as Map<String, dynamic>?;
    final landType = _plan!['land_type']?.toString() ?? '';
    final sowingWindow = bestMatch?['sowingWindow']?.toString() ?? '';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grass, color: AppColors.primary, size: 28),
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
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SeasonPlanningScreen(),
                  ),
                ).then((_) => _load()),
                child: Text(
                  'New plan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (landType.isNotEmpty || sowingWindow.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (landType.isNotEmpty)
                  _buildChip(Icons.landscape_outlined, landType),
                if (sowingWindow.isNotEmpty)
                  _buildChip(Icons.calendar_month_outlined, 'Sow: $sowingWindow'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
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

    final crop = _plan!['primary_crop']?.toString() ?? '';
    final advisorJson = _plan!['advisor_json'] as Map<String, dynamic>?;
    final bestMatch = advisorJson?['best_match'] as Map<String, dynamic>?;
    final sowingWindow = bestMatch?['sowingWindow']?.toString() ?? '';
    final growingPeriod = bestMatch?['growingPeriod']?.toString() ?? '';

    final widgets = <Widget>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final key = m['key']?.toString() ?? '';
      final title = m['title']?.toString() ?? key;
      final done = m['done'] == true;
      final busy = _pendingKeys.contains(key);

      // Crop-specific guidance
      final tip = crop.isNotEmpty ? _stageTip(crop, key) : '';

      // Timing hint — show sowing window on plant stage, growing period on harvest
      String timingHint = '';
      final keyLower = key.toLowerCase();
      if (keyLower.contains('plant') && sowingWindow.isNotEmpty) {
        timingHint = 'Sowing window: $sowingWindow';
      } else if (keyLower.contains('harvest') && !keyLower.contains('post') && growingPeriod.isNotEmpty) {
        timingHint = 'Expected: ~$growingPeriod after planting';
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: done ? Colors.grey.shade50 : Colors.white,
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
                              activeColor: AppColors.primary,
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
                              color: done
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (tip.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              tip,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (timingHint.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  timingHint,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
    final notSignedIn = _message?.startsWith('Sign in') ?? false;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notSignedIn ? Icons.lock_outline : Icons.agriculture_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              notSignedIn ? 'Sign in to view your process' : 'No season plan yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              notSignedIn
                  ? 'Create an account or sign in to save and track your season plan.'
                  : 'Start by planning your season. Once saved, your stages will appear here.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (notSignedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ).then((_) => _load());
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SeasonPlanningScreen(),
                      ),
                    ).then((_) => _load());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(notSignedIn ? Icons.login : Icons.calendar_today_rounded),
                label: Text(notSignedIn ? 'Sign in' : 'Plan new season'),
              ),
            ),
          ],
        ),
      ),
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
