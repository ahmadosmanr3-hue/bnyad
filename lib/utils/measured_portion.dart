/// User-supplied food-specific mass/volume, never a universal plate or slice.
double measuredPortionAmount({
  required double amountPerUnit,
  required double count,
}) {
  final total = amountPerUnit * count;
  if (!amountPerUnit.isFinite ||
      !count.isFinite ||
      amountPerUnit <= 0 ||
      count <= 0 ||
      !total.isFinite ||
      total > 10000) {
    throw const FormatException(
      'Enter positive measured quantities totaling at most 10000 g or mL.',
    );
  }
  return total;
}
