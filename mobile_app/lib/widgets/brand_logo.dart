import 'package:flutter/material.dart';

/// Shared, untinted artwork for splash, authentication and application headers.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 40});
  final double height;
  static const assetPath = 'assets/branding/app_icon.png';

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo Thợ Xây',
    image: true,
    child: SizedBox.square(
      dimension: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height * .16),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Semantics(label: '$title · Thợ Xây', child: const BrandLogo(height: 36));
}
