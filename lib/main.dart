import 'package:flutter/material.dart';
import 'core/theme/palette.dart';
import 'domain/models/app_state.dart';
import 'presentation/screens/first_run_screen.dart';
import 'presentation/screens/guides_screen.dart';
import 'presentation/screens/paused_screen.dart';
import 'presentation/screens/this_week_screen.dart';
import 'presentation/screens/today_screen.dart';
import 'presentation/widgets/app_nav_bar.dart';
import 'presentation/widgets/top_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.load();
  runApp(LittleBumpyApp(state: state));
}

class LittleBumpyApp extends StatefulWidget {
  const LittleBumpyApp({super.key, required this.state});

  final AppState state;

  @override
  State<LittleBumpyApp> createState() => _LittleBumpyAppState();
}

class _LittleBumpyAppState extends State<LittleBumpyApp> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final palette = state.isHalloween
        ? AppPalette.halloween
        : AppPalette.everyday;

    return MaterialApp(
      title: 'Little Bumpy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: state.isHalloween ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: palette.skyBottom,
        extensions: [palette],
      ),
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.skyTop, palette.skyBottom],
                ),
              ),
              child: SafeArea(
                child: state.isFirstRun
                    ? FirstRunScreen(state: state)
                    : state.isPaused
                    ? PausedScreen(state: state)
                    : _MainShell(state: state),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-tab shell shown when app is active and onboarding is complete.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopBar(state: state),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(state.currentTab),
              child: _currentScreen(),
            ),
          ),
        ),
        AppNavBar(state: state),
      ],
    );
  }

  Widget _currentScreen() => switch (state.currentTab) {
    0 => TodayScreen(state: state),
    1 => ThisWeekScreen(state: state),
    _ => const GuidesScreen(),
  };
}
