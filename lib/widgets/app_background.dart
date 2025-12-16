import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2F),
                  const Color(0xFF23233D),
                  const Color(0xFF2E2E4A),
                ]
              : [
                  const Color(0xFFC4C4DF), // اللون اللي انت اخترته
                  const Color(0xFFD1D1E7),
                  const Color(0xFFE2E2F2),
                ],
        ),
      ),

      child: Stack(
        children: [
          /// DNA BACKGROUND — واضحة في Light Mode
          Positioned(
            right: -30,
            bottom: -20,
            child: Image.asset(
              'assets/images/dna_bg.png',
              width: 420,
              fit: BoxFit.contain,

              /// مهم جداً:
              /// Light Mode → بدون أي color أو opacity (واضحة 100%)
              /// Dark Mode → نعطيها لون أبيض خفيف
              color: isDark ? Colors.white.withOpacity(0.18) : null,
            ),
          ),

          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
