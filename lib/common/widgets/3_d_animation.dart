import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'nothing_verse_card.dart';

class ThreeDSpinWrapper extends StatefulWidget {
  final Widget child;
  final dynamic toggleKey;

  const ThreeDSpinWrapper({super.key, required this.child, required this.toggleKey});

  @override
  State<ThreeDSpinWrapper> createState() => _ThreeDSpinWrapperState();
}

class _ThreeDSpinWrapperState extends State<ThreeDSpinWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Slightly faster but still smooth
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(ThreeDSpinWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.toggleKey != widget.toggleKey) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double rotationValue = _animation.value * 2 * math.pi;
        // The back is visible between 90 and 270 degrees
        final bool isBack = rotationValue > math.pi / 2 && rotationValue < 3 * math.pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Increased depth slightly for better 3D look
            ..rotateY(rotationValue),
          alignment: Alignment.center,
          child: isBack ? _buildBackSide() : widget.child,
        );
      },
    );
  }

  Widget _buildBackSide() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi), // Corrects the mirrored 'J'
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            // Added the dots to the back for consistency
            Positioned.fill(
              child: CustomPaint(
                painter: DotGridPainter(color: Colors.white.withValues(alpha: 0.03)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 100), // Gives it vertical bulk
                child: Image.asset("assets/images/jo.png")
                
                // Text(
                //   'J',
                //   style: GoogleFonts.ibmPlexMono(
                //     fontSize: 120,
                //     fontWeight: FontWeight.w900,
                //     color: Colors.white.withValues(alpha: 0.1),
                //   ),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep your DotGridPainter class below...