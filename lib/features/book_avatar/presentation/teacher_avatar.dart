import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/avatar_models.dart';

enum AvatarMood { idle, listening, thinking, speaking }

/// Live 2D teacher avatar (port of the web SVG avatar): breathing, blinking, lip-sync driven
/// by [mouth] (0–1), a listening pulse, a thinking bubble and head motion while speaking.
/// Respects the platform's reduce-motion setting.
class TeacherAvatar extends StatefulWidget {
  const TeacherAvatar({super.key, required this.appearance, this.mood = AvatarMood.idle, this.mouth = 0, this.size = 220, this.semanticLabel});

  final AvatarAppearance appearance;
  final AvatarMood mood;
  final double mouth;
  final double size;
  final String? semanticLabel;

  @override
  State<TeacherAvatar> createState() => _TeacherAvatarState();
}

class _TeacherAvatarState extends State<TeacherAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 60));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 280 / 240),
        painter: _AvatarPainter(widget.appearance, widget.mood, widget.mouth, _clock.value * 60),
      ),
    );
    return Semantics(label: widget.semanticLabel, image: widget.semanticLabel != null, excludeSemantics: true, child: painter);
  }
}

Color _c(int argb) => Color(argb);

/// Darken (amt < 0) or lighten (amt > 0) a colour.
Color shade(Color color, double amt) {
  int f(double c) {
    final v = c * 255;
    return (amt < 0 ? v + v * amt : v + (255 - v) * amt).round().clamp(0, 255);
  }

  return Color.fromARGB(255, f(color.r), f(color.g), f(color.b));
}

/// Minimal SVG path parser (absolute M, L, C, Q, Z) — enough for the avatar shapes.
Path svgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MLCQZ]|-?\d*\.?\d+').allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  var cmd = 'M';
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'^[MLCQZ]$').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        path.moveTo(n(), n());
        cmd = 'L';
      case 'L':
        path.lineTo(n(), n());
      case 'C':
        path.cubicTo(n(), n(), n(), n(), n(), n());
      case 'Q':
        path.quadraticBezierTo(n(), n(), n(), n());
      case 'Z':
        path.close();
    }
  }
  return path;
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.a, this.mood, this.mouth, this.t);

  final AvatarAppearance a;
  final AvatarMood mood;
  final double mouth;

  /// Seconds since the clock started.
  final double t;

  static final _cache = <String, Path>{};
  Path p(String d) => _cache.putIfAbsent(d, () => svgPath(d));

  Paint fill(Color c, [double opacity = 1]) => Paint()..color = c.withValues(alpha: opacity);
  Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 280);
    final skin = _c(a.skinTone), hair = _c(a.hairColor), outfit = _c(a.outfitColor), accent = _c(a.accentColor), bg = _c(a.background);
    final skinShadow = shade(skin, -0.18), hairDark = shade(hair, -0.25), outfitDark = shade(outfit, -0.25);
    final female = a.gender == AvatarGender.female;
    final hijab = a.hairStyle == HairStyle.hijab;
    final speaking = mood == AvatarMood.speaking;
    final m = speaking ? mouth.clamp(0.0, 1.0) : 0.0;
    final lookUp = mood == AvatarMood.thinking;
    final brow = mood == AvatarMood.listening ? -3.0 : (mood == AvatarMood.thinking ? -2.0 : 0.0);
    const white = Color(0xFFF8FAFC);

    // Background (rounded card + soft radial light).
    final card = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 240, 280), const Radius.circular(28));
    canvas.clipRRect(card);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 240, 280),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.24),
          radius: 0.9,
          colors: [shade(bg, 0.35), bg],
        ).createShader(const Rect.fromLTWH(0, 0, 240, 280)),
    );

    if (mood == AvatarMood.listening) {
      final phase = (t % 1.4) / 1.4;
      canvas.save();
      canvas.translate(120, 140);
      canvas.scale(0.92 + 0.2 * phase);
      canvas.drawCircle(Offset.zero, 104, stroke(accent.withValues(alpha: 0.55 * (1 - phase)), 6));
      canvas.restore();
    }

    // Breathing body.
    canvas.save();
    canvas.translate(0, -1.6 * (0.5 - 0.5 * math.cos(2 * math.pi * t / 4.2)));

    if (a.hairStyle == HairStyle.long) canvas.drawPath(p('M66 118 C 60 175, 64 225, 78 250 L 162 250 C 176 225, 180 175, 174 118 Z'), fill(hairDark));
    if (hijab) canvas.drawPath(p('M58 120 C 54 190, 40 230, 30 280 L 210 280 C 200 230, 186 190, 182 120 C 178 60, 62 60, 58 120 Z'), fill(accent));

    canvas.drawPath(p('M28 280 C 32 228, 72 206, 120 206 C 168 206, 208 228, 212 280 Z'), fill(outfit));
    switch (a.outfit) {
      case Outfit.blazer:
        canvas.drawPath(p('M98 208 L 120 262 L 142 208 C 132 206, 108 206, 98 208 Z'), fill(white));
        canvas.drawPath(p('M96 208 L 120 262 L 104 280 L 70 280 C 72 240, 84 216, 96 208 Z'), fill(outfitDark));
        canvas.drawPath(p('M144 208 L 120 262 L 136 280 L 170 280 C 168 240, 156 216, 144 208 Z'), fill(outfitDark));
      case Outfit.shirt:
        canvas.drawPath(p('M104 207 L 120 236 L 136 207 Z'), fill(skin));
        canvas.drawPath(p('M100 206 L 120 238 L 110 246 L 92 214 Z M140 206 L 120 238 L 130 246 L 148 214 Z'), fill(white));
        canvas.drawCircle(const Offset(120, 252), 2, fill(outfitDark));
        canvas.drawCircle(const Offset(120, 268), 2, fill(outfitDark));
      case Outfit.panjabi:
        canvas.drawPath(p('M112 207 C 114 214, 126 214, 128 207 Z'), fill(skin));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(117, 212, 6, 56), const Radius.circular(2)), fill(outfitDark, 0.35));
        for (final y in const [222.0, 236.0, 250.0]) {
          canvas.drawCircle(Offset(120, y), 1.8, fill(accent));
        }
      case Outfit.saree:
        canvas.drawPath(p('M104 207 C 110 218, 130 218, 136 207 Z'), fill(skin));
        canvas.drawPath(p('M150 208 C 132 236, 104 256, 82 280 L 120 280 C 138 256, 160 236, 178 220 C 170 213, 160 209, 150 208 Z'), fill(accent));
        canvas.drawPath(p('M150 208 C 132 236, 104 256, 82 280'), stroke(shade(accent, 0.4), 3));
      case Outfit.salwar:
        canvas.drawPath(p('M104 207 C 110 220, 130 220, 136 207 Z'), fill(skin));
        canvas.drawPath(p('M62 236 C 90 252, 150 252, 178 236 L 184 252 C 150 270, 90 270, 56 252 Z'), fill(accent, 0.9));
    }

    // Head (tilts while speaking, looks up while thinking).
    canvas.save();
    canvas.translate(120, 190);
    var tilt = 0.0;
    if (speaking) tilt = 1.4 * math.sin(2 * math.pi * t / 1.6) * math.pi / 180;
    if (lookUp) tilt = -3 * math.pi / 180;
    canvas.rotate(tilt);
    canvas.translate(-120, -190);

    canvas.drawPath(p('M104 160 L 104 204 C 112 212, 128 212, 136 204 L 136 160 Z'), fill(skin));
    canvas.drawPath(p('M104 178 C 112 188, 128 188, 136 178 L 136 166 L 104 166 Z'), fill(skinShadow, 0.5));
    if (!hijab) {
      canvas.drawOval(Rect.fromCenter(center: const Offset(72, 124), width: 16, height: 24), fill(skin));
      canvas.drawOval(Rect.fromCenter(center: const Offset(168, 124), width: 16, height: 24), fill(skin));
      if (female) {
        canvas.drawCircle(const Offset(72, 138), 2.6, fill(accent));
        canvas.drawCircle(const Offset(168, 138), 2.6, fill(accent));
      }
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(120, 118), width: 96, height: 112), fill(skin));

    switch (a.hairStyle) {
      case HairStyle.short:
        canvas.drawPath(p('M71 112 C 66 66, 100 52, 122 54 C 150 54, 176 70, 170 112 C 164 92, 150 80, 122 80 C 98 80, 80 90, 71 112 Z'), fill(hair));
      case HairStyle.sidePart:
        canvas.drawPath(
          p('M70 116 C 64 70, 96 50, 124 52 C 156 54, 178 74, 170 114 C 164 94, 154 84, 136 80 C 124 92, 98 92, 80 96 C 76 102, 72 108, 70 116 Z'),
          fill(hair),
        );
      case HairStyle.long || HairStyle.bun:
        canvas.drawPath(
          p('M70 124 C 62 70, 96 52, 122 52 C 150 52, 180 70, 170 124 C 166 96, 152 82, 140 78 C 130 90, 104 88, 92 80 C 80 88, 72 104, 70 124 Z'),
          fill(hair),
        );
        if (a.hairStyle == HairStyle.bun) canvas.drawCircle(const Offset(120, 50), 18, fill(hair));
      case HairStyle.bald:
        canvas.drawPath(p('M72 120 C 70 106, 74 98, 78 94 L 80 120 Z M168 120 C 170 106, 166 98, 162 94 L 160 120 Z'), fill(hair));
      case HairStyle.hijab:
        canvas.drawPath(p('M66 126 C 60 64, 180 64, 174 126 C 172 96, 158 74, 120 72 C 82 74, 68 96, 66 126 Z'), fill(shade(accent, -0.12)));
    }

    // Brows.
    canvas.save();
    canvas.translate(0, brow);
    canvas.drawPath(p('M90 98 Q 101 92, 111 97'), stroke(hairDark, 3.4));
    canvas.drawPath(p('M129 97 Q 139 92, 150 98'), stroke(hairDark, 3.4));
    canvas.restore();

    // Eyes (blink every 5.2 s).
    final cycle = (t % 5.2) / 5.2;
    final blink = cycle > 0.92 && cycle < 0.98 ? 0.08 : 1.0;
    for (final (cx, px) in [(101.0, lookUp ? 104.0 : 101.0), (139.0, lookUp ? 142.0 : 139.0)]) {
      canvas.save();
      canvas.translate(cx, 114);
      canvas.scale(1, blink);
      canvas.translate(-cx, -114);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, 114), width: 17, height: 13), fill(Colors.white));
      final py = lookUp ? 111.0 : 114.5;
      canvas.drawCircle(Offset(px, py), 4.2, fill(const Color(0xFF2B1D16)));
      canvas.drawCircle(Offset(px + 1.5, py - 1.5), 1.3, fill(Colors.white));
      canvas.restore();
    }
    if (a.glasses) {
      final g = stroke(const Color(0xFF1F2937), 2.4);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(88, 104, 26, 20), const Radius.circular(7)), g);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(126, 104, 26, 20), const Radius.circular(7)), g);
      canvas.drawPath(p('M114 112 Q 120 108, 126 112'), g);
    }

    // Nose, cheeks, beard.
    canvas.drawPath(p('M120 120 C 118 130, 114 136, 118 139 C 121 140, 124 139, 125 137'), stroke(skinShadow, 2.2));
    canvas.drawCircle(const Offset(92, 136), 7, fill(const Color(0xFFF08A8A), 0.18));
    canvas.drawCircle(const Offset(148, 136), 7, fill(const Color(0xFFF08A8A), 0.18));
    if (a.beard) {
      canvas.drawPath(
        p('M76 132 C 80 168, 100 178, 120 178 C 140 178, 160 168, 164 132 C 160 150, 146 160, 140 154 C 132 160, 108 160, 100 154 C 94 160, 80 150, 76 132 Z'),
        fill(hair, 0.85),
      );
    }

    // Mouth (lip-sync).
    if (m < 0.06) {
      canvas.drawPath(p('M106 150 Q 120 160, 134 150'), stroke(const Color(0xFF8C3B3B), 3.2));
    } else {
      final ry = 2.5 + m * 9;
      canvas.drawOval(Rect.fromCenter(center: Offset(120, 152 + m * 2), width: 2 * (11 + m * 2), height: 2 * ry), fill(const Color(0xFF5B1F23)));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(112, 150 - ry + 1.5, 16, math.min(4, 1 + m * 4)), const Radius.circular(1.5)),
        fill(Colors.white, 0.9),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(120, 154 + m * 6), width: 2 * (6 + m * 2), height: 2 * (1.5 + m * 2.5)),
        fill(const Color(0xFFE36F7A), 0.85),
      );
    }
    canvas.restore(); // head
    canvas.restore(); // breathing

    if (mood == AvatarMood.thinking) {
      canvas.drawCircle(const Offset(186, 58), 20, fill(Colors.white, 0.95));
      canvas.drawCircle(const Offset(166, 84), 5, fill(Colors.white, 0.9));
      for (var i = 0; i < 3; i++) {
        final phase = ((t - i * 0.18) % 1.2) / 1.2;
        final o = 0.25 + 0.75 * (0.5 - 0.5 * math.cos(2 * math.pi * phase));
        canvas.drawCircle(Offset(176 + i * 10.0, 58), 3.2, fill(const Color(0xFF475569), o));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.t != t || old.mood != mood || old.mouth != mouth || old.a != a;
}
