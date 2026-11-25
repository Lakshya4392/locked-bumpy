import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';
import '../widgets/baby_avatar.dart';

/// Settings screen — edit nickname, due date, look mode, view privacy
/// & medical disclaimer, or erase all on-device data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.state,
    this.isEmbedded = false,
  });

  final AppState state;
  final bool isEmbedded;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.state.nickname);
    widget.state.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate(AppPalette palette) async {
    final now = DateTime.now();
    final initial = widget.state.dueDate ?? now.add(const Duration(days: 140));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 300)),
    );
    if (picked != null && mounted) {
      await widget.state.saveDueDate(picked);
    }
  }

  Future<void> _confirmErase(AppPalette palette) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Erase everything?',
          style: TextStyle(color: palette.ink, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This removes your date, nickname, and check-ins. It cannot be undone.',
          style: TextStyle(color: palette.inkSoft, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: palette.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Yes, erase'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.state.eraseAll();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final palette = state.isHalloween
        ? AppPalette.halloween
        : AppPalette.everyday;
    final dueDate = state.dueDate;
    final weekLabel = dueDate == null
        ? 'Not set'
        : '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')} '
              '(Week ${PregnancyCalculator.weekFromDueDate(dueDate: dueDate, currentDate: DateTime.now())})';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.skyTop, palette.skyBottom],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        if (!widget.isEmbedded) ...[
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: palette.moonlight,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: palette.moonlight,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Mom & Bumpy Summary Card ───────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.paper,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: palette.paperRaised,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: BabyAvatar(
                                    need: state.costumeOverride ??
                                        state.todayNeed,
                                    size: 50,
                                    animate: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.babyDisplayName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: palette.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dueDate == null
                                          ? 'Set your expected due date below'
                                          : 'Week ${PregnancyCalculator.weekFromDueDate(dueDate: dueDate, currentDate: DateTime.now())} of 42 • On-device only',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: palette.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Baby & Date ────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.paper,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Baby Nickname',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nicknameController,
                                      style: TextStyle(color: palette.ink),
                                      decoration: InputDecoration(
                                        hintText: 'Little Bumpy',
                                        hintStyle: TextStyle(
                                          color: palette.inkSoft.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: palette.paperRaised,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await state.saveNickname(
                                        _nicknameController.text,
                                      );
                                      if (context.mounted) {
                                        FocusScope.of(context).unfocus();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Nickname saved.'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: palette.accent,
                                      foregroundColor: palette.accentText,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size(64, 44),
                                    ),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Expected Due Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Used to calculate your current week (Week 4–42)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: palette.inkSoft.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _pickDueDate(palette),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.paperRaised,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        weekLabel,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: palette.ink,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 18,
                                        color: palette.accent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Theme toggle ───────────────────────────────────
                        Material(
                          color: palette.paper,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: SwitchListTile(
                            title: Text(
                              'Halloween Party Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: palette.ink,
                              ),
                            ),
                            subtitle: Text(
                              state.isHalloween
                                  ? 'Playful costumes & pumpkin moon'
                                  : 'Warm everyday nursery',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.inkSoft,
                              ),
                            ),
                            value: state.isHalloween,
                            activeThumbColor: palette.accent,
                            onChanged: (_) => state.toggleMode(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Privacy & About ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: palette.paper,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Little Bumpy v${AppConstants.appVersion}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppConstants.privacyStatement,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                AppConstants.disclaimer,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: palette.inkSoft,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Erase ──────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _confirmErase(palette),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              'Erase all data',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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
}
