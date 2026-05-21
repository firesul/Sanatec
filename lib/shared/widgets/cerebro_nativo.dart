import 'dart:math' as math;
import 'package:flutter/material.dart';

class CerebroNativo extends StatefulWidget {
  const CerebroNativo({
    super.key,
    required this.moodValue,
    this.size = 140.0,
  });

  final double moodValue;
  final double size;

  @override
  State<CerebroNativo> createState() => _CerebroNativoState();
}

class _CerebroNativoState extends State<CerebroNativo> with TickerProviderStateMixin {
  // Controlador para el "respirar" constante del cerebro (latido sutil)
  late final AnimationController _breathController;
  
  // Controlador para la lluvia y relámpagos del estado Agotado
  late final AnimationController _stormController;
  
  // Controlador para el flotar y brillar de la aureola del estado Feliz
  late final AnimationController _haloController;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _stormController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _stormController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determinar la categoría según el valor del mood (1-10)
    // 1-4: Agotado, 5-6: Neutro, 7-10: Feliz
    final double val = widget.moodValue;
    final bool isAgotado = val <= 4.0;
    final bool isNeutro = val > 4.0 && val <= 6.0;
    final bool isFeliz = val > 6.0;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _stormController,
        _haloController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _BrainPainter(
              moodValue: val,
              isAgotado: isAgotado,
              isNeutro: isNeutro,
              isFeliz: isFeliz,
              breathVal: _breathController.value,
              stormVal: _stormController.value,
              haloVal: _haloController.value,
            ),
          ),
        );
      },
    );
  }
}

class _BrainPainter extends CustomPainter {
  _BrainPainter({
    required this.moodValue,
    required this.isAgotado,
    required this.isNeutro,
    required this.isFeliz,
    required this.breathVal,
    required this.stormVal,
    required this.haloVal,
  });

  final double moodValue;
  final bool isAgotado;
  final bool isNeutro;
  final bool isFeliz;
  final double breathVal;
  final double stormVal;
  final double haloVal;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Configuración de colores dinámicos del cerebro según el ánimo
    Color brainColor;
    Color borderBrainColor;
    Color gyriColor;

    if (isAgotado) {
      // Tono grisáceo azulado (agotamiento emocional)
      brainColor = const Color(0xFF94A3B8);
      borderBrainColor = const Color(0xFF64748B);
      gyriColor = const Color(0xFF475569);
    } else if (isNeutro) {
      // Tono durazno clásico de SanaTec (neutral)
      brainColor = const Color(0xFFF7C3AD);
      borderBrainColor = const Color(0xFFEBA282);
      gyriColor = const Color(0xFFD67F5D);
    } else {
      // Tono durazno brillante / coral (felicidad)
      brainColor = const Color(0xFFFDC0A4);
      borderBrainColor = const Color(0xFFFF8E73);
      gyriColor = const Color(0xFFE0523C);
    }

    // 2. Efecto de Brillo Angelical de Fondo (Aura) para el estado Feliz
    if (isFeliz) {
      final double glowRadius = size.width * 0.45 + (10.0 * haloVal);
      final Paint glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF2CC).withOpacity(0.5 * (1.0 - (haloVal * 0.2))),
            const Color(0xFFFFD966).withOpacity(0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.48),
          radius: glowRadius,
        ));
      
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.48), glowRadius, glowPaint);
    }

    // 3. Efectos climáticos del estado Agotado (Lluvia y Trueno de fondo)
    if (isAgotado) {
      // Dibujar gotitas de lluvia cayendo detrás del cerebro
      final Paint rainPaint = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.0;

      // Gotas distribuidas con desfases
      _drawRaindrop(canvas, size, Offset(size.width * 0.3, size.height * 0.28), stormVal, rainPaint);
      _drawRaindrop(canvas, size, Offset(size.width * 0.42, size.height * 0.28), (stormVal + 0.3) % 1.0, rainPaint);
      _drawRaindrop(canvas, size, Offset(size.width * 0.58, size.height * 0.28), (stormVal + 0.7) % 1.0, rainPaint);
      _drawRaindrop(canvas, size, Offset(size.width * 0.7, size.height * 0.28), (stormVal + 0.5) % 1.0, rainPaint);

      // Relámpago ocasional (cuando la animación stormVal está en su pico)
      if (stormVal > 0.85 && stormVal < 0.95) {
        final Paint flashPaint = Paint()
          ..color = const Color(0xFFFEF08A).withOpacity(0.9)
          ..style = PaintingStyle.fill;
        
        final Path lightningPath = Path();
        lightningPath.moveTo(size.width * 0.50, size.height * 0.16);
        lightningPath.lineTo(size.width * 0.46, size.height * 0.32);
        lightningPath.lineTo(size.width * 0.54, size.height * 0.30);
        lightningPath.lineTo(size.width * 0.48, size.height * 0.45);
        lightningPath.lineTo(size.width * 0.52, size.height * 0.34);
        lightningPath.lineTo(size.width * 0.44, size.height * 0.36);
        lightningPath.close();

        canvas.drawPath(lightningPath, flashPaint);
        
        // Destello de pantalla completa sutil
        final Paint screenFlash = Paint()
          ..color = const Color(0xFFFFFBEB).withOpacity(0.15);
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), screenFlash);
      }
    }

    // 4. Dibujar la Aureola Angelical (Agotado no, Feliz sí)
    if (isFeliz) {
      final double floatY = 8.0 * haloVal;
      final double haloCenterY = size.height * 0.16 - floatY;

      // Elipse del halo
      final Rect haloRect = Rect.fromCenter(
        center: Offset(size.width * 0.5, haloCenterY),
        width: size.width * 0.52,
        height: size.height * 0.10,
      );

      final Paint haloPaint = Paint()
        ..color = const Color(0xFFF59E0B) // Oro
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      // Sombra del halo (glow)
      final Paint haloGlow = Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawOval(haloRect, haloGlow);
      canvas.drawOval(haloRect, haloPaint);
    }

    // 5. Dibujar el CEREBRO (Con animación de respiración sutil)
    final double scale = 1.0 + (0.04 * breathVal);
    canvas.save();
    // Centrar la escala en el medio del cerebro
    canvas.translate(size.width * 0.5, size.height * 0.56);
    canvas.scale(scale);
    canvas.translate(-size.width * 0.5, -size.height * 0.56);

    // Pinturas del cerebro
    final Paint fillPaint = Paint()
      ..color = brainColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = borderBrainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final Paint gyriPaint = Paint()
      ..color = gyriColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // --- Hemisferio Izquierdo ---
    final Path pathLeft = Path();
    pathLeft.moveTo(size.width * 0.50, size.height * 0.32);
    // Lóbulo frontal superior
    pathLeft.cubicTo(
      size.width * 0.38, size.height * 0.28,
      size.width * 0.22, size.height * 0.36,
      size.width * 0.20, size.height * 0.48,
    );
    // Lóbulo temporal inferior
    pathLeft.cubicTo(
      size.width * 0.18, size.height * 0.58,
      size.width * 0.24, size.height * 0.72,
      size.width * 0.36, size.height * 0.76,
    );
    // Lóbulo occipital a unión
    pathLeft.cubicTo(
      size.width * 0.42, size.height * 0.78,
      size.width * 0.48, size.height * 0.76,
      size.width * 0.50, size.height * 0.72,
    );
    pathLeft.close();

    // --- Hemisferio Derecho ---
    final Path pathRight = Path();
    pathRight.moveTo(size.width * 0.50, size.height * 0.32);
    // Lóbulo frontal superior
    pathRight.cubicTo(
      size.width * 0.62, size.height * 0.28,
      size.width * 0.78, size.height * 0.36,
      size.width * 0.80, size.height * 0.48,
    );
    // Lóbulo temporal inferior
    pathRight.cubicTo(
      size.width * 0.82, size.height * 0.58,
      size.width * 0.76, size.height * 0.72,
      size.width * 0.64, size.height * 0.76,
    );
    // Lóbulo occipital a unión
    pathRight.cubicTo(
      size.width * 0.58, size.height * 0.78,
      size.width * 0.52, size.height * 0.76,
      size.width * 0.50, size.height * 0.72,
    );
    pathRight.close();

    // Dibujar sombras sutiles interiores para efecto 3D
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    // Dibujar relleno
    canvas.drawPath(pathLeft, fillPaint);
    canvas.drawPath(pathRight, fillPaint);

    // Dibujar sombra del hemisferio izquierdo para contraste 3D
    canvas.drawPath(pathLeft, shadowPaint);

    // Dibujar contornos
    canvas.drawPath(pathLeft, borderPaint);
    canvas.drawPath(pathRight, borderPaint);

    // --- Fibras y circunvoluciones (Gyri / Curvas internas del cerebro) ---
    // Hemisferio Izquierdo
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.48, size.height * 0.38),
      Offset(size.width * 0.38, size.height * 0.42),
      Offset(size.width * 0.35, size.height * 0.50),
      Offset(size.width * 0.46, size.height * 0.52),
    ]), gyriPaint);
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.28, size.height * 0.44),
      Offset(size.width * 0.24, size.height * 0.52),
      Offset(size.width * 0.30, size.height * 0.60),
    ]), gyriPaint);
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.34, size.height * 0.66),
      Offset(size.width * 0.44, size.height * 0.68),
      Offset(size.width * 0.48, size.height * 0.62),
    ]), gyriPaint);

    // Hemisferio Derecho
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.52, size.height * 0.38),
      Offset(size.width * 0.62, size.height * 0.42),
      Offset(size.width * 0.65, size.height * 0.50),
      Offset(size.width * 0.54, size.height * 0.52),
    ]), gyriPaint);
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.72, size.height * 0.44),
      Offset(size.width * 0.76, size.height * 0.52),
      Offset(size.width * 0.70, size.height * 0.60),
    ]), gyriPaint);
    canvas.drawPath(_buildGyrus(size, [
      Offset(size.width * 0.66, size.height * 0.66),
      Offset(size.width * 0.56, size.height * 0.68),
      Offset(size.width * 0.52, size.height * 0.62),
    ]), gyriPaint);

    canvas.restore(); // Restaurar escala

    // 6. Dibujar la Nube Tormentosa del estado Agotado (Delante del cerebro)
    if (isAgotado) {
      final double cloudFloat = 4.0 * math.sin(stormVal * 2 * math.pi);
      final double cloudY = size.height * 0.16 + cloudFloat;

      final Path cloudPath = Path();
      // Puntos para formar una nube esponjosa
      cloudPath.moveTo(size.width * 0.32, cloudY);
      cloudPath.cubicTo(
        size.width * 0.22, cloudY - size.height * 0.08,
        size.width * 0.34, cloudY - size.height * 0.16,
        size.width * 0.45, cloudY - size.height * 0.10,
      );
      cloudPath.cubicTo(
        size.width * 0.50, cloudY - size.height * 0.20,
        size.width * 0.62, cloudY - size.height * 0.14,
        size.width * 0.66, cloudY - size.height * 0.08,
      );
      cloudPath.cubicTo(
        size.width * 0.78, cloudY - size.height * 0.06,
        size.width * 0.72, cloudY + size.height * 0.06,
        size.width * 0.60, cloudY + size.height * 0.04,
      );
      cloudPath.lineTo(size.width * 0.36, cloudY + size.height * 0.04);
      cloudPath.cubicTo(
        size.width * 0.24, cloudY + size.height * 0.04,
        size.width * 0.24, cloudY - size.height * 0.04,
        size.width * 0.32, cloudY,
      );
      cloudPath.close();

      // Gradiente de nube gris de tormenta
      final Paint cloudPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF64748B), // Slate 500
            Color(0xFF334155), // Slate 700
          ],
        ).createShader(Rect.fromLTWH(size.width * 0.2, cloudY - 20, size.width * 0.6, 50))
        ..style = PaintingStyle.fill;

      final Paint borderCloud = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Dibujar nube
      canvas.drawPath(cloudPath, cloudPaint);
      canvas.drawPath(cloudPath, borderCloud);
    }
  }

  // Helper para dibujar gotitas individuales
  void _drawRaindrop(Canvas canvas, Size size, Offset start, double animValue, Paint paint) {
    final double dropY = start.dy + (size.height * 0.40 * animValue);
    // Desvanecer gota al final del recorrido
    paint.color = paint.color.withOpacity(0.7 * (1.0 - animValue));

    canvas.drawLine(
      Offset(start.dx, dropY),
      Offset(start.dx - 2, dropY + 8),
      paint,
    );
  }

  // Convierte una lista de puntos en una curva suave para las circunvoluciones del cerebro
  Path _buildGyrus(Size size, List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final xc = (p0.dx + p1.dx) / 2;
      final yc = (p0.dy + p1.dy) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) {
    return oldDelegate.moodValue != moodValue ||
        oldDelegate.breathVal != breathVal ||
        oldDelegate.stormVal != stormVal ||
        oldDelegate.haloVal != haloVal;
  }
}
