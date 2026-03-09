import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PromiseBoxWidget extends StatelessWidget {
  final VoidCallback onTap;

  const PromiseBoxWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Box Body
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.amber.shade800, width: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 50),
                const SizedBox(height: 10),
                Text(
                  'OPEN ME',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Decorative Lid
          Positioned(
            top: 0,
            child: Container(
              width: 200,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.brown.shade600,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Colors.amber.shade800, width: 3),
                ),
              ),
            ),
          ),
          // Latch
          Positioned(
            top: 35,
            child: Container(
              width: 40,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
