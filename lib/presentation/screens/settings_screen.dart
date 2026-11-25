import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/palette.dart';
import '../../domain/models/app_state.dart';
import '../../domain/pregnancy.dart';

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
                                'Baby Tone',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children:
                                    [
                                      ('fair', const Color(0xFFF1C9A8)),
                                      ('peach', const Color(0xFFFAB073)),
                                      ('honey', const Color(0xFFDCA06D)),
                                      ('deep', const Color(0xFF9B6142)),
                                      ('deepest', const Color(0xFF844934)),
                                    ].map((entry) {
                                      final isSelected =
                                          state.babyTone == entry.$1;
                                      return Semantics(
                                        label: 'Baby tone ${entry.$1}',
                                        selected: isSelected,
                                        button: true,
                                        child: InkWell(
                                          onTap: () =>
                                              state.saveBabyTone(entry.$1),
                                          customBorder: const CircleBorder(),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: entry.$2,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? palette.accent
                                                    : palette.ink.withValues(
                                                        alpha: 0.2,
                                                      ),
                                                width: isSelected ? 3 : 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 6),
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
