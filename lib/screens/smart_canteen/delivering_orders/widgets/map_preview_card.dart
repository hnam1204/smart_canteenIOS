import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../order_model.dart';
import 'delivery_status_banner.dart';

class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({
    super.key,
    required this.order,
    required this.onMapTap,
    this.compact = false,
  });

  final OrderModel order;
  final VoidCallback onMapTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 106 : 122,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE1EFE5)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _StreetPattern()),
          Positioned(
            left: 14,
            top: compact ? 31 : 38,
            child: const _Marker(
              icon: Icons.delivery_dining_rounded,
              color: deliveryGreen,
            ),
          ),
          Positioned(
            right: 62,
            top: compact ? 15 : 22,
            child: const _Marker(
              icon: Icons.location_on_rounded,
              color: AppColors.primary,
            ),
          ),
          Positioned(
            left: 50,
            right: 96,
            top: compact ? 46 : 54,
            child: CustomPaint(
              painter: _DashedPainter(),
              size: const Size(double.infinity, 2),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: TextButton(
              key: ValueKey('map-${order.id}'),
              onPressed: onMapTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                padding: const EdgeInsets.symmetric(horizontal: 9),
              ),
              child: const Text(
                'Xem bản đồ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppColors.cardShadow,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StreetPattern extends StatelessWidget {
  const _StreetPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RoadPainter());
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE6EEE9)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.25)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.15,
        size.width * 0.35,
        size.height * 0.75,
        size.width,
        size.height * 0.54,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * 0.56, 0),
      Offset(size.width * 0.48, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = deliveryGreen
      ..strokeWidth = 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x + 5, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
