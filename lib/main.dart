import 'dart:async';
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

class _LittleBumpyAppState extends State<LittleBumpyApp>
    with WidgetsBindingObserver {
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onStateChange);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    _scheduleMidnight();
    setState(() {});
  }

  void _scheduleMidnight() {
    _dayTimer?.cancel();
    if (widget.state.isPaused || widget.state.isFirstRun) return;
    _dayTimer = Timer(widget.state.timeToMidnight, () {
      widget.state.refreshDay();
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Retry a pause write that failed, before the app can be closed.
    widget.state.savePendingPause();
    if (state == AppLifecycleState.resumed) {
      widget.state.refreshDay();
      _scheduleMidnight();
    } else {
      _dayTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final palette = state.isHalloween
        ? AppPalette.halloween
        : AppPalette.everyday;

    return MaterialApp(
      // Pause and Erase dismiss the whole route stack, including any open editor.
      key: ValueKey((state.isFirstRun, state.isPaused)),
      title: 'Little Bumpy',
      themeAnimationDuration:
          MediaQuery.maybeDisableAnimationsOf(context) ??
              WidgetsBinding
                  .instance
                  .platformDispatcher
                  .accessibilityFeatures
                  .disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 300),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: state.isHalloween ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: palette.skyBottom,
        extensions: [palette],
      ),
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, bounds) {
            final wideVisit =
                !state.isFirstRun &&
                !state.isPaused &&
                state.currentTab <= 1 &&
                (bounds.maxWidth >= 640 ||
                    (bounds.maxWidth >= 540 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 21)) &&
                bounds.maxHeight <= 600;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wideVisit ? 860 : 440),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [palette.skyTop, palette.skyBottom],
                    ),
                  ),
                  child: SafeArea(
                    child: state.isPaused
                        ? PausedScreen(state: state)
                        : state.isFirstRun
                        ? FirstRunScreen(state: state)
                        : _MainShell(state: state),
                  ),
                ),
              ),
            );
          },
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
        Expanded(child: _currentScreen()),
        AppNavBar(state: state),
      ],
    );
  }

  Widget _currentScreen() => switch (state.currentTab) {
    0 => TodayScreen(state: state),
    1 => ThisWeekScreen(state: state),
    _ => GuidesScreen(state: state),
  };
}
