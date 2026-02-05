import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SilenceApp());
}

/// =============================================================
///  MODES
/// =============================================================
enum SessionMode { silence, pomodoro }

String _modeToStr(SessionMode m) =>
    m == SessionMode.pomodoro ? 'pomodoro' : 'silence';
SessionMode _modeFromStr(String? s) =>
    (s == 'pomodoro') ? SessionMode.pomodoro : SessionMode.silence;

/// =============================================================
///  PHRASES
/// =============================================================
const List<String> kSilencePhrases = [
  "Just this breath.",
  "Arrive in this moment.",
  "Nothing to fix.",
  "Let it be simple.",
  "Be here now.",
  "This moment is enough.",
  "No need to rush.",
  "Feel what is here.",
  "Now is wide open.",
  "Rest in awareness.",
  "Soften the effort.",
  "Let the mind settle.",
  "Stay with the present.",
  "Allow this to be.",
  "Nothing is missing.",
  "Come back to now.",
  "Meet this moment gently.",
  "Let thoughts pass through.",
  "You are already here.",
  "This is your home.",
  "Quietly notice.",
  "Just witnessing.",
  "Ease into being.",
  "The present holds you.",
  "Let go of the next thing.",
  "One breath at a time.",
  "Be with what is.",
  "No story needed.",
  "Peace is here.",
  "Stop trying for a second.",
  "The now is enough.",
  "Feel the aliveness.",
  "Release the tension.",
  "Nothing to achieve.",
  "Let the moment breathe you.",
  "Be the space around thoughts.",
  "Gently return.",
  "Here. Now.",
  "Simply aware.",
  "This is it.",
  "Drop the commentary.",
  "Let the body rest.",
  "Notice and allow.",
  "Don’t add anything.",
  "A soft attention.",
  "Let time be time.",
  "Befriend the moment.",
  "Stay with the breath.",
  "Rest your mind.",
  "Let silence listen.",
];

const List<String> kEndPhrases = [
  "Done.",
  "Carry this with you.",
  "You can go now.",
  "Silence continues outside.",
  "Nothing else is required.",
  "Return when you want.",
];

const List<String> kPomodoroPhrases = [
  "Start small. Start now.",
  "One task. One block.",
  "Focus is a choice.",
  "Make it easy to begin.",
  "Progress over perfection.",
  "Do the next right thing.",
  "Show up for this block.",
  "Momentum is built, not found.",
  "Your future self will thank you.",
  "Clarity comes from action.",
  "Remove one distraction.",
  "Earn your confidence.",
  "Tiny steps, real change.",
  "Commit to the process.",
  "Work the plan—gently.",
  "Deep work, simple rules.",
  "Attention is your superpower.",
  "Create, then refine.",
  "Let consistency win.",
  "Today’s effort counts.",
  "You don’t need motivation—just start.",
  "Finish one thing.",
  "Make it measurable: one block.",
  "Keep it boring. Keep it done.",
  "Discipline becomes freedom later.",
  "Put the phone away.",
  "Protect this block.",
  "The first minute matters.",
  "You’re building trust with yourself.",
  "Decide, then do.",
  "Less planning, more doing.",
  "Small actions beat big intentions.",
  "Focus is kindness to yourself.",
  "Don’t negotiate with distractions.",
  "One page. One paragraph. One line.",
  "Make the work obvious.",
  "Stay with the task.",
  "You can do hard things calmly.",
  "Be proud of showing up.",
  "Do it imperfectly, but do it.",
  "Your job is to begin.",
  "The timer is your ally.",
  "This block is a vote for your goals.",
  "Simple. Repeatable. Done.",
  "You’re closer than you think.",
  "Focus now, relax later.",
  "Energy follows attention.",
  "Keep going—just a little more.",
  "Complete the block.",
  "Done is powerful.",
];

const List<String> kBreathCues = [
  "Inhale… Exhale…",
  "One breath.",
];

/// =============================================================
///  Daily tracker keys
/// =============================================================
const String kPrefDailySeconds = 'dailySeconds';
const String kPrefDailyKey = 'dailyKey';

String _dayKeyNow() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _fmtToday(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  if (m >= 60) {
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}h ${mm.toString().padLeft(2, '0')}m';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// =============================================================
///  STYLE — gradients
/// =============================================================

LinearGradient kAppGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF121225),
        Color(0xFF1B1837),
        Color(0xFF0B0B10),
      ],
      stops: [0.0, 0.55, 1.0],
    );

LinearGradient kSilenceBgGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF07070C),
        Color(0xFF0E0C1A),
        Color(0xFF000000),
      ],
      stops: [0.0, 0.55, 1.0],
    );

LinearGradient kPomodoroBgGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF12060A),
        Color(0xFF1A0A10),
        Color(0xFF000000),
      ],
      stops: [0.0, 0.55, 1.0],
    );

/// =============================================================
///  APP (always dark)
/// =============================================================

class SilenceApp extends StatelessWidget {
  const SilenceApp({super.key});

  void _forceFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  ThemeData _theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7E57C2),
      brightness: Brightness.dark,
    );

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B0B10),
      fontFamilyFallback: const ['Inter', 'SF Pro Display', 'Roboto'],
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 52,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.2,
          height: 1.05,
          color: scheme.onBackground,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.7,
          height: 1.25,
          color: scheme.onBackground.withOpacity(0.86),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.6,
          height: 1.25,
          color: scheme.onBackground.withOpacity(0.90),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.55,
          height: 1.55,
          color: scheme.onBackground.withOpacity(0.82),
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          letterSpacing: 0.45,
          height: 1.45,
          color: scheme.onBackground.withOpacity(0.62),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _forceFullscreen();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Silence',
      theme: _theme(),
      home: const StartScreen(),
    );
  }
}

/// =============================================================
///  START
/// =============================================================

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void go() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: kAppGradient()),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Silence1',
                        style: Theme.of(context).textTheme.displayLarge),
                    const SizedBox(height: 14),
                    Text(
                      "Just be here.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 26),
                    FilledButton(
                      onPressed: go,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =============================================================
///  HOME
/// =============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loaded = false;

  static const List<int> timeOptions = [
    30,
    45,
    60,
    90,
    120,
    300,
    600,
    1200,
    1800,
  ];

  int silenceSeconds = 45;
  bool soundOn = true;
  double volume = 0.18;
  double speedMul = 1.0;

  SessionMode mode = SessionMode.silence;
  int pomoFocusMin = 25;
  int pomoBreakMin = 5;
  int pomoCycles = 4;

  int todaySeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _ensureDailyFresh(SharedPreferences prefs) async {
    final key = prefs.getString(kPrefDailyKey);
    final nowKey = _dayKeyNow();
    if (key != nowKey) {
      await prefs.setString(kPrefDailyKey, nowKey);
      await prefs.setInt(kPrefDailySeconds, 0);
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureDailyFresh(prefs);

    final savedSeconds = prefs.getInt('silenceSeconds');
    silenceSeconds = timeOptions.contains(savedSeconds) ? savedSeconds! : 45;

    soundOn = prefs.getBool('soundOn') ?? true;
    volume = (prefs.getDouble('volume') ?? 0.18).clamp(0.0, 0.35);
    speedMul = (prefs.getDouble('speedMul') ?? 1.0).clamp(0.7, 1.25);

    mode = _modeFromStr(prefs.getString('mode'));
    pomoFocusMin = (prefs.getInt('pomoFocusMin') ?? 25).clamp(5, 60);
    pomoBreakMin = (prefs.getInt('pomoBreakMin') ?? 5).clamp(3, 30);
    pomoCycles = (prefs.getInt('pomoCycles') ?? 4).clamp(1, 8);

    todaySeconds = prefs.getInt(kPrefDailySeconds) ?? 0;

    if (!mounted) return;
    setState(() => loaded = true);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('silenceSeconds', silenceSeconds);
    await prefs.setBool('soundOn', soundOn);
    await prefs.setDouble('volume', volume);
    await prefs.setDouble('speedMul', speedMul);

    await prefs.setString('mode', _modeToStr(mode));
    await prefs.setInt('pomoFocusMin', pomoFocusMin);
    await prefs.setInt('pomoBreakMin', pomoBreakMin);
    await prefs.setInt('pomoCycles', pomoCycles);
  }

  Future<void> _addToday(int secondsToAdd) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureDailyFresh(prefs);
    final curr = prefs.getInt(kPrefDailySeconds) ?? 0;
    final next = curr + secondsToAdd;
    await prefs.setInt(kPrefDailySeconds, next);
    if (!mounted) return;
    setState(() => todaySeconds = next);
  }

  int _plannedSessionSeconds() {
    if (mode == SessionMode.pomodoro) {
      final focus = pomoFocusMin * 60;
      final brk = pomoBreakMin * 60;
      return pomoCycles * (focus + brk);
    }
    return silenceSeconds;
  }

  Future<void> openSession() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => BallSessionScreen(
          mode: mode,
          silenceSeconds: silenceSeconds,
          pomodoroFocusMin: pomoFocusMin,
          pomodoroBreakMin: pomoBreakMin,
          pomodoroCycles: pomoCycles,
          soundOn: soundOn,
          volume: volume,
          speedMul: speedMul,
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final fade = Tween(begin: 0.0, end: 1.0).animate(curved);
          final scale = Tween(begin: 0.985, end: 1.0).animate(curved);
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );

    if (result == true) {
      await _addToday(_plannedSessionSeconds());
    } else {
      final prefs = await SharedPreferences.getInstance();
      await _ensureDailyFresh(prefs);
      final v = prefs.getInt(kPrefDailySeconds) ?? 0;
      if (!mounted) return;
      setState(() => todaySeconds = v);
    }
  }

  Future<void> openSettings() async {
    final result = await Navigator.of(context).push<SettingsResult>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          initialSeconds: silenceSeconds,
          initialSoundOn: soundOn,
          initialVolume: volume,
          initialSpeedMul: speedMul,
          timeOptions: timeOptions,
          initialMode: mode,
          initialPomoFocusMin: pomoFocusMin,
          initialPomoBreakMin: pomoBreakMin,
          initialPomoCycles: pomoCycles,
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      silenceSeconds = result.silenceSeconds;
      soundOn = result.soundOn;
      volume = result.volume.clamp(0.0, 0.35);
      speedMul = result.speedMul.clamp(0.7, 1.25);

      mode = result.mode;
      pomoFocusMin = result.pomoFocusMin;
      pomoBreakMin = result.pomoBreakMin;
      pomoCycles = result.pomoCycles;
    });

    await _savePrefs();

    final prefs = await SharedPreferences.getInstance();
    await _ensureDailyFresh(prefs);
    final v = prefs.getInt(kPrefDailySeconds) ?? 0;
    if (!mounted) return;
    setState(() => todaySeconds = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: kAppGradient()),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: kAppGradient()),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Silence', style: text.titleLarge),
                    const Spacer(),
                    IconButton(
                      onPressed: openSettings,
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Opacity(
                  opacity: 0.55,
                  child: Text(
                    'Today: ${_fmtToday(todaySeconds)}',
                    style: text.bodyMedium,
                  ),
                ),
              ),
              const Spacer(),
              Text('Enter the present.',
                  style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                mode == SessionMode.pomodoro
                    ? 'Focus gently. Rest briefly.'
                    : 'No tapping needed.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: openSession,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Text('Enter'),
                ),
              ),
              const Spacer(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================================================
///  SETTINGS
/// =============================================================

class SettingsResult {
  final int silenceSeconds;
  final bool soundOn;
  final double volume;
  final double speedMul;

  final SessionMode mode;
  final int pomoFocusMin;
  final int pomoBreakMin;
  final int pomoCycles;

  SettingsResult({
    required this.silenceSeconds,
    required this.soundOn,
    required this.volume,
    required this.speedMul,
    required this.mode,
    required this.pomoFocusMin,
    required this.pomoBreakMin,
    required this.pomoCycles,
  });
}

class SettingsScreen extends StatefulWidget {
  final int initialSeconds;
  final bool initialSoundOn;
  final double initialVolume;
  final double initialSpeedMul;
  final List<int> timeOptions;

  final SessionMode initialMode;
  final int initialPomoFocusMin;
  final int initialPomoBreakMin;
  final int initialPomoCycles;

  const SettingsScreen({
    super.key,
    required this.initialSeconds,
    required this.initialSoundOn,
    required this.initialVolume,
    required this.initialSpeedMul,
    required this.timeOptions,
    required this.initialMode,
    required this.initialPomoFocusMin,
    required this.initialPomoBreakMin,
    required this.initialPomoCycles,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int silenceSeconds;
  late bool soundOn;
  late double volume;
  late double speedMul;

  late SessionMode mode;
  late int pomoFocusMin;
  late int pomoBreakMin;
  late int pomoCycles;

  @override
  void initState() {
    super.initState();
    silenceSeconds = widget.initialSeconds;
    soundOn = widget.initialSoundOn;
    volume = widget.initialVolume.clamp(0.0, 0.35);
    speedMul = widget.initialSpeedMul.clamp(0.7, 1.25);

    mode = widget.initialMode;
    pomoFocusMin = widget.initialPomoFocusMin.clamp(5, 60);
    pomoBreakMin = widget.initialPomoBreakMin.clamp(3, 30);
    pomoCycles = widget.initialPomoCycles.clamp(1, 8);
  }

  String fmtMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  int secondsToIndex(int s) {
    final i = widget.timeOptions.indexOf(s);
    return i >= 0 ? i : widget.timeOptions.indexOf(45);
  }

  String speedLabel(double v) {
    if (v <= 0.82) return 'Slow';
    if (v >= 1.15) return 'Soft+';
    return 'Default';
  }

  void saveAndExit() {
    Navigator.of(context).pop(
      SettingsResult(
        silenceSeconds: silenceSeconds,
        soundOn: soundOn,
        volume: volume,
        speedMul: speedMul,
        mode: mode,
        pomoFocusMin: pomoFocusMin,
        pomoBreakMin: pomoBreakMin,
        pomoCycles: pomoCycles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    final timeIndex = secondsToIndex(silenceSeconds);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: onBg.withOpacity(0.92)),
        ),
        iconTheme: IconThemeData(color: onBg.withOpacity(0.80)),
        actions: [
          TextButton(
            onPressed: saveAndExit,
            style: TextButton.styleFrom(
              foregroundColor: onBg.withOpacity(0.85),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: kAppGradient()),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Mode', style: TextStyle(fontSize: 18, color: onBg)),
                  const Spacer(),
                  SegmentedButton<SessionMode>(
                    segments: const [
                      ButtonSegment(
                          value: SessionMode.silence, label: Text('Silence')),
                      ButtonSegment(
                          value: SessionMode.pomodoro, label: Text('Pomodoro')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) {
                      setState(() => mode = s.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Silence timer',
                      style: TextStyle(fontSize: 18, color: onBg)),
                  const Spacer(),
                  Text(fmtMMSS(silenceSeconds),
                      style: TextStyle(fontSize: 18, color: onBg)),
                ],
              ),
              const SizedBox(height: 10),
              Slider(
                value: timeIndex.toDouble(),
                min: 0,
                max: (widget.timeOptions.length - 1).toDouble(),
                divisions: widget.timeOptions.length - 1,
                label: fmtMMSS(silenceSeconds),
                onChanged: (v) {
                  final idx = v.round().clamp(0, widget.timeOptions.length - 1);
                  setState(() => silenceSeconds = widget.timeOptions[idx]);
                },
              ),
              if (mode == SessionMode.pomodoro) ...[
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 12),
                Text('Pomodoro',
                    style:
                        TextStyle(fontSize: 18, color: onBg.withOpacity(0.95))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Focus', style: TextStyle(fontSize: 16, color: onBg)),
                    const Spacer(),
                    Text('$pomoFocusMin min',
                        style: TextStyle(
                            fontSize: 16, color: onBg.withOpacity(0.8))),
                  ],
                ),
                Slider(
                  value: pomoFocusMin.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  label: '$pomoFocusMin',
                  onChanged: (v) => setState(() => pomoFocusMin = v.round()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Break', style: TextStyle(fontSize: 16, color: onBg)),
                    const Spacer(),
                    Text('$pomoBreakMin min',
                        style: TextStyle(
                            fontSize: 16, color: onBg.withOpacity(0.8))),
                  ],
                ),
                Slider(
                  value: pomoBreakMin.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 9,
                  label: '$pomoBreakMin',
                  onChanged: (v) => setState(() => pomoBreakMin = v.round()),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Cycles', style: TextStyle(fontSize: 16, color: onBg)),
                    const Spacer(),
                    Text('$pomoCycles',
                        style: TextStyle(
                            fontSize: 16, color: onBg.withOpacity(0.8))),
                  ],
                ),
                Slider(
                  value: pomoCycles.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '$pomoCycles',
                  onChanged: (v) => setState(() => pomoCycles = v.round()),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Sound', style: TextStyle(fontSize: 18, color: onBg)),
                  const Spacer(),
                  Switch(
                    value: soundOn,
                    onChanged: (v) => setState(() => soundOn = v),
                  ),
                ],
              ),
              if (soundOn) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Volume',
                        style: TextStyle(
                            fontSize: 16, color: onBg.withOpacity(0.9))),
                    const Spacer(),
                    Text('${(volume * 100).round()}%',
                        style: TextStyle(color: onBg.withOpacity(0.8))),
                  ],
                ),
                Slider(
                  value: volume,
                  min: 0.0,
                  max: 0.35,
                  divisions: 35,
                  onChanged: (v) => setState(() => volume = v),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Speed', style: TextStyle(fontSize: 18, color: onBg)),
                  const Spacer(),
                  Text(speedLabel(speedMul),
                      style: TextStyle(
                          fontSize: 16, color: onBg.withOpacity(0.8))),
                ],
              ),
              Slider(
                value: speedMul,
                min: 0.7,
                max: 1.25,
                divisions: 22,
                onChanged: (v) => setState(() => speedMul = v),
              ),
              const SizedBox(height: 12),
              Text(
                'Silence works best when you don’t interact.\nTap to pause is available inside the session.',
                style: TextStyle(color: onBg.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =============================================================
///  EXPERIENCE: BALL SESSION
///  FIX PRINCIPAL: audio ambiente 100% simple:
///   - un solo play() (no setSource+play doble)
///   - releaseMode loop
///   - AudioContext Android con audioFocus gain + usage media
///   - si el player cae, lo re-iniciamos 1 vez (timer pequeño)
/// =============================================================

class BallSessionScreen extends StatefulWidget {
  final SessionMode mode;

  final int silenceSeconds;

  final int pomodoroFocusMin;
  final int pomodoroBreakMin;
  final int pomodoroCycles;

  final bool soundOn;
  final double volume;
  final double speedMul;

  const BallSessionScreen({
    super.key,
    required this.mode,
    required this.silenceSeconds,
    required this.pomodoroFocusMin,
    required this.pomodoroBreakMin,
    required this.pomodoroCycles,
    required this.soundOn,
    required this.volume,
    required this.speedMul,
  });

  @override
  State<BallSessionScreen> createState() => _BallSessionScreenState();
}

class _BallSessionScreenState extends State<BallSessionScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController controller;
  final rnd = Random();

  double x = 0.5, y = 0.5;
  double vx = 0.06, vy = 0.04;

  // Audio
  AudioPlayer? _ambient;
  AudioPlayer? _bell;

  bool showSessionText = true;
  bool showEndText = false;
  bool showTapHint = true;
  bool _finishing = false;
  bool _paused = false;

  // Robust timer
  int _elapsedMs = 0;
  int _lastTickMs = 0;

  ui.Image? _noiseImage;

  static const double _cycleSeconds = 14.0;

  late final List<_Phase> _phases;
  int _phaseIndex = 0;
  int _phaseStartSec = 0;
  int _phaseEndSec = 0;

  String _headline = '';
  String _endline = '';

  double _finishT = 0.0;
  late final AnimationController _finishController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _phases = _buildPhases();
    _setPhase(0);

    x = rnd.nextDouble() * 0.6 + 0.2;
    y = rnd.nextDouble() * 0.6 + 0.2;

    final spMul = widget.speedMul.clamp(0.7, 1.25);
    final baseBoost = 1.25;
    final modeBoost = widget.mode == SessionMode.pomodoro ? 1.12 : 1.0;
    final speed =
        (0.05 + rnd.nextDouble() * 0.06) * spMul * baseBoost * modeBoost;

    final angle = rnd.nextDouble() * pi * 2;
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    final totalSeconds =
        _phases.isNotEmpty ? _phases.last.endSec : widget.silenceSeconds;

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: max(1, totalSeconds)),
    )
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onCompleteSession();
      });

    _finishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        setState(() =>
            _finishT = Curves.easeOutCubic.transform(_finishController.value));
      });

    _elapsedMs = 0;
    _lastTickMs = 0;

    _startAudio(); // ✅ aquí
    _scheduleTextFades();
    _buildNoiseImage();

    controller.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Si el sistema pausa audio cuando la app pierde foco, lo manejamos
    if (!widget.soundOn) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _ambient?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (!_paused && !_finishing) {
        _ensureAmbient();
      }
    }
  }

  List<_Phase> _buildPhases() {
    if (widget.mode == SessionMode.silence) {
      return [
        _Phase(
          kind: _PhaseKind.silence,
          label: 'Silence',
          startSec: 0,
          endSec: widget.silenceSeconds,
        ),
      ];
    }

    final focus = widget.pomodoroFocusMin * 60;
    final brk = widget.pomodoroBreakMin * 60;

    final phases = <_Phase>[];
    int t = 0;
    for (int i = 0; i < widget.pomodoroCycles; i++) {
      phases.add(_Phase(
        kind: _PhaseKind.focus,
        label: 'Focus',
        startSec: t,
        endSec: t + focus,
      ));
      t += focus;
      phases.add(_Phase(
        kind: _PhaseKind.breakk,
        label: 'Break',
        startSec: t,
        endSec: t + brk,
      ));
      t += brk;
    }
    return phases;
  }

  void _setPhase(int idx) {
    _phaseIndex = idx.clamp(0, _phases.length - 1);
    _phaseStartSec = _phases[_phaseIndex].startSec;
    _phaseEndSec = _phases[_phaseIndex].endSec;

    final phrase = _pickPhasePhrase(_phases[_phaseIndex].kind);
    _headline = phrase;
    _endline = kEndPhrases[rnd.nextInt(kEndPhrases.length)];

    showSessionText = true;
  }

  String _pickPhasePhrase(_PhaseKind kind) {
    final maybeBreath = (rnd.nextDouble() < 0.14);
    if (_phaseIndex == 0 && maybeBreath) {
      return kBreathCues[rnd.nextInt(kBreathCues.length)];
    }

    if (widget.mode == SessionMode.silence) {
      return kSilencePhrases[rnd.nextInt(kSilencePhrases.length)];
    }

    if (kind == _PhaseKind.breakk) {
      const breakHints = [
        "Stand up. Breathe.",
        "Release your shoulders.",
        "Rest your eyes for a moment.",
        "Small reset. Back soon.",
        "Let your mind soften.",
      ];
      return breakHints[rnd.nextInt(breakHints.length)];
    }

    return kPomodoroPhrases[rnd.nextInt(kPomodoroPhrases.length)];
  }

  void _scheduleTextFades() {
    Future.delayed(const Duration(milliseconds: 10500), () {
      if (!mounted) return;
      setState(() => showSessionText = false);
    });

    Future.delayed(const Duration(milliseconds: 9000), () {
      if (!mounted) return;
      setState(() => showTapHint = false);
    });
  }

  AudioContext _ctx() {
    // 🔧 configuración simple y “segura” para que *sí suene* en Android
    return AudioContext(
      android: AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gain,
        usageType: AndroidUsageType.media,
        contentType: AndroidContentType.music,
        stayAwake: true,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );
  }

  Future<void> _startAmbient({AudioContext? ctx}) async {
    final context = ctx ?? _audioContextForMixing();
    final p = AudioPlayer();
    await p.setPlayerMode(PlayerMode.mediaPlayer);
    await p.setAudioContext(context);
    await p.setReleaseMode(ReleaseMode.loop);
    final ambientVol = widget.volume.clamp(0.0, 0.35);
    await p.setVolume(ambientVol);
    await p.setSource(AssetSource('sounds/ambient.mp3'));
    await p.resume();
    ambientPlayer = p;
  }

  Future<void> _ensureAmbientPlaying() async {
    if (!widget.soundOn) return;
    if (ambientPlayer == null) {
      try {
        await _startAmbient();
      } catch (_) {}
      return;
    }
    try {
      await ambientPlayer?.resume();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 150));
    if (ambientPlayer?.state != PlayerState.playing) {
      try {
        await ambientPlayer?.stop();
      } catch (_) {}
      try {
        await ambientPlayer?.dispose();
      } catch (_) {}
      ambientPlayer = null;
      try {
        await _startAmbient();
      } catch (_) {}
    }
  }

  Future<void> _initAudio() async {
  Future<void> _startAudio() async {
    if (!widget.soundOn) return;

    final vol = widget.volume.clamp(0.0, 0.35);
    final ctx = _ctx();

    // ✅ Ambient: UN SOLO play() y loop
    try {
      await _startAmbient(ctx: ctx);
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        await _ensureAmbientPlaying();
      });
      final p = AudioPlayer(playerId: 'ambient');
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      await p.setAudioContext(ctx);
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(vol);
      await p.play(AssetSource('sounds/ambient.mp3')); // <-- clave
      _ambient = p;

      // “Watchdog” simple: si no quedó playing, reintenta 1 vez.
      Future.delayed(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        if (_paused || _finishing) return;
        if (_ambient?.state != PlayerState.playing) {
          await _restartAmbient();
        }
      });
    } catch (e) {
      // debugPrint('ambient error: $e');
    }

    // Bell
    try {
      final b = AudioPlayer(playerId: 'bell');
      await b.setPlayerMode(PlayerMode.lowLatency);
      await b.setAudioContext(ctx);
      await b.setReleaseMode(ReleaseMode.stop);
      await b.setVolume((widget.volume * 0.95).clamp(0.0, 0.35));
      await b.setSource(AssetSource('sounds/bell.mp3'));
      _bell = b;
    } catch (_) {}
  }

  Future<void> _restartAmbient() async {
    if (!widget.soundOn) return;
    try {
      await _ambient?.stop();
      await _ambient?.dispose();
    } catch (_) {}
    _ambient = null;

    try {
      final p = AudioPlayer(playerId: 'ambient');
      await p.setPlayerMode(PlayerMode.mediaPlayer);
      await p.setAudioContext(_ctx());
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(widget.volume.clamp(0.0, 0.35));
      await p.play(AssetSource('sounds/ambient.mp3'));
      _ambient = p;
    } catch (_) {}
  }

  Future<void> _ensureAmbient() async {
    if (!widget.soundOn) return;
    if (_ambient == null) {
      await _restartAmbient();
      return;
    }
    try {
      await _ambient!.resume();
    } catch (_) {}
    if (_ambient!.state != PlayerState.playing) {
      await _restartAmbient();
    }
  }

  Future<void> _playBell() async {
    if (!widget.soundOn) return;
    if (_paused) return;
    if (_bell == null) return;

    try {
      await _bell!.seek(Duration.zero);
      await _bell!.resume();
    } catch (_) {
      try {
        await _bell!.play(
          AssetSource('sounds/bell.mp3'),
          volume: (widget.volume * 0.95).clamp(0.0, 0.35),
        );
      } catch (_) {}
    }
  }

  Future<void> _playBounce() async {
    await _ensureAmbientPlaying();
  }

  Future<void> _togglePause() async {
    if (_finishing) return;

    final nextPaused = !_paused;
    setState(() => _paused = nextPaused);

    if (nextPaused) {
      controller.stop(canceled: false);
      try {
        await _ambient?.pause();
      } catch (_) {}
    } else {
      _lastTickMs = 0;
      controller.forward(from: controller.value);
      await _ensureAmbient();
    }
  }

  void _tick() {
    if (_paused) return;

    final totalMs =
        (controller.duration?.inMilliseconds ?? 1000).clamp(1, 1 << 30);
    final nowMs = (controller.value * totalMs).round();

    if (_lastTickMs == 0) {
      _lastTickMs = nowMs;
      _elapsedMs = nowMs;
      return;
    }

    final deltaMs = nowMs - _lastTickMs;
    if (deltaMs <= 0) return;

    _lastTickMs = nowMs;
    _elapsedMs = nowMs;

    final dt = deltaMs / 1000.0;
    final elapsedSec = (_elapsedMs / 1000.0).floor();

    // Pomodoro phase transitions
    if (_phases.length > 1) {
      if (elapsedSec >= _phaseEndSec && _phaseIndex < _phases.length - 1) {
        _playBell();
        _setPhase(_phaseIndex + 1);

        showSessionText = true;
        Future.delayed(const Duration(milliseconds: 10500), () {
          if (!mounted) return;
          if (_paused) return;
          setState(() => showSessionText = false);
        });
      }
    }

    final spMul = widget.speedMul.clamp(0.7, 1.25);
    final baseBoost = 1.25;
    final phaseBoost = _currentPhaseKind() == _PhaseKind.focus ? 1.10 : 1.0;
    final modeBoost = widget.mode == SessionMode.pomodoro ? 1.08 : 1.0;
    final eff = spMul * baseBoost * modeBoost * phaseBoost;

    final damp = pow(0.995, dt * 60).toDouble();
    vx *= damp;
    vy *= damp;

    final wobble = 0.010 * eff;
    vx += (rnd.nextDouble() - 0.5) * wobble * dt;
    vy += (rnd.nextDouble() - 0.5) * wobble * dt;

    final sp = sqrt(vx * vx + vy * vy);
    final minSp = 0.04 * eff;
    final maxSp = 0.12 * eff;
    if (sp < minSp) {
      final k = minSp / max(sp, 1e-9);
      vx *= k;
      vy *= k;
    } else if (sp > maxSp) {
      final k = maxSp / sp;
      vx *= k;
      vy *= k;
    }

    x += vx * dt;
    y += vy * dt;

    if (x < 0) {
      x = -x;
      vx = -vx;
    } else if (x > 1) {
      x = 2 - x;
      vx = -vx;
    }
    if (y < 0) {
      y = -y;
      vy = -vy;
    } else if (y > 1) {
      y = 2 - y;
      vy = -vy;
    }

    if (mounted) setState(() {});
  }

  _PhaseKind _currentPhaseKind() => _phases[_phaseIndex].kind;

  Future<void> _onCompleteSession() async {
    if (_finishing) return;
    _finishing = true;

    await _playBell();

    if (!mounted) return;
    setState(() {
      showEndText = true;
      showSessionText = false;
    });

    try {
      await _finishController.forward();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _buildNoiseImage() async {
    const w = 256;
    const h = 256;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0x00000000),
    );

    final r = Random(1337);
    final paint = Paint()..color = const Color(0xFFFFFFFF);

    const dots = 5200;
    for (int i = 0; i < dots; i++) {
      final dx = r.nextDouble() * w;
      final dy = r.nextDouble() * h;
      final a = (r.nextDouble() * r.nextDouble() * 40 + 6).clamp(0, 60).toInt();
      paint.color = Color.fromARGB(a, 255, 255, 255);
      final s = (r.nextDouble() < 0.86) ? 1.0 : 2.0;
      canvas.drawRect(Rect.fromLTWH(dx, dy, s, s), paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);

    if (!mounted) return;
    setState(() => _noiseImage = img);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    _finishController.dispose();
    _ambient?.dispose();
    _bell?.dispose();
    _noiseImage?.dispose();
    super.dispose();
  }

  String _fmtMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  Color _baseColorAt(double seconds) {
    final phase = (seconds / _cycleSeconds) % 1.0;
    final eased = Curves.easeInOut.transform(phase);

    if (widget.mode == SessionMode.pomodoro) {
      final hue = ui.lerpDouble(350.0, 10.0, eased)!;
      return HSVColor.fromAHSV(1.0, hue, 0.75, 0.95).toColor();
    }

    final hue = ui.lerpDouble(250.0, 290.0, eased)!;
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.98).toColor();
  }

  int _remainingPhaseSeconds() {
    final elapsedSec = (_elapsedMs ~/ 1000);
    final rem = _phaseEndSec - elapsedSec;
    return rem.clamp(0, max(0, _phaseEndSec - _phaseStartSec));
  }

  String _phaseLabel() {
    if (widget.mode == SessionMode.silence) return '';
    final k = _currentPhaseKind();
    return (k == _PhaseKind.focus) ? 'Focus' : 'Break';
  }

  Future<void> _confirmExit() async {
    if (_finishing) return;
    try {
      await _ambient?.pause();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Widget _timerPill(BuildContext context, int remainingPhase) {
    final label = _fmtMMSS(remainingPhase);
    final phase = _phaseLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xAA000000),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.92),
                  letterSpacing: 0.6,
                ),
          ),
          if (widget.mode == SessionMode.pomodoro) ...[
            const SizedBox(width: 10),
            Opacity(
              opacity: 0.70,
              child: Text(
                phase,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _elapsedMs / 1000.0;
    final baseColor = _baseColorAt(elapsed);
    final remainingPhase = _remainingPhaseSeconds();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePause,
        child: LayoutBuilder(
          builder: (_, c) {
            final px = x * c.maxWidth;
            final py = y * c.maxHeight;

            final t = controller.value;
            final rr =
                10 + 2.2 * sin(t * pi * 2) + 1.2 * sin(t * pi * 0.27 + 1.7);

            final ox = 0.9 * sin(t * pi * 0.13 + 0.6);
            final oy = 0.9 * cos(t * pi * 0.11 + 2.1);

            return Stack(
              children: [
                CustomPaint(
                  painter: _BallPainter(
                    mode: widget.mode,
                    phaseKind: _currentPhaseKind(),
                    p: Offset(px, py),
                    r: rr,
                    haloOffset: Offset(ox, oy),
                    noise: _noiseImage,
                    baseColor: baseColor,
                    timeSeconds: elapsed,
                    finishT: _finishT,
                  ),
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  top: 8,
                  left: 6,
                  child: SafeArea(
                    bottom: false,
                    child: IconButton(
                      onPressed: _confirmExit,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 18,
                      splashRadius: 18,
                      tooltip: 'Back',
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: _timerPill(context, remainingPhase),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity: showTapHint && !_paused ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOut,
                      child: Center(
                        child: Text(
                          'Tap to pause',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.16),
                                    letterSpacing: 0.4,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: showSessionText && !_paused ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeOut,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _headline,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.36),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: showEndText ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOut,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _endline,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.55),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: _paused ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    child: Container(
                      color: Colors.black.withOpacity(0.22),
                      child: Center(
                        child: Text(
                          'Paused — tap to continue',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.58),
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _PhaseKind { silence, focus, breakk }

class _Phase {
  final _PhaseKind kind;
  final String label;
  final int startSec;
  final int endSec;
  _Phase({
    required this.kind,
    required this.label,
    required this.startSec,
    required this.endSec,
  });
}

/// =============================================================
///  PAINTER
/// =============================================================

class _BallPainter extends CustomPainter {
  final SessionMode mode;
  final _PhaseKind phaseKind;
  final Offset p;
  final double r;
  final Offset haloOffset;
  final ui.Image? noise;
  final Color baseColor;
  final double timeSeconds;
  final double finishT;

  _BallPainter({
    required this.mode,
    required this.phaseKind,
    required this.p,
    required this.r,
    required this.haloOffset,
    required this.noise,
    required this.baseColor,
    required this.timeSeconds,
    required this.finishT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = (mode == SessionMode.pomodoro)
        ? kPomodoroBgGradient()
        : kSilenceBgGradient();
    final bgPaint = Paint()..shader = bg.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.92,
        colors: const [
          Color(0x00000000),
          Color(0x00000000),
          Color(0xAA000000),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    if (noise != null) {
      final shader = ImageShader(
        noise!,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().scaled(1.35, 1.35).storage,
      );
      final grainPaint = Paint()
        ..shader = shader
        ..colorFilter =
            const ColorFilter.mode(Color(0x1AFFFFFF), BlendMode.srcIn)
        ..blendMode = BlendMode.softLight;
      canvas.drawRect(Offset.zero & size, grainPaint);
    }

    final finishBoost = 1.0 + 0.35 * finishT;

    final glowColor = baseColor.withOpacity(0.18 * finishBoost);
    final glowColor2 = baseColor.withOpacity(0.12 * finishBoost);
    final glowColor3 = baseColor.withOpacity(0.08 * finishBoost);

    final bloom1 = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final bloom2 = Paint()
      ..color = glowColor2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    final bloom3 = Paint()
      ..color = glowColor3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);

    final p2 = p + haloOffset * 1.2;

    canvas.drawCircle(p2, (r + 14) * finishBoost, bloom3);
    canvas.drawCircle(p2, (r + 9) * finishBoost, bloom2);
    canvas.drawCircle(p, (r + 6) * finishBoost, bloom1);

    final rect = Rect.fromCircle(center: p, radius: r);

    final hsv = HSVColor.fromColor(baseColor);
    final c1 = HSVColor.fromAHSV(
            1.0,
            hsv.hue,
            (hsv.saturation * 0.85).clamp(0.0, 1.0),
            (hsv.value * 0.95).clamp(0.0, 1.0))
        .toColor();
    final c2 = HSVColor.fromAHSV(
            1.0,
            (hsv.hue + 22) % 360,
            (hsv.saturation * 0.75).clamp(0.0, 1.0),
            (hsv.value * 0.88).clamp(0.0, 1.0))
        .toColor();
    final c3 = HSVColor.fromAHSV(
            1.0,
            (hsv.hue + 300) % 360,
            (hsv.saturation * 0.60).clamp(0.0, 1.0),
            (hsv.value * 0.78).clamp(0.0, 1.0))
        .toColor();

    final radial = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.40),
        radius: 1.15,
        colors: [
          Color.lerp(c1, Colors.white, 0.16)!.withOpacity(0.98),
          c2.withOpacity(0.96),
          c3.withOpacity(0.92),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawCircle(p, r, radial);

    final rot = (timeSeconds * 0.55) % (pi * 2);
    final sweep = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: rot,
        endAngle: rot + pi * 2,
        colors: [
          baseColor.withOpacity(0.05),
          Colors.white.withOpacity(0.10),
          baseColor.withOpacity(0.06),
          Colors.black.withOpacity(0.08),
          baseColor.withOpacity(0.05),
        ],
        stops: const [0.0, 0.22, 0.5, 0.72, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.softLight;

    canvas.drawCircle(p, r, sweep);

    final hx = p.dx + (r * 0.35) * sin(timeSeconds * 0.85 + 0.6);
    final hy = p.dy - (r * 0.35) * cos(timeSeconds * 0.80 + 1.2);
    final highlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.00),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(hx, hy), radius: r * 0.75))
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(p, r, highlight);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.14);
    canvas.drawCircle(p, r + 0.4, edge);
  }

  @override
  bool shouldRepaint(covariant _BallPainter oldDelegate) => true;
}
