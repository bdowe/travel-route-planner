import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an airline's logo from Duffel's `owner.logo_symbol_url` (an SVG).
/// Shows nothing (zero-size) when [url] is null/empty or fails to load, so
/// callers can place it unconditionally.
class AirlineLogo extends StatelessWidget {
  final String? url;
  final double size;
  const AirlineLogo({super.key, required this.url, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return const SizedBox.shrink();
    return SvgPicture.network(
      u,
      width: size,
      height: size,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
    );
  }
}
