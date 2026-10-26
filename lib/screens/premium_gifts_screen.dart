import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PremiumGiftsScreen extends StatefulWidget {
  const PremiumGiftsScreen({super.key});
  @override
  State<PremiumGiftsScreen> createState() => _PremiumGiftsScreenState();
}

class _PremiumGiftsScreenState extends State<PremiumGiftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().syncPremiumFromServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>(), t = state.t;
    final gifts = state.premiumGifts;
    String date(DateTime? value) {
      if (value == null) return t.giftNotScheduled;
      final local = value.toLocal();
      final l10n = MaterialLocalizations.of(context);
      return '${l10n.formatMediumDate(local)} · ${l10n.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
    }

    return Directionality(
      textDirection: state.isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(t.premiumGifts)),
        body: RefreshIndicator(
          onRefresh: state.syncPremiumFromServer,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(t.giftPolicy, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              if (gifts.isEmpty) Text(t.giftEmpty),
              for (final g in gifts)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                g.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(g.reason),
                        const SizedBox(height: 12),
                        Text(t.giftDays(g.days, g.remainingDays.ceil())),
                        Text(
                          g.revoked
                              ? t.giftRevoked
                              : g.active
                              ? t.giftActive
                              : g.remainingDays <= 0
                              ? t.giftExpired
                              : t.giftBanked,
                        ),
                        const SizedBox(height: 8),
                        Text('${t.giftStarts}: ${date(g.startsAt)}'),
                        Text('${t.giftExpires}: ${date(g.expiresAt)}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                t.giftDatesMayChange,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
