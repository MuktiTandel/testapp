import 'dart:math';

import 'package:flutter/material.dart';

class DrawCircle extends CustomPainter {

  final Map<String, double> center;
  final double radius;
  final Color color;
  final AnimationController controller;

  DrawCircle({
    required this.center,
    required this.radius,
    required this.color,
    required this.controller
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint brush = new Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill
        ..strokeWidth = 30;

    var offset = Offset(size.width / 2, size.height / 2);
    var smileCenter = Offset(offset.dx, offset.dy + 30);

    final rect = Rect.fromLTRB(50, 100, 250, 200);

    canvas.drawCircle(Offset(center['x']!, center['y']!), radius, brush);
    drawOval(canvas, size);
    canvas.drawArc(Rect.fromCenter(center: smileCenter, width: 90, height: 60), 0, pi, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 5);
  }

  void drawOval(Canvas canvas, Size size){

    var center = Offset(size.width / 2, size.height / 2);

    var eyeAnimation = Tween<double>(begin: 0, end: 50).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut));

    Paint brush = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 5;

    void draweye(double xOffset){
      canvas.drawOval(Rect.fromCenter(center: Offset(center.dx - xOffset, center.dy - 30), width: 25, height: 50), brush);
      canvas.drawCircle(
          Offset(center.dx - xOffset , center.dy -30), 6, Paint()..color = Colors.white);
    }

    void drawEyeLid(double xOffset) {
      canvas.drawOval(Rect.fromCircle( center: Offset(center.dx + xOffset -10, center.dy -  eyeAnimation.value + 23), radius: 28),
          Paint()
            ..color = Colors.yellow
            ..style = PaintingStyle.fill
            ..strokeWidth = 5);
    }

    draweye(50);
    draweye(-50);
    drawEyeLid(60);
    drawEyeLid(-40);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}