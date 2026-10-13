import 'package:flutter/material.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';

Future<bool> ensureAiConsent(BuildContext context, AppState state) async {
  final owner = state.sessionAccountId;
  if (!state.isAuthenticated) return false;
  if (!state.hasPremiumFeatures) {
    await showPremiumPaywall(context);
    return false;
  }
  final consent = await state.getAiConsent();
  if (!context.mounted || state.sessionAccountId != owner) return false;
  if (consent == true) return true;
  if (consent == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AiStrings.get(state.lang, 'unavailable'))),
    );
    return false;
  }
  final allowed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AiStrings.get(state.lang, 'title')),
      content: SingleChildScrollView(
        child: Text(
          '${AiStrings.get(state.lang, 'notice')}\n\n${AiStrings.get(state.lang, 'bodyNotice')}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AiStrings.get(state.lang, 'decline')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(AiStrings.get(state.lang, 'allow')),
        ),
      ],
    ),
  );
  if (allowed != true || state.sessionAccountId != owner) return false;
  final saved = await state.setAiConsent(true);
  if (!saved && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AiStrings.get(state.lang, 'unavailable'))),
    );
  }
  return saved && context.mounted;
}

Future<bool> confirmAiEstimate(
  BuildContext context,
  AppState state, {
  String details = '',
}) async {
  final owner = state.sessionAccountId;
  final accepted =
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AiStrings.get(state.lang, 'confirm')),
          content: SingleChildScrollView(
            child: Text('${AiStrings.get(state.lang, 'estimate')}\n\n$details'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(state.t.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AiStrings.get(state.lang, 'review')),
            ),
          ],
        ),
      ) ??
      false;
  return accepted && context.mounted && owner == state.sessionAccountId;
}

class AiPrivacySettings extends StatelessWidget {
  const AiPrivacySettings({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.privacy_tip_outlined),
    title: Text(AiStrings.get(state.lang, 'title')),
    subtitle: Text(AiStrings.get(state.lang, 'revoke')),
    onTap: () async {
      final ok = await state.setAiConsent(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AiStrings.get(state.lang, ok ? 'revoked' : 'unavailable'),
            ),
          ),
        );
      }
    },
  );
}
