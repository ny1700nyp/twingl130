import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Spark Card: Daily quote on a Deep Purple → Mint Green gradient with a decorative quote mark.
class SparkCard extends StatelessWidget {
  const SparkCard({super.key, required this.quote, required this.author});

  final String quote;
  final String author;

  static const Color _deepPurple = Color(0xFF4C1D95);
  static const Color _mintGreen = Color(0xFF6EE7B7);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _deepPurple.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepPurple, Color(0xFF5B21B6), Color(0xFF34D399), _mintGreen],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative large quotation mark (10% opacity)
          Positioned(
            top: -8,
            right: 4,
            child: Opacity(
              opacity: 0.10,
              child: Text(
                '"',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 120,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Quote content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote,
                style: GoogleFonts.quicksand(
                  fontSize: 15,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withAlpha(250),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— $author',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
