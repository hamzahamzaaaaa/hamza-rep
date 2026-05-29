import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class DecorativeRecentlyAdded extends StatelessWidget {
  const DecorativeRecentlyAdded({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 90, maxHeight: 42),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Sharper Glassmorphism Background
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.3) 
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.gold.withValues(alpha: 0.6) : AppColors.goldDark.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 2. Thicker Custom Painted Decorative Frame
          CustomPaint(
            painter: GoldenFramePainter(),
            size: const Size(90, 42),
          ),

          // 3. High-Contrast Glowing Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'مُضافة حديثاً',
                    style: GoogleFonts.amiri(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      shadows: isDark ? [
                        Shadow(
                          color: Colors.amber.withValues(alpha: 0.9),
                          blurRadius: 12,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.stars, color: Colors.amber, size: 12),
                ],
              ),
            ),
          ),

          // 4. Vibrant 'New' Badge
          Positioned(
            top: -10,
            left: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Text(
                'جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoldenFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.9) // More opaque
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8; // Thicker lines

    final path = Path();
    double cornerSize = 10.0;

    // Drawing decorative corners
    // Top-Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);

    // Top-Right
    path.moveTo(size.width - cornerSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerSize);

    // Bottom-Right
    path.moveTo(size.width, size.height - cornerSize);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width - cornerSize, size.height);

    // Bottom-Left
    path.moveTo(cornerSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height - cornerSize);

    canvas.drawPath(path, paint);

    // Add some tiny dots or details
    canvas.drawCircle(const Offset(2, 2), 1, paint);
    canvas.drawCircle(Offset(size.width - 2, 2), 1, paint);
    canvas.drawCircle(Offset(size.width - 2, size.height - 2), 1, paint);
    canvas.drawCircle(Offset(2, size.height - 2), 1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
