/// Promotional credit is server-issued and separate from store purchases.
class PremiumGift {
  final String id, campaignId, name, reason;
  final int days;
  final double remainingDays;
  final DateTime? startsAt, expiresAt;
  final bool active, deferred, revoked;
  const PremiumGift({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.reason,
    required this.days,
    required this.remainingDays,
    this.startsAt,
    this.expiresAt,
    required this.active,
    required this.deferred,
    required this.revoked,
  });
  static List<PremiumGift> parse(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .where(
          (r) =>
              r['id'] is String &&
              r['campaignId'] is String &&
              r['days'] is int &&
              r['days'] > 0 &&
              r['remainingDays'] is num &&
              (r['remainingDays'] as num).isFinite &&
              r['remainingDays'] >= 0,
        )
        .map(
          (r) => PremiumGift(
            id: r['id'],
            campaignId: r['campaignId'],
            name: r['name']?.toString() ?? '',
            reason: r['reason']?.toString() ?? '',
            days: r['days'],
            remainingDays: (r['remainingDays'] as num).toDouble(),
            startsAt: DateTime.tryParse(r['startsAt']?.toString() ?? ''),
            expiresAt: DateTime.tryParse(r['expiresAt']?.toString() ?? ''),
            active: r['active'] == true,
            deferred: r['deferred'] == true,
            revoked: r['revokedAt'] != null,
          ),
        )
        .toList();
  }
}
