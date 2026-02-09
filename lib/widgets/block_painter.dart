import 'package:flutter/material.dart';

class BlockShapePainter extends CustomPainter {
  final Color color;
  final bool isHat;
  final bool isMouth;

  const BlockShapePainter({
    required this.color,
    this.isHat = false,
    this.isMouth = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int to255(double value) => value.round().clamp(0, 255);

    Color darken(Color c, [double amount = 0.12]) {
      final r = to255(c.r * 255 * (1 - amount));
      final g = to255(c.g * 255 * (1 - amount));
      final b = to255(c.b * 255 * (1 - amount));
      return Color.fromARGB(to255(c.a * 255), r, g, b);
    }

    Color lighten(Color c, [double amount = 0.08]) {
      final r = to255((c.r * 255) + ((255 - (c.r * 255)) * amount));
      final g = to255((c.g * 255) + ((255 - (c.g * 255)) * amount));
      final b = to255((c.b * 255) + ((255 - (c.b * 255)) * amount));
      return Color.fromARGB(to255(c.a * 255), r, g, b);
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [lighten(color), color, darken(color, 0.16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    final path = Path();

    const double radius = 11.0;
    const double connectorStart = 18.0;
    const double connectorWidth = 26.0;
    const double connectorDepth = 7.0;
    const double headerHeight = 34.0;
    final double mouthTop = isMouth ? headerHeight : size.height;
    final double mouthBottom = isMouth ? (size.height - 34.0) : size.height;

    if (isHat) {
      path.moveTo(0, 18);
      path.quadraticBezierTo(size.width * 0.2, -2, size.width * 0.5, 0);
      path.quadraticBezierTo(size.width * 0.85, 2, size.width, 16);
    } else {
      path.moveTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(connectorStart, 0);
      path.lineTo(connectorStart + 4, connectorDepth);
      path.lineTo(connectorStart + connectorWidth - 4, connectorDepth);
      path.lineTo(connectorStart + connectorWidth, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
    }

    if (isMouth) {
      path.lineTo(size.width, mouthTop);
      path.lineTo(20, mouthTop);
      path.lineTo(20, mouthBottom);
      path.lineTo(size.width, mouthBottom);
    }

    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    );
    path.lineTo(connectorStart + connectorWidth, size.height);
    path.lineTo(
      connectorStart + connectorWidth - 4,
      size.height + connectorDepth,
    );
    path.lineTo(connectorStart + 4, size.height + connectorDepth);
    path.lineTo(connectorStart, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    if (isMouth) {
      path.lineTo(0, mouthBottom);
      path.lineTo(0, mouthTop);
    }
    path.close();

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final borderPaint = Paint()
      ..color = darken(color, 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, highlightPaint);
    canvas.drawPath(path, borderPaint);

    if (isMouth) {
      final slotLine = Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(20, headerHeight),
        Offset(size.width - 2, headerHeight),
        slotLine,
      );
      canvas.drawLine(
        Offset(20, size.height - 34),
        Offset(size.width - 2, size.height - 34),
        slotLine,
      );
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0);
    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
