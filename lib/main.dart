import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const SilenceApp());

/// ==================== COPY (NO PERIODS) ====================

const List<String> kSessionPhrases = [
  'Do nothing',
  'Just stay',
  'Nothing to solve',
  'No effort needed',
  'Let it pass',
  'You can stop trying',
  'This is enough',
];

const List<String> kEndPhrases = [
  'That’s enough',
  'You can go now',
  'Silence continues outside',
  'Nothing else is required',
];

/// ==================== APP ====================

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
      );
    }

    final light = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF6F3FF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB39DDB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final dark = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0B10),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7E57C2),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
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

/// ==================== START (FADE-IN) ====================

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
    final c = Theme.of(context).colorScheme;

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
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Silence',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.w300,
                    color: c.onBackground,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Do nothing',
                  style: TextStyle(
                    fontSize: 16,
                    color: c.onBackground.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 26),
                FilledButton(
                  onPressed: go,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ==================== HOME ====================

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

  static const List<int> timeOptions = [30, 45, 60, 90, 120];

  int silenceSeconds = 45;
  bool soundOn = false;
  double volume = 0.18;
  double speedMul = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final savedSeconds = prefs.getInt('silenceSeconds');
    silenceSeconds = timeOptions.contains(savedSeconds) ? savedSeconds! : 45;

    soundOn = prefs.getBool('soundOn') ?? false;
    volume = (prefs.getDouble('volume') ?? 0.18).clamp(0.0, 0.35);
    speedMul = (prefs.getDouble('speedMul') ?? 1.0).clamp(0.7, 1.25);

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

  String fmtMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  /// ==================== CHANGE B: "SINK" TRANSITION HOME → BALL ====================
  Future<void> openSilence() async {
    await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, __, ___) => BallSilenceScreen(
          segundos: silenceSeconds,
          soundOn: soundOn,
          volume: volume,
          speedMul: speedMul,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

          // subtle "sink" scale (barely noticeable but felt)
          final scale = Tween<double>(begin: 0.985, end: 1.0).animate(curved);

          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: child,
            ),
          );
        },
      ),
    );
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
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final c = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    'Silence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: c.onBackground,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: openSettings,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              fmtMMSS(silenceSeconds),
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w300,
                color: c.onBackground.withOpacity(0.92),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No tapping needed',
              style: TextStyle(
                fontSize: 14,
                color: c.onBackground.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.tonal(
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
    );
  }
}

/// ==================== SETTINGS ====================

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
              Text(fmtMMSS(seconds), style: TextStyle(fontSize: 18, color: onBg)),
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
                Text(
                  'Volume',
                  style: TextStyle(fontSize: 16, color: onBg.withOpacity(0.9)),
                ),
                const Spacer(),
                Text(
                  '${(volume * 100).round()}%',
                  style: TextStyle(color: onBg.withOpacity(0.8)),
                ),
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
              Text(
                speedLabel(speedMul),
                style: TextStyle(fontSize: 16, color: onBg.withOpacity(0.8)),
              ),
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
            'Silence works best when you don’t interact\nSound is optional and should remain soft',
            style: TextStyle(color: onBg.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

/// ==================== EXPERIENCE: BALL ====================

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

  // bounce sound control
  DateTime _lastBounceSound = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _minBounceMs = 180;
  static const double _bounceChance = 0.35;

  late final String sessionPhrase;
  late final String endPhrase;
  bool showSessionText = true;
  bool showEndText = false;
  bool _popping = false;

  /// ==================== CHANGE A: GRAIN IMAGE (TILED) ====================
  ui.Image? _noiseImage;

  @override
  void initState() {
    super.initState();

    sessionPhrase = kSessionPhrases[rnd.nextInt(kSessionPhrases.length)];
    endPhrase = (rnd.nextDouble() < 0.55)
        ? kEndPhrases.first
        : kEndPhrases[rnd.nextInt(kEndPhrases.length)];

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
        if (s == AnimationStatus.completed) {
          _onComplete();
        }
      });

    _initAudio();
    _scheduleSessionTextFade();
    _buildNoiseImage();

    controller.forward();
  }

  void _scheduleSessionTextFade() {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => showSessionText = false);
    });
  }

  Future<void> _initAudio() async {
    if (!widget.soundOn) return;

    // ambient
    try {
      final p = AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(widget.volume.clamp(0.0, 0.35));
      await p.setSource(AssetSource('sounds/ambient.mp3'));
      await p.resume();
      ambientPlayer = p;
    } catch (_) {}

    // bounce
    try {
      final p2 = AudioPlayer();
      await p2.setReleaseMode(ReleaseMode.stop);
      await p2.setSource(AssetSource('sounds/soft_pop.mp3'));
      bouncePlayer = p2;
    } catch (_) {}
  }

  Future<void> _maybePlayBounce() async {
    if (!widget.soundOn) return;
    if (bouncePlayer == null) return;

    if (rnd.nextDouble() > _bounceChance) return;

    final now = DateTime.now();
    if (now.difference(_lastBounceSound).inMilliseconds < _minBounceMs) return;
    _lastBounceSound = now;

    final bounceVol = (widget.volume * 0.45).clamp(0.0, 0.16);

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

    await Future.delayed(const Duration(milliseconds: 2400));
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

    // gentle damping
    final damp = pow(0.995, dt * 60).toDouble();
    vx *= damp;
    vy *= damp;

    // tiny random drift
    final wobble = 0.010 * spMul;
    vx += (rnd.nextDouble() - 0.5) * wobble * dt;
    vy += (rnd.nextDouble() - 0.5) * wobble * dt;

    // clamp speed
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

    if (bounced) _maybePlayBounce();

    if (mounted) setState(() {});
  }

  /// ==================== CHANGE A: BUILD A SMALL NOISE TILE ====================
  Future<void> _buildNoiseImage() async {
    // 256x256 tile, sparse bright pixels
    const w = 256;
    const h = 256;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // transparent base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = const Color(0x00000000),
    );

    final r = Random(1337);
    final paint = Paint()..color = const Color(0xFFFFFFFF);

    // tweak density here (higher = more visible grain)
    const dots = 5200;

    for (int i = 0; i < dots; i++) {
      final dx = r.nextDouble() * w;
      final dy = r.nextDouble() * h;

      // brightness distribution (mostly faint)
      final a = (r.nextDouble() * r.nextDouble() * 40 + 6).clamp(0, 60).toInt();
      paint.color = Color.fromARGB(a, 255, 255, 255);

      // tiny rects rather than points (better on some GPUs)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: LayoutBuilder(
        builder: (_, c) {
          final px = x * c.maxWidth;
          final py = y * c.maxHeight;

          // subtle, non-rhythmic breathing
          final t = controller.value; // 0..1
          final r = 10 +
              2.2 * sin(t * pi * 2) +
              1.2 * sin(t * pi * 0.27 + 1.7);

          // micro offset for "organic" halo
          final ox = 0.9 * sin(t * pi * 0.13 + 0.6);
          final oy = 0.9 * cos(t * pi * 0.11 + 2.1);

          return Stack(
            children: [
              CustomPaint(
                painter: _BallPainter(
                  p: Offset(px, py),
                  r: r,
                  haloOffset: Offset(ox, oy),
                  noise: _noiseImage,
                ),
                child: const SizedBox.expand(),
              ),
              IgnorePointer(
                ignoring: true,
                child: AnimatedOpacity(
                  opacity: showSessionText ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOut,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        sessionPhrase,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.38),
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
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

/// ==================== PAINTER ====================
/// Implements
/// - Change A: grain + vignette (visible, elegant)
/// - Change C: premium bloom glow (layered halos)

class _BallPainter extends CustomPainter {
  final Offset p;
  final double r;
  final Offset haloOffset;
  final ui.Image? noise;

  _BallPainter({
    required this.p,
    required this.r,
    required this.haloOffset,
    required this.noise,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // background gradient (ultra subtle)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF000000),
          Color(0xFF050508),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bgPaint);

    /// ==================== CHANGE A: VIGNETTE ====================
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.92,
        colors: [
          const Color(0x00000000),
          const Color(0x00000000),
          const Color(0xAA000000),
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, vignette);

    /// ==================== CHANGE A: GRAIN OVERLAY (TILED) ====================
    if (noise != null) {
      final shader = ImageShader(
        noise!,
        TileMode.repeated,
        TileMode.repeated,
        // scale grain a bit larger so it reads nicely on phones
        Matrix4.identity().scaled(1.35, 1.35).storage,
      );

      final grainPaint = Paint()
        ..shader = shader
        ..colorFilter = const ColorFilter.mode(
          Color(0x1AFFFFFF), // overall intensity of grain
          BlendMode.srcIn,
        )
        ..blendMode = BlendMode.softLight; // subtle, film-like

      canvas.drawRect(Offset.zero & size, grainPaint);
    }

    /// ==================== CHANGE C: PREMIUM BLOOM ====================
    // bloom core
    final bloom1 = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final bloom2 = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    final bloom3 = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);

    // slightly offset bloom for organic feel
    final p2 = p + haloOffset * 1.2;
    canvas.drawCircle(p2, r + 14, bloom3);
    canvas.drawCircle(p2, r + 9, bloom2);
    canvas.drawCircle(p, r + 6, bloom1);

    // dot
    final dot = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawCircle(p, r, dot);

    // tiny crisp inner edge (premium)
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withOpacity(0.16);
    canvas.drawCircle(p, r + 0.4, edge);
  }

  @override
  bool shouldRepaint(covariant _BallPainter oldDelegate) => true;
}
