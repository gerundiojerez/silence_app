import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

void main() => runApp(const SilenceApp());

enum Experience { ball, cascade, sand }

String experienceLabel(Experience e) {
  switch (e) {
    case Experience.ball:
      return 'Ball';
    case Experience.cascade:
      return 'Cascade';
      case Experience.sand:
  return 'Sand';
  }
}

Experience? parseExperience(String s) {
  if (s == 'ball') return Experience.ball;
  if (s == 'cascade') return Experience.cascade;
  if (s == 'sand') return Experience.sand;
  return null;
}

class SilenceApp extends StatefulWidget {
  const SilenceApp({super.key});
  @override
  State<SilenceApp> createState() => _SilenceAppState();
}

class _SilenceAppState extends State<SilenceApp> {
  bool darkMode = true;
  bool cargado = false;

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
      cargado = true;
    });
  }

  Future<void> _setTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => darkMode = value);
    await prefs.setBool('darkMode', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    if (!cargado) {
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Silence',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w300,
                  color: c.onBackground,
                ),
              ),
              const SizedBox(height: 24),
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
    );
  }
}

class Planta {
  final double x; // 0..1
  final double y; // 0..1
  int nivel; // 0..3
  Planta({required this.x, required this.y, required this.nivel});
}

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final rnd = Random();
  bool cargado = false;

  List<Planta> plantas = [];
  int silencioSeg = 5;

  Set<Experience> enabledExperiences = {Experience.ball, Experience.cascade};

  late final AnimationController celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> pulse = Tween<double>(begin: 1.0, end: 1.06)
      .animate(CurvedAnimation(parent: celebrate, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    celebrate.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();

    // plantas
    final raw = prefs.getStringList('plantas') ?? [];
    final List<Planta> parsed = [];
    for (final s in raw) {
      try {
        if (s.contains('|')) {
          final parts = s.split('|');
          if (parts.length != 3) continue;
          parsed.add(Planta(
            x: double.parse(parts[0]),
            y: double.parse(parts[1]),
            nivel: int.parse(parts[2]),
          ));
        } else if (s.contains('=') && s.contains('&')) {
          final q = Uri.splitQueryString(s);
          parsed.add(Planta(
            x: double.parse(q['x'] ?? ''),
            y: double.parse(q['y'] ?? ''),
            nivel: int.parse(q['nivel'] ?? '0'),
          ));
        }
      } catch (_) {}
    }
    plantas = parsed;

    // timer
    silencioSeg = prefs.getInt('silencioSeg') ?? 5;

    // experiences
    final expRaw = prefs.getStringList('experiences') ?? ['ball', 'cascade', 'sand'];
    final set = <Experience>{};
    for (final s in expRaw) {
      final e = parseExperience(s);
      if (e != null) set.add(e);
    }
    if (set.isEmpty) set.add(Experience.ball);
    enabledExperiences = set;

    await _guardar();

    if (!mounted) return;
    setState(() => cargado = true);
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'plantas',
      plantas.map((p) => '${p.x}|${p.y}|${p.nivel}').toList(),
    );
    await prefs.setInt('silencioSeg', silencioSeg);
    await prefs.setStringList(
      'experiences',
      enabledExperiences.map((e) => e.name).toList(),
    );
  }

  String emojiParaNivel(int n) {
    if (n == 0) return '🌱';
    if (n == 1) return '🌿';
    if (n == 2) return '🌲';
    return '🌳';
  }

  double sizeParaNivel(int n) {
    if (n == 0) return 28;
    if (n == 1) return 42;
    if (n == 2) return 58;
    return 74;
  }

  Experience _pickExperience() {
    final list = enabledExperiences.toList();
    if (list.isEmpty) return Experience.ball;
    return list[rnd.nextInt(list.length)];
  }

  Future<void> abrirSilencio() async {
    final exp = _pickExperience();

        bool? ok;
    if (exp == Experience.ball) {
      ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => BallSilenceScreen(segundos: silencioSeg)),
      );
    } else if (exp == Experience.cascade) {
      ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CascadeSilenceScreen(segundos: silencioSeg)),
      );
    } else {
      ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => SandSilenceScreen(segundos: silencioSeg)),
      );
    }


    if (ok == true) {
      HapticFeedback.lightImpact();

      setState(() {
        if (plantas.isEmpty || rnd.nextBool()) {
          plantas.add(Planta(
            x: rnd.nextDouble() * 0.86 + 0.07,
            y: rnd.nextDouble() * 0.62 + 0.20,
            nivel: 0,
          ));
        } else {
          final i = rnd.nextInt(plantas.length);
          plantas[i].nivel = min(3, plantas[i].nivel + 1);
        }
      });

      await _guardar();
      if (mounted) celebrate.forward(from: 0);
    }
  }

  Future<void> abrirSettings() async {
    final result = await Navigator.of(context).push<SettingsResult>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          initialSeconds: silencioSeg,
          initialDarkMode: widget.darkMode,
          initialExperiences: enabledExperiences,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      silencioSeg = result.seconds;
      enabledExperiences = result.experiences.isEmpty ? {Experience.ball} : result.experiences;
    });

    await _guardar();
    await widget.onSetTheme(result.darkMode);
  }

  @override
  Widget build(BuildContext context) {
    if (!cargado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: abrirSettings,
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: pulse,
                builder: (_, __) => Transform.scale(
                  scale: pulse.value,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      return Stack(
                        children: plantas.map((p) {
                          final size = sizeParaNivel(p.nivel);
                          final emoji = emojiParaNivel(p.nivel);

                          final left = (c.maxWidth * p.x) - (size / 2);
                          final top = (c.maxHeight * p.y) - (size / 2);

                          return Positioned(
                            left: left,
                            top: top,
                            child: Text(emoji, style: TextStyle(fontSize: size)),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonal(
              onPressed: abrirSilencio,
              child: const Text('Go to Silence'),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class SettingsResult {
  final int seconds;
  final bool darkMode;
  final Set<Experience> experiences;

  SettingsResult({
    required this.seconds,
    required this.darkMode,
    required this.experiences,
  });
}

class SettingsScreen extends StatefulWidget {
  final int initialSeconds;
  final bool initialDarkMode;
  final Set<Experience> initialExperiences;

  const SettingsScreen({
    super.key,
    required this.initialSeconds,
    required this.initialDarkMode,
    required this.initialExperiences,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int seconds;
  late bool darkMode;
  late Set<Experience> experiences;

  @override
  void initState() {
    super.initState();
    seconds = widget.initialSeconds;
    darkMode = widget.initialDarkMode;
    experiences = {...widget.initialExperiences};
    if (experiences.isEmpty) experiences.add(Experience.ball);
  }

  String fmtMMSS(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  void saveAndExit() {
    Navigator.of(context).pop(
      SettingsResult(seconds: seconds, darkMode: darkMode, experiences: experiences),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onBg = Theme.of(context).colorScheme.onBackground;

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
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => seconds = max(5, seconds - 5)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Slider(
                  value: seconds.toDouble(),
                  min: 5,
                  max: 600,
                  divisions: 119,
                  label: fmtMMSS(seconds),
                  onChanged: (v) => setState(() => seconds = v.round()),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => seconds = min(600, seconds + 5)),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
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
          const SizedBox(height: 22),
          Text('Experiences', style: TextStyle(fontSize: 18, color: onBg)),
          const SizedBox(height: 8),
          _expTile(Experience.ball),
          _expTile(Experience.cascade),
          _expTile(Experience.sand),
          const SizedBox(height: 8),
          Text(
            'Tip: desmarca para probar una sola experiencia.',
            style: TextStyle(color: onBg.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _expTile(Experience e) {
    final checked = experiences.contains(e);
    return CheckboxListTile(
      value: checked,
      title: Text(experienceLabel(e)),
      onChanged: (v) {
        setState(() {
          if (v == true) {
            experiences.add(e);
          } else {
            experiences.remove(e);
            if (experiences.isEmpty) experiences.add(Experience.ball);
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

/// ==================== EXPERIENCE 1: BALL ====================

class BallSilenceScreen extends StatefulWidget {
  final int segundos;
  const BallSilenceScreen({super.key, required this.segundos});

  @override
  State<BallSilenceScreen> createState() => _BallSilenceScreenState();
}

class _BallSilenceScreenState extends State<BallSilenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  final rnd = Random();

  double x = 0.5, y = 0.5;
  late double vx, vy;
  Duration? prev;

  late final AudioPlayer player;
  DateTime _lastSound = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    player.setVolume(0.35);
    Future.microtask(() async {
      try {
        await player.setSource(AssetSource('sounds/soft_pop.mp3'));
      } catch (_) {}
    });

    x = rnd.nextDouble() * 0.8 + 0.1;
    y = rnd.nextDouble() * 0.8 + 0.1;

    final speed = 0.35 + rnd.nextDouble() * 0.35;
    final angle = rnd.nextDouble() * pi * 2;
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.segundos),
    )
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop(true);
        }
      });

    controller.forward();
  }

  Future<void> _playBounce() async {
    final now = DateTime.now();
    if (now.difference(_lastSound).inMilliseconds < 70) return;
    _lastSound = now;

    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      try {
        await player.play(AssetSource('sounds/soft_pop.mp3'), volume: 0.35);
      } catch (_) {}
    }
  }

  void _tick() {
    final now = controller.lastElapsedDuration ?? Duration.zero;
    final p = prev ?? now;
    final dt = (now - p).inMicroseconds / 1e6;
    prev = now;
    if (dt <= 0) return;

    x += vx * dt;
    y += vy * dt;

    bool bounce = false;

    if (x < 0) {
      x = -x;
      vx = -vx;
      bounce = true;
    } else if (x > 1) {
      x = 2 - x;
      vx = -vx;
      bounce = true;
    }

    if (y < 0) {
      y = -y;
      vy = -vy;
      bounce = true;
    } else if (y > 1) {
      y = 2 - y;
      vy = -vy;
      bounce = true;
    }

    if (bounce) {
      HapticFeedback.selectionClick();
      _playBounce();
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = controller.value; // 0..1
    final dotColor = Color.lerp(Colors.greenAccent, Colors.redAccent, t)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (_, c) {
          final px = x * c.maxWidth;
          final py = y * c.maxHeight;
          return Stack(
            children: [
              Positioned(
                left: px - 10,
                top: py - 10,
                child: Text('●', style: TextStyle(fontSize: 26, color: dotColor)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ==================== EXPERIENCE 2: CASCADE ====================

class _Ball {
  Offset p;
  Offset v;
  final double r;
  final Color color;

  _Ball({
    required this.p,
    required this.v,
    required this.r,
    required this.color,
  });
}

class _Paddle {
  final Offset center;
  final double length;
  final double thickness;
  final double angle;
  final Color color;

  _Paddle({
    required this.center,
    required this.length,
    required this.thickness,
    required this.angle,
    required this.color,
  });
}

class CascadeSilenceScreen extends StatefulWidget {
  final int segundos;
  const CascadeSilenceScreen({super.key, required this.segundos});

  @override
  State<CascadeSilenceScreen> createState() => _CascadeSilenceScreenState();
}

class _CascadeSilenceScreenState extends State<CascadeSilenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  final rnd = Random();
  final List<_Ball> balls = [];
  final List<_Paddle> paddles = [];

  late final AudioPlayer player;
  DateTime _lastSound = DateTime.fromMillisecondsSinceEpoch(0);

  // física calmante
  final double gravity = 300; // más lento
  final double damping = 0.992;
  final double wallBounce = 0.92;
  final double restitutionBallBall = 0.85;

  Size size = Size.zero;
  Duration? prev;

  @override
  void initState() {
    super.initState();

    player = AudioPlayer();
    player.setReleaseMode(ReleaseMode.stop);
    player.setVolume(0.32);
    Future.microtask(() async {
      try {
        await player.setSource(AssetSource('sounds/soft_pop.mp3'));
      } catch (_) {}
    });

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.segundos),
    )
      ..addListener(_tick)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop(true);
        }
      });

    controller.forward();
  }

  void _initScene(Size s) {
    size = s;
    balls.clear();
    paddles.clear();

    // 3 plataformas pequeñas, inclinación random izq/der
    for (int i = 0; i < 3; i++) {
      final center = Offset(
        rnd.nextDouble() * s.width,
        (rnd.nextDouble() * 0.60 + 0.20) * s.height,
      );

      final length = 60 + rnd.nextDouble() * 20; // 60-80
      final thickness = 12.0; // grosor real para colisión robusta

      final base = (pi / 4) + (rnd.nextDouble() - 0.5) * (pi / 6); // 45° +- 15°
      final angle = rnd.nextBool() ? base : -base;

      paddles.add(
        _Paddle(
          center: center,
          length: length,
          thickness: thickness,
          angle: angle,
          color: const Color(0xFFB39DDB).withOpacity(0.80),
        ),
      );
    }

    // 3 pelotas pequeñas
    for (int i = 0; i < 3; i++) {
      balls.add(_spawnBall(top: true));
    }
  }

  _Ball _spawnBall({required bool top}) {
    final w = max(1.0, size.width);
    final r = 7 + rnd.nextDouble() * 2.5; // 7-9.5
    final x = rnd.nextDouble() * (w - 2 * r) + r;
    final y = top ? (-rnd.nextDouble() * 160 - r) : (rnd.nextDouble() * size.height * 0.2);

    final vx = (rnd.nextDouble() - 0.5) * 70;
    final vy = rnd.nextDouble() * 20;

    final palette = <Color>[
      const Color(0xFFAEDFF7),
      const Color(0xFFFFD6E7),
      const Color(0xFFD7F8D7),
      const Color(0xFFFFF0B3),
    ];
    final color = palette[rnd.nextInt(palette.length)].withOpacity(0.95);

    return _Ball(p: Offset(x, y), v: Offset(vx, vy), r: r, color: color);
  }

  Future<void> _playBounce() async {
    final now = DateTime.now();
    if (now.difference(_lastSound).inMilliseconds < 70) return;
    _lastSound = now;

    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      try {
        await player.play(AssetSource('sounds/soft_pop.mp3'), volume: 0.32);
      } catch (_) {}
    }
  }

  Offset _normalize(Offset v) {
    final d = v.distance;
    if (d == 0) return const Offset(0, -1);
    return v / d;
  }

  bool _collideBallWithPaddle(_Ball b, _Paddle p) {
    // transformar centro de pelota a coords locales del paddle
    final cosA = cos(-p.angle);
    final sinA = sin(-p.angle);

    final dx = b.p.dx - p.center.dx;
    final dy = b.p.dy - p.center.dy;

    final localX = dx * cosA - dy * sinA;
    final localY = dx * sinA + dy * cosA;

    final halfL = p.length / 2;
    final halfT = p.thickness / 2;

    // punto más cercano en AABB local
    final closestX = localX.clamp(-halfL, halfL);
    final closestY = localY.clamp(-halfT, halfT);

    final distX = localX - closestX;
    final distY = localY - closestY;

    final dist2 = distX * distX + distY * distY;
    if (dist2 > b.r * b.r) return false;

    // normal local
    final nLocal = _normalize(Offset(distX, distY));

    // normal mundo
    final cosB = cos(p.angle);
    final sinB = sin(p.angle);
    final nWorld = Offset(
      nLocal.dx * cosB - nLocal.dy * sinB,
      nLocal.dx * sinB + nLocal.dy * cosB,
    );

    // si viene hacia la superficie, reflejar
    final vDot = b.v.dx * nWorld.dx + b.v.dy * nWorld.dy;
    if (vDot < 0) {
      b.v = b.v - nWorld * (2 * vDot) * 0.90; // rebote suave
      // empujar fuera (corrige penetración)
      final pen = (b.r - sqrt(max(0.0, dist2))) + 1.0;
      b.p = b.p + nWorld * pen;
      return true;
    }

    // aunque esté dentro (por corrección numérica), empujar un poco
    final pen = (b.r - sqrt(max(0.0, dist2)));
    if (pen > 0.0) {
      b.p = b.p + nWorld * (pen + 0.5);
      return true;
    }

    return false;
  }

  void _resolveBallBall(_Ball a, _Ball b) {
    final dp = b.p - a.p;
    final dist = dp.distance;
    final minDist = a.r + b.r;
    if (dist <= 0 || dist >= minDist) return;

    final n = dp / dist;

    // separar
    final overlap = minDist - dist;
    a.p = a.p - n * (overlap * 0.5);
    b.p = b.p + n * (overlap * 0.5);

    // impulso (misma masa)
    final relV = b.v - a.v;
    final relDot = relV.dx * n.dx + relV.dy * n.dy;
    if (relDot > 0) return;

    final j = -(1 + restitutionBallBall) * relDot / 2;
    final impulse = n * j;
    a.v = a.v - impulse;
    b.v = b.v + impulse;
  }

  void _tick() {
    if (size == Size.zero) return;

    final now = controller.lastElapsedDuration ?? Duration.zero;
    final p = prev ?? now;
    final dt0 = (now - p).inMicroseconds / 1e6;
    prev = now;
    if (dt0 <= 0) return;

    // substeps anti-tunneling (igual, pero ahora con colisión robusta)
    final steps = (dt0 > 0.02) ? 6 : 4;
    final dt = dt0 / steps;

    bool bounced = false;

    for (int step = 0; step < steps; step++) {
      // integrar
      for (final b in balls) {
        b.v = Offset(b.v.dx, b.v.dy + gravity * dt);
        b.v = b.v * damping;
        b.p = b.p + b.v * dt;

        // paredes
        if (b.p.dx - b.r < 0) {
          b.p = Offset(b.r, b.p.dy);
          b.v = Offset(-b.v.dx * wallBounce, b.v.dy);
          bounced = true;
        } else if (b.p.dx + b.r > size.width) {
          b.p = Offset(size.width - b.r, b.p.dy);
          b.v = Offset(-b.v.dx * wallBounce, b.v.dy);
          bounced = true;
        }

        if (b.p.dy - b.r < 0) {
          b.p = Offset(b.p.dx, b.r);
          b.v = Offset(b.v.dx, -b.v.dy * wallBounce);
          bounced = true;
        }

        // plataformas (rectángulos con grosor)
        for (final pad in paddles) {
          if (_collideBallWithPaddle(b, pad)) {
            bounced = true;
          }
        }
      }

      // pelota–pelota (2 iteraciones)
      for (int iter = 0; iter < 2; iter++) {
        for (int i = 0; i < balls.length; i++) {
          for (int j = i + 1; j < balls.length; j++) {
            _resolveBallBall(balls[i], balls[j]);
          }
        }
      }
    }

    // respawn: mantener 3 pelotas
    balls.removeWhere((b) => b.p.dy - b.r > size.height + 80);
    while (balls.length < 3) {
      balls.add(_spawnBall(top: true));
    }

    if (bounced) {
      HapticFeedback.selectionClick();
      _playBounce();
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = controller.value;
    final bg = Color.lerp(const Color(0xFF0B0B10), const Color(0xFF141424), 0.6)!;

    return Scaffold(
      backgroundColor: bg,
      body: LayoutBuilder(
        builder: (_, c) {
          if (size == Size.zero) {
            _initScene(Size(c.maxWidth, c.maxHeight));
          }

          final glow = Color.lerp(
            const Color(0xFFB39DDB).withOpacity(0.07),
            const Color(0xFFFFD6E7).withOpacity(0.05),
            t,
          )!;

          return CustomPaint(
            painter: _CascadePainter(
              paddles: paddles,
              balls: balls,
              glow: glow,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _CascadePainter extends CustomPainter {
  final List<_Paddle> paddles;
  final List<_Ball> balls;
  final Color glow;

  _CascadePainter({
    required this.paddles,
    required this.balls,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // glow sutil
    canvas.drawRect(Offset.zero & size, Paint()..color = glow);

    // paddles: rectángulos rotados con esquinas redondeadas
    for (final p in paddles) {
      canvas.save();
      canvas.translate(p.center.dx, p.center.dy);
      canvas.rotate(p.angle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.length,
        height: p.thickness,
      );

      final paint = Paint()..color = p.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );

      canvas.restore();
    }

    // balls
    for (final b in balls) {
      canvas.drawCircle(b.p, b.r, Paint()..color = b.color);

      final halo = Paint()
        ..color = b.color.withOpacity(0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(b.p, b.r + 2.5, halo);
    }
  }

  @override
  bool shouldRepaint(covariant _CascadePainter oldDelegate) => true;
}
/// ==================== EXPERIENCE 3: SAND (stub) ====================

class SandSilenceScreen extends StatefulWidget {
  final int segundos;
  const SandSilenceScreen({super.key, required this.segundos});

  @override
  State<SandSilenceScreen> createState() => _SandSilenceScreenState();
}

class _SandSilenceScreenState extends State<SandSilenceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.segundos),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop(true);
        }
      });

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B10),
      body: SafeArea(
        child: Center(
          child: CustomPaint(
            painter: _SandBoxPainter(),
            size: const Size(320, 520),
          ),
        ),
      ),
    );
  }
}

class _SandBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // arena
    final sand = Paint()..color = const Color(0xFFE6D6B8).withOpacity(0.95);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, sand);

    // marco
    final frame = Paint()
      ..color = const Color(0xFF3A2E25).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawRRect(rect, frame);

    // borde interior
    final inner = Paint()
      ..color = const Color(0xFF6B5444).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final innerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(14),
    );
    canvas.drawRRect(innerRect, inner);

    // texto sutil
    final tp = TextPainter(
      text: TextSpan(
        text: 'Sand (soon)',
        style: TextStyle(
          color: const Color(0xFF0B0B10).withOpacity(0.45),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SandBoxPainter oldDelegate) => false;
}
