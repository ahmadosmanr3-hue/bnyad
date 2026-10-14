import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'demo_backend.dart';

/// Outside the original navigator, so the demo label survives every app route.
class DemoShell extends StatefulWidget {
  final DemoBackend backend;
  final Widget child;
  const DemoShell({super.key, required this.backend, required this.child});
  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int _navigationEpoch = 0;
  bool _busy = false;
  bool _phoneLayout = false;
  String? _error;

  Future<void> _action(Future<void> Function(AppState) action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(context.read<AppState>());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Demo action failed. Reload or reset sample data.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _navigationEpoch++;
        });
      }
    }
  }

  Future<void> _enter(AppState state, {bool onboarded = true}) async {
    widget.backend.profile['onboarded'] = onboarded;
    // Simulated consent, not permission to send anything to Google.
    widget.backend.data['consent'] = true;
    await widget.backend.persist();
    final error = await state.loginWithPassword('+9647700000010', 'demo-only');
    if (error != null) throw StateError(error);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'BNYAD — DEMO MODE',
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: const Color(0xFFFFE8A3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'DEMO MODE • Fictional data • Simulated AI, NOT Gemini • No backend/purchases • External links disabled',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Text(
                        'Use fictional details and sample images only. Nothing is uploaded. Login phone: 7700000010; registration: 7700000011; password: demo123; OTP: 123456.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _phoneLayout = !_phoneLayout),
                            child: Text(
                              _phoneLayout ? 'Full width' : 'Phone layout',
                            ),
                          ),
                          FilledButton(
                            onPressed: _busy ? null : () => _action(_enter),
                            child: const Text('Enter Demo'),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action((s) => s.logout()),
                            child: const Text('Login / Register'),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action(
                                    (s) => _enter(s, onboarded: false),
                                  ),
                            child: const Text('Onboarding'),
                          ),
                          Builder(
                            builder: (ctx) => TextButton(
                              onPressed: () => showPremiumPaywall(ctx),
                              child: const Text('Premium screen'),
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action((s) async {
                                    widget.backend.data['premium'] =
                                        widget.backend.data['premium'] != true;
                                    await widget.backend.persist();
                                    await s.syncPremiumFromServer();
                                  }),
                            child: Text(
                              'Mock premium: ${state.isPremium ? 'ON' : 'OFF'}',
                            ),
                          ),
                          for (final lang in ['en', 'ar', 'ku'])
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => state.setLang(lang),
                              child: Text(lang.toUpperCase()),
                            ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _action((s) async {
                                    await s.logout();
                                    // getKeys() is restricted to the bnyad_demo. namespace.
                                    for (final key
                                        in widget.backend.preferences
                                            .getKeys()) {
                                      await widget.backend.preferences.remove(
                                        key,
                                      );
                                    }
                                    await widget.backend.reset();
                                    await widget.backend.seedLocalHistory();
                                    await s.initializeSession();
                                    await _enter(s);
                                  }),
                            child: const Text('Reset sample data'),
                          ),
                          if (_busy)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: _phoneLayout ? 390 : double.infinity,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_navigationEpoch),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
