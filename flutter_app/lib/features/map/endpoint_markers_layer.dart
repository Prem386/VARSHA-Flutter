import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/app_colors.dart';
import '../../models/route.dart';

/// Layer rendering Origin 'A' and Destination 'B' map pin markers.
class EndpointMarkersLayer extends StatelessWidget {
  final SelectedLocation? origin;
  final SelectedLocation? destination;

  const EndpointMarkersLayer({
    super.key,
    required this.origin,
    required this.destination,
  });

  Widget _buildPin({
    required String letter,
    required Color color,
    required Color darkColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: darkColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePointerPainter(color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (origin != null) {
      markers.add(
        Marker(
          point: origin!.coordinates,
          width: 36,
          height: 42,
          alignment: Alignment.topCenter,
          child: _buildPin(
            letter: 'A',
            color: AppColors.originGreen,
            darkColor: Colors.white,
          ),
        ),
      );
    }

    if (destination != null) {
      markers.add(
        Marker(
          point: destination!.coordinates,
          width: 36,
          height: 42,
          alignment: Alignment.topCenter,
          child: _buildPin(
            letter: 'B',
            color: AppColors.destinationPurple,
            darkColor: Colors.white,
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }
}

class _TrianglePointerPainter extends CustomPainter {
  final Color color;

  _TrianglePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
