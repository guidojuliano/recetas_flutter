import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.url,
    required this.fallbackSvg,
    this.fit = BoxFit.cover,
    this.fallbackAssetPath = 'assets/images/logo.PNG',
    this.fallbackBackgroundColor = const Color(0xFF673AB7),
  });

  final String url;
  final String fallbackSvg;
  final BoxFit fit;
  final String fallbackAssetPath;
  final Color fallbackBackgroundColor;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _buildFallback();
    }

    if (url.startsWith('data:image/svg+xml')) {
      final svg = _decodeDataSvg(url) ?? fallbackSvg;
      return SvgPicture.string(svg, fit: fit);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, _) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, _, __) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return ColoredBox(
      color: fallbackBackgroundColor,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.45,
          heightFactor: 0.45,
          child: Image.asset(fallbackAssetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  String? _decodeDataSvg(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) return null;
    final raw = dataUrl.substring(commaIndex + 1);
    return Uri.decodeComponent(raw);
  }
}
