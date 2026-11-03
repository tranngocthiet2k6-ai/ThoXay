import 'package:flutter/material.dart';

/// Display identity only; package names, session keys and API URLs stay stable.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 40, this.onDark = false});
  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(onDark ? 4 : 0),
    decoration: BoxDecoration(
      color: onDark ? Colors.white : null,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Image.asset(
      'assets/branding/logo_xay_transparent.png',
      height: height,
      width: height * 1.34,
      fit: BoxFit.contain,
      semanticLabel: 'Xây',
    ),
  );
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      BrandLogo(
        height: 32,
        onDark: Theme.of(context).brightness == Brightness.dark,
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}
