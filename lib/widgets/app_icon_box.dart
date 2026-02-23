import 'package:flutter/material.dart';

/// Shared icon box used in settings, accounts, and other screens.
/// Renders an icon inside a rounded container with gradient or solid color;
/// icon is always white for contrast. Use for list tiles, headers, and menus.
class AppIconBox extends StatelessWidget {
  final IconData icon;
  final List<Color>? gradient;
  final Color? color;
  final double size;
  final double padding;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  const AppIconBox({
    super.key,
    required this.icon,
    this.gradient,
    this.color,
    this.size = 20,
    this.padding = 10,
    this.borderRadius = 12,
    this.boxShadow,
  }) : assert(
         gradient != null || color != null,
         'Provide either gradient or color',
       );

  @override
  Widget build(BuildContext context) {
    final colors = gradient ??
        [color!, color!];
    final decoration = BoxDecoration(
      gradient: colors.length > 1
          ? LinearGradient(colors: colors)
          : null,
      color: colors.length == 1 ? colors.first : null,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: boxShadow,
    );
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: decoration,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}
