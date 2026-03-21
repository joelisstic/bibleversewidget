import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/promise_box/domain/entities/bible_verse.dart';
import '3_d_animation.dart';

class NothingVerseCard extends StatelessWidget {
  final BibleVerse verse;
  final VoidCallback onRefresh;

  const NothingVerseCard({super.key, required this.verse, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
          HapticFeedback.mediumImpact();
          onRefresh();
        }
      },
      child: ThreeDSpinWrapper(
        toggleKey: verse.sentence,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotGridPainter(color: Colors.white.withValues(alpha: 0.03)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  // AnimatedSwitcher removed to allow ThreeDSpinWrapper to handle the visual change
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      Text(
                        verse.sentence,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
// ... _buildHeader and _buildFooter stay the same


  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFF0000),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'LOVE',
          style: GoogleFonts.ibmPlexMono(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        _buildIconButton(
          context: context,
          icon: Icons.copy_all_rounded,
          onTap: () {
            Clipboard.setData(ClipboardData(
              text: '"${verse.sentence}" - ${verse.reference}',
            ));
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Copied to clipboard', style: GoogleFonts.ibmPlexMono()),
                backgroundColor: const Color(0xFF333333),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SOURCE DATA',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                verse.reference,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            onRefresh();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({required BuildContext context, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 22),
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 12.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}