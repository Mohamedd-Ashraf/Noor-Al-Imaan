import "package:flutter/material.dart";

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
    // Now using the transparent versions of your original files!
    // No more white background boxes.
    final String assetPath = darkTheme
        ? "assets/logo/files/transparent/Splash_dark_transparent.png"
        : "assets/logo/files/transparent/splash_light_transparent.png";

    return Center(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
