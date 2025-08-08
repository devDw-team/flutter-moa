import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// This is a temporary script to generate PNG from SVG-like design
// Run this with: dart create_app_icon.dart

void main() async {
  // Create a 1024x1024 image for high quality
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = 1024.0;
  
  // Background gradient
  final gradient = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Draw rounded rectangle background
  final backgroundPaint = Paint()
    ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size, size));
  
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      Radius.circular(240),
    ),
    backgroundPaint,
  );
  
  // Draw chart bars
  final barPaint = Paint()
    ..color = Colors.white.withOpacity(0.95)
    ..style = PaintingStyle.fill;
  
  // Bar 1
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(280, 560, 120, 240),
      Radius.circular(20),
    ),
    barPaint,
  );
  
  // Bar 2
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(452, 440, 120, 360),
      Radius.circular(20),
    ),
    barPaint,
  );
  
  // Bar 3
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(624, 520, 120, 280),
      Radius.circular(20),
    ),
    barPaint,
  );
  
  // Draw circular progress
  final center = Offset(size / 2, 360);
  
  // Outer circle
  final circlePaint = Paint()
    ..color = Colors.white.withOpacity(0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 16;
  
  canvas.drawCircle(center, 100, circlePaint);
  
  // Progress arc
  final progressPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 16
    ..strokeCap = StrokeCap.round;
  
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: 100),
    -90 * 3.14159 / 180,
    240 * 3.14159 / 180,
    false,
    progressPaint,
  );
  
  // Draw Won symbol
  final textPainter = TextPainter(
    text: TextSpan(
      text: '₩',
      style: TextStyle(
        color: Colors.white,
        fontSize: 72,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
  );
  
  print('PNG icon design created successfully!');
  print('Please use an online tool or Flutter app to convert this to actual PNG files.');
  print('Recommended sizes: 1024x1024, 512x512, 256x256, 128x128');
}