import 'package:flutter/material.dart';

class DotMatrixLoading extends StatefulWidget {
  const DotMatrixLoading({super.key});

  @override
  State<DotMatrixLoading> createState() => _DotMatrixLoadingState();
}

class _DotMatrixLoadingState extends State<DotMatrixLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final opacity = ((_controller.value * 3 - index) % 3).clamp(0.1, 1.0);
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  shape: BoxShape.rectangle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
