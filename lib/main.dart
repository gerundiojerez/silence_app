import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const SilenceApp());

/// =============================================================
///  PHRASES (EN) — short, present-focused (paraphrases)
/// =============================================================

const List<String> kSessionPhrases = [
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
///  APP
/// =============================================================

class SilenceApp extends StatefulWidget {
  const SilenceApp({super.key});
  @override
  State<SilenceApp> createState() => _SilenceAppState();
}

class _SilenceAppState extends State<SilenceApp> {
  bool darkMode = true;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? true;
      loaded = true;
    });
  }

  Future<void> _setTheme(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkMode = v);
    await prefs.setBool('darkMode', v);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    ThemeData baseTheme(Brightness b, Color seed, Color bg) {
      final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
      final onBg = scheme.onBackground;

      return ThemeData(
        brightness: b,
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: bg,
        fontFamilyFallback: const ['Inter', 'SF Pro Display', 'Roboto'],
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.2,
            height: 1.05,
            color: onBg,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.7,
            height: 1.25,
            color: onBg.withOpacity(0.86),
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.6,
            height: 1.25,
            color: onBg.withOpacity(0.90),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.55,
            height: 1.55,
            color: onBg.withOpacity(0.82),
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.45,
            height: 1.45,
            color: onBg.withOpacity(0.62),
          ),
        ),
      );
    }

    final light = baseTheme(
      Brightness.light,
      const Color(0xFF9B8CFF),
      const Color(0xFFF6F3FF),
    );

    final dark = baseTheme(
      Brightness.dark,
      const Color(0xFF7E57C2),
      const Color(0xFF0B0B10),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Silence',
      theme: light,
      darkTheme: dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: StartScreen(
        darkMode: darkMode,
        onSetTheme: _setTheme,
      ),
    );
  }
}

/// =============================================================
///  START
/// =============================================================

class StartScreen extends StatelessWidget {
  final bool darkMode;
  final Future<void> Function(bool) onSetTheme;

  const StartScreen({
    super.key,
    required this.darkMode,
    required this.onSetTheme,
  });

  @override
  Widget build(BuildContext context) {
    void go() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            darkMode: darkMode,
            onSetTheme: onSetTheme,
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF121225),
                Color(0xFF1B1837),
                Color(0xFF0B0B10),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Silence',
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
///  - Adds: Today silence marker (resets daily)
///  - Extends: time options
/// =============================================================

class HomeScreen extends StatefulWidget {
  final bool darkMode;
  final Future<void> Function(bool) onSetTheme;

  const HomeScreen({
    super.key,
    required this.darkMode,
    required this.onSetTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loaded = false;

  // Extended options:
  // 30s, 45s, 1m, 1.5m, 2m, 5m, 10m, 20m, 30m
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

  Future<void> openSilence() async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => BallSilenceScreen(
          segundos: silenceSeconds,
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
      // Session completed => add configured seconds
      await _addToday(silenceSeconds);
    } else {
      // Still ensure daily reset if date changed while in session.
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
          initialDarkMode: widget.darkMode,
          initialSoundOn: soundOn,
          initialVolume: volume,
          initialSpeedMul: speedMul,
          timeOptions: timeOptions,
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      silenceSeconds = result.seconds;
      soundOn = result.soundOn;
      volume = result.volume.clamp(0.0, 0.35);
      speedMul = result.speedMul.clamp(0.7, 1.25);
    });

    await _savePrefs();
    await widget.onSetTheme(result.darkMode);

    // refresh daily in case date changed
    final prefs = await SharedPreferences.getInstance();
    await _ensureDailyFresh(prefs);
    final v = prefs.getInt(kPrefDailySeconds) ?? 0;
    if (!mounted) return;
    setState(() => todaySeconds = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final c = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.background,
              c.background.withOpacity(0.88),
              c.background.withOpacity(0.78),
            ],
          ),
        ),
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

              // (4) Today marker — small, subtle, resets daily
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
              Text('No tapping needed.',
                  style: text.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: openSilence,
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
  final int seconds;
  final bool darkMode;
  final bool soundOn;
  final double volume;
  final double speedMul;

  SettingsResult({
    required this.seconds,
    required this.darkMode,
    required this.soundOn,
    required this.volume,
    required this.speedMul,
  });
}

class SettingsScreen extends StatefulWidget {
  final int initialSeconds;
  final bool initialDarkMode;
  final bool initialSoundOn;
  final double initialVolume;
  final double initialSpeedMul;
  final List<int> timeOptions;

  const SettingsScreen({
    super.key,
    required this.initialSeconds,
    required this.initialDarkMode,
    required this.initialSoundOn,
    required this.initialVolume,
    required this.initialSpeedMul,
    required this.timeOptions,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int seconds;
  late bool darkMode;
  late bool soundOn;
  late double volume;
  late double speedMul;

  @override
  void initState() {
    super.initState();
    seconds = widget.initialSeconds;
    darkMode = widget.initialDarkMode;
    soundOn = widget.initialSoundOn;
    volume = widget.initialVolume.clamp(0.0, 0.35);
    speedMul = widget.initialSpeedMul.clamp(0.7, 1.25);
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
        seconds: seconds,
        darkMode: darkMode,
        soundOn: soundOn,
        volume: volume,
        speedMul: speedMul,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;
    final timeIndex = secondsToIndex(seconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(onPressed: saveAndExit, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Timer', style: TextStyle(fontSize: 18, color: onBg)),
              const Spacer(),
              Text(fmtMMSS(seconds),
                  style: TextStyle(fontSize: 18, color: onBg)),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: timeIndex.toDouble(),
            min: 0,
            max: (widget.timeOptions.length - 1).toDouble(),
            divisions: widget.timeOptions.length - 1,
            label: fmtMMSS(seconds),
            onChanged: (v) {
              final idx = v.round().clamp(0, widget.timeOptions.length - 1);
              setState(() => seconds = widget.timeOptions[idx]);
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Night mode', style: TextStyle(fontSize: 18, color: onBg)),
              const Spacer(),
              Switch(
                value: darkMode,
                onChanged: (v) => setState(() => darkMode = v),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                    style:
                        TextStyle(fontSize: 16, color: onBg.withOpacity(0.9))),
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
                  style: TextStyle(fontSize: 16, color: onBg.withOpacity(0.8))),
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
            'Silence works best when you don’t interact.\nKeep sound soft.',
            style: TextStyle(color: onBg.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

/// =============================================================
///  EXPERIENCE: BALL
///  Changes:
///   (1) Color cycling, premium
///   (2) Bounce sound every bounce
/// =============================================================

class BallSilenceScreen extends StatefulWidget {
  final int segundos;
  final bool soundOn;
  final double volume;
  final double speedMul;

  const BallSilenceScreen({
    super.key,
    required this.segundos,
    required this.soundOn,
    required this.volume,
    required this.speedMul,
  });

  @override
  State<BallSilenceScreen> createState() => _BallSilenceScreenState();
}

class _BallSilenceScreenState extends State<BallSilenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  final rnd = Random();

  double x = 0.5, y = 0.5;
  double vx = 0.06, vy = 0.04;
  Duration? prev;

  AudioPlayer? ambientPlayer;
  AudioPlayer? bouncePlayer;

  DateTime _lastBounceSound = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minBounceMs =
      80; // short throttle to prevent double-fire per frame

  late final String sessionPhrase;
  late final String endPhrase;

  bool showSessionText = true;
  bool showEndText = false;
  bool _popping = false;

  ui.Image? _noiseImage;

  // Color cycle settings
  static const double _cycleSeconds = 14.0; // not too slow, not too fast

  @override
  void initState() {
    super.initState();

    sessionPhrase = kSessionPhrases[rnd.nextInt(kSessionPhrases.length)];
    endPhrase = kEndPhrases[rnd.nextInt(kEndPhrases.length)];

    x = rnd.nextDouble() * 0.6 + 0.2;
    y = rnd.nextDouble() * 0.6 + 0.2;

    final spMul = widget.speedMul.clamp(0.7, 1.25);
    final speed = (0.05 + rnd.nextDouble() * 0.06) * spMul;
    final angle = rnd.nextDouble() * pi * 2;
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.segundos),
    )
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _onComplete();
      });

    _initAudio();
    _scheduleSessionTextFade();
    _buildNoiseImage();

    controller.forward();
  }

  void _scheduleSessionTextFade() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => showSessionText = false);
    });
  }

  Future<void> _initAudio() async {
    if (!widget.soundOn) return;

    // Ambient loop
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(widget.volume.clamp(0.0, 0.35));
      await p.setSource(AssetSource('sounds/ambient.mp3'));
      await p.resume();
      ambientPlayer = p;
    } catch (_) {}

    // Bounce FX
    try {
      final p2 = AudioPlayer();
      await p2.setReleaseMode(ReleaseMode.stop);
      await p2.setSource(AssetSource('sounds/soft_pop.mp3'));
      bouncePlayer = p2;
    } catch (_) {}
  }

  Future<void> _playBounce() async {
    if (!widget.soundOn) return;
    if (bouncePlayer == null) return;

    final now = DateTime.now();
    if (now.difference(_lastBounceSound).inMilliseconds < _minBounceMs) return;
    _lastBounceSound = now;

    final bounceVol = (widget.volume * 0.50).clamp(0.0, 0.18);
    try {
      await bouncePlayer!.setVolume(bounceVol);
      await bouncePlayer!.seek(Duration.zero);
      await bouncePlayer!.resume();
    } catch (_) {
      try {
        await bouncePlayer!.play(
          AssetSource('sounds/soft_pop.mp3'),
          volume: bounceVol,
        );
      } catch (_) {}
    }
  }

  Future<void> _onComplete() async {
    if (_popping) return;
    _popping = true;

    if (!mounted) return;
    setState(() {
      showEndText = true;
      showSessionText = false;
    });

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _tick() {
    final now = controller.lastElapsedDuration ?? Duration.zero;
    final p = prev ?? now;
    final dt = (now - p).inMicroseconds / 1e6;
    prev = now;
    if (dt <= 0) return;

    final spMul = widget.speedMul.clamp(0.7, 1.25);

    final damp = pow(0.995, dt * 60).toDouble();
    vx *= damp;
    vy *= damp;

    final wobble = 0.010 * spMul;
    vx += (rnd.nextDouble() - 0.5) * wobble * dt;
    vy += (rnd.nextDouble() - 0.5) * wobble * dt;

    final sp = sqrt(vx * vx + vy * vy);
    final minSp = 0.04 * spMul;
    final maxSp = 0.12 * spMul;
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

    bool bounced = false;
    if (x < 0) {
      x = -x;
      vx = -vx;
      bounced = true;
    } else if (x > 1) {
      x = 2 - x;
      vx = -vx;
      bounced = true;
    }
    if (y < 0) {
      y = -y;
      vy = -vy;
      bounced = true;
    } else if (y > 1) {
      y = 2 - y;
      vy = -vy;
      bounced = true;
    }

    if (bounced) _playBounce();
    if (mounted) setState(() {});
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
    controller.dispose();
    ambientPlayer?.dispose();
    bouncePlayer?.dispose();
    _noiseImage?.dispose();
    super.dispose();
  }

  String _fmtMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  // Smooth, premium color cycling:
  // - uses hue rotation
  // - clamps saturation/value to avoid “RGB toy”
  Color _colorAt(double seconds) {
    final phase = (seconds / _cycleSeconds) % 1.0;

    // A subtle easing so the hue drift feels natural.
    final eased = Curves.easeInOut.transform(phase);

    final hue = eased * 360.0;

    // Keep it vivid but not neon.
    final hsv = HSVColor.fromAHSV(1.0, hue, 0.78, 1.0);
    return hsv.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed =
        (controller.lastElapsedDuration ?? Duration.zero).inMilliseconds /
            1000.0;
    final ballColor = _colorAt(elapsed);

    final remaining = (widget.segundos * (1.0 - controller.value))
        .ceil()
        .clamp(0, widget.segundos);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(
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
                  p: Offset(px, py),
                  r: rr,
                  haloOffset: Offset(ox, oy),
                  noise: _noiseImage,
                  ballColor: ballColor,
                ),
                child: const SizedBox.expand(),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Opacity(
                  opacity: 0.28,
                  child: Text(
                    _fmtMMSS(remaining),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: showSessionText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOut,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        sessionPhrase,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                        endPhrase,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.55),
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
    );
  }
}

/// =============================================================
///  PAINTER — now tinted bloom + dot by ballColor (premium)
/// =============================================================

class _BallPainter extends CustomPainter {
  final Offset p;
  final double r;
  final Offset haloOffset;
  final ui.Image? noise;
  final Color ballColor;

  _BallPainter({
    required this.p,
    required this.r,
    required this.haloOffset,
    required this.noise,
    required this.ballColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF07070C),
          Color(0xFF0E0C1A),
          Color(0xFF000000),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
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

    // Tinted glow derived from ballColor (keeps premium look)
    final glowColor = ballColor.withOpacity(0.18);
    final glowColor2 = ballColor.withOpacity(0.12);
    final glowColor3 = ballColor.withOpacity(0.08);

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

    canvas.drawCircle(p2, r + 14, bloom3);
    canvas.drawCircle(p2, r + 9, bloom2);
    canvas.drawCircle(p, r + 6, bloom1);

    // Core dot: slightly whiter center but colored body
    final dot = Paint()
      ..color = Color.lerp(ballColor, Colors.white, 0.18)!.withOpacity(0.98);
    canvas.drawCircle(p, r, dot);

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.16);
    canvas.drawCircle(p, r + 0.4, edge);
  }

  @override
  bool shouldRepaint(covariant _BallPainter oldDelegate) => true;
}
