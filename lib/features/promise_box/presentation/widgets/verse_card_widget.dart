import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/bible_verse.dart';

class VerseCardWidget extends StatelessWidget {
  final BibleVerse verse;
  final VoidCallback onRefresh;

  const VerseCardWidget({
    super.key,
    required this.verse,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.15),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote, color: Colors.amber.shade800, size: 50),
          const SizedBox(height: 10),
          Text(
            verse.sentence,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              verse.reference,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.amber.shade900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.copy_all_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: '"${verse.sentence}" - ${verse.reference}',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verse copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 25),
              _buildActionButton(
                context: context,
                icon: Icons.refresh_rounded,
                onPressed: onRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade50,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Colors.brown.shade800,
        iconSize: 28,
      ),
    );
  }
}
