/// User-facing app branding (display name + logo assets).
class AppBranding {
  AppBranding._();

  static const name = 'BNYAD';
  /// Transparent PNG — apple mark, natural aspect ratio (`bnyadnewest.jpeg`).
  static const logoAsset = 'assets/images/bnyad_logo.png';
  /// Square transparent icon for app bar / compact UI.
  static const iconAsset = 'assets/images/bnyad_icon.png';

  /// Horizontal align within logo box (-1 left … 1 right). Shifts bnyadnewest artwork left.
  static const double logoAlignX = -0.28;
}
