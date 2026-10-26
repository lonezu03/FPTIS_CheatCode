import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

/// Catalog media can be an HTTPS URL, a relative API-media path or a legacy
/// embedded raster. Never attach API credentials to third-party image requests.
class CatalogImage extends StatelessWidget {
  const CatalogImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });
  final String url;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => SizedBox(
      width: width,
      height: height,
      child: const Center(child: Icon(Icons.broken_image_outlined)),
    );
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'data') {
        if (url.length > 2000000 || !uri.data!.mimeType.startsWith('image/')) {
          return fallback();
        }
        return Image.memory(
          uri.data!.contentAsBytes(),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => fallback(),
        );
      }
      final resolved = uri.hasScheme
          ? uri
          : Uri.parse(AppConfig.apiBaseUrl).resolveUri(uri);
      if (!const ['http', 'https'].contains(resolved.scheme)) return fallback();
      return Image.network(
        resolved.toString(),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => fallback(),
      );
    } catch (_) {
      return fallback();
    }
  }
}
