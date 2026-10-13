import 'package:flutter/material.dart';
import 'package:nutrify/constants/app_branding.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Renders the BNYAD logo from [AppBranding.logoAsset] / [AppBranding.iconAsset].
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  final AppLogoVariant variant;

  const AppLogo({
    super.key,
    this.size = 48,
    this.fit = BoxFit.contain,
    this.variant = AppLogoVariant.full,
  });

  const AppLogo.icon({
    super.key,
    required this.size,
    this.fit = BoxFit.contain,
  }) : variant = AppLogoVariant.icon;

  @override
  Widget build(BuildContext context) {
    final asset = variant == AppLogoVariant.icon
        ? AppBranding.iconAsset
        : AppBranding.logoAsset;
    final dimension = size * 0.88;

    return SizedBox(
      width: size,
      height: size,
      child: Align(
        alignment: Alignment(AppBranding.logoAlignX, 0),
        child: Image.asset(
          asset,
          width: dimension,
          height: dimension,
          fit: fit,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _fallback(size),
        ),
      ),
    );
  }

  Widget _fallback(double s) => Icon(
        Icons.eco_rounded,
        size: s * 0.85,
        color: AppTheme.brandTeal,
      );
}

enum AppLogoVariant { full, icon }

/// Gradient wordmark matching the logo colors.
class AppBrandTitle extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const AppBrandTitle({
    super.key,
    this.fontSize = 32,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = -1,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: AppTheme.brandWordmarkGradient,
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        AppBranding.name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// Centered logo + wordmark for login / splash (welcome).
class AppBrandHeader extends StatelessWidget {
  final double logoSize;
  final double titleSize;
  final double spacing;

  const AppBrandHeader({
    super.key,
    this.logoSize = 100,
    this.titleSize = 32,
    this.spacing = 18,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppLogo(size: logoSize),
          SizedBox(height: spacing),
          AppBrandTitle(fontSize: titleSize),
        ],
      ),
    );
  }
}
