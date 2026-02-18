import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IslamicLogo extends StatelessWidget {
  final double size;
  final bool darkTheme;

  const IslamicLogo({
    super.key,
    this.size = 200,
    this.darkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine which logo to use based on the theme
    // Concept 1 is the high-luxury emerald and gold version
    // Concept 2 is a darker navy and gold variant
    final String assetPath = darkTheme 
        ? 'assets/logo/generated/logo_concept_2_monoline_navy.svg'
        : 'assets/logo/generated/logo_concept_1_luxury_v2.svg';

    return Center(
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        placeholderBuilder: (BuildContext context) => const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      ),
    );
  }
}
