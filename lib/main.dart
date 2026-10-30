import 'screens/premium_gifts_screen.dart';
import 'dart:async';
import 'package:nutrify/l10n/framework_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/notification_service.dart';
import 'package:nutrify/services/push_service.dart';
import 'package:nutrify/services/purchases_bootstrap.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/screens/onboarding_screen.dart';
import 'package:nutrify/screens/dashboard_screen.dart';
import 'package:nutrify/screens/food_log_screen.dart';
import 'package:nutrify/screens/meal_plan_screen.dart';
import 'package:nutrify/screens/scanner_screen.dart';
import 'package:nutrify/screens/settings_screen.dart';
import 'package:nutrify/screens/notifications_screen.dart';
import 'package:nutrify/screens/splash_screen.dart';
import 'package:nutrify/widgets/app_bottom_nav.dart';
import 'package:nutrify/widgets/premium_gate.dart';
import 'package:nutrify/widgets/auth_gate.dart';
import 'package:nutrify/config/private_keys.dart' as private_keys;
import 'package:nutrify/constants/app_branding.dart';
import 'package:nutrify/widgets/app_logo.dart';

void main() async {
  await runBnyad();
}

Future<void> runBnyad({
  String apiBaseUrl = private_keys.apiBaseUrl,
  bool aiEnabled = true,
  bool optionalIntegrations = true,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService(baseUrl: apiBaseUrl, aiEnabled: aiEnabled);

  final appState = AppState(
    authService: AuthService(api: apiService),
    apiService: apiService,
  );
  runApp(
    ChangeNotifierProvider(create: (_) => appState, child: const BnyadApp()),
  );
  if (optionalIntegrations) {
    unawaited(_initializeOptionalServices(appState));
  }
}

Future<void> _initializeOptionalServices(AppState appState) async {
  if (!kIsWeb) {
    // Optional integrations must not prevent the app and saved session from
    // initializing when permissions, Firebase or store services are unavailable.
    try {
      await NotificationService.instance.init().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {}
    try {
      await PushService.instance.init().timeout(const Duration(seconds: 8));
    } catch (_) {}

    await PurchasesBootstrap.instance.ensureConfigured();
  }

  await appState.onAppResumed();
}

class BnyadApp extends StatefulWidget {
  const BnyadApp({super.key});

  @override
  State<BnyadApp> createState() => _BnyadAppState();
}

class _BnyadAppState extends State<BnyadApp> with WidgetsBindingObserver {
  bool _splashDone = false;
  final _navigatorKey = GlobalKey<NavigatorState>();
  bool _pendingNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // A restored connection can notify synchronously when refreshing. Wait
    // until the provider/widget mount is complete before triggering it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().steps.setForeground(
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
      );
    });
    _pendingNotification = PushService.instance.openedRoute != null;
    PushService.instance.onEntitlementsChanged = () {
      if (mounted) context.read<AppState>().syncPremiumFromServer();
    };
    PushService.instance.onNotificationOpened = () {
      _pendingNotification = true;
      _openPendingNotification();
    };
  }

  void _openPendingNotification() {
    if (!mounted || !_pendingNotification || !_splashDone) return;
    final state = context.read<AppState>();
    if (state.authLoading ||
        !state.isAuthenticated ||
        !state.onboardingComplete) {
      return;
    }
    _pendingNotification = false;
    final gifts = PushService.instance.openedRoute == 'premium-gifts';
    PushService.instance.openedRoute = null;
    state.syncPremiumFromServer();
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            gifts ? const PremiumGiftsScreen() : const NotificationsScreen(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushService.instance.onNotificationOpened = null;
    PushService.instance.onEntitlementsChanged = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<AppState>().steps.setForeground(
      state == AppLifecycleState.resumed,
    );
    if (state == AppLifecycleState.resumed && _splashDone) {
      context.read<AppState>().onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (_pendingNotification) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openPendingNotification(),
      );
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppBranding.name,
      locale: bnyadLocale(state.lang),
      supportedLocales: bnyadLocales,
      localizationsDelegates: bnyadDelegates,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: Directionality(
            textDirection: state.isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: _buildHome(state),
    );
  }

  Widget _buildHome(AppState state) {
    if (!_splashDone) {
      return SplashScreen(
        isDark: state.isDark,
        tagline: state.t.splashTagline,
        subline: state.t.splashSubline,
        onComplete: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }

    if (state.authLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo.icon(size: 40),
              const SizedBox(height: 16),
              Text(
                state.t.appLoading,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: state.isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.sessionNeedsRetry) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.t.sessionUnavailable, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.initializeSession,
                  child: Text(state.t.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!state.isLoggedIn) {
      return const LoginScreen();
    }

    if (!state.onboardingComplete) {
      return const OnboardingScreen();
    }

    return const _MainShell();
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    final screens = [
      const SettingsScreen(),
      AuthGate.block(title: t.signInToContinue, child: const FoodLogScreen()),
      const DashboardScreen(),
      AuthGate.block(
        title: t.signInToContinue,
        child: PremiumGate.block(
          title: t.mealPlan,
          subtitle: t.premiumPerkMealPlan,
          child: const MealPlanScreen(),
        ),
      ),
      AuthGate.block(
        title: t.signInToContinue,
        child: PremiumGate.block(
          title: t.foodScanner,
          subtitle: t.premiumPerkScanner,
          child: const ScannerScreen(),
        ),
      ),
    ];
    final tabSubtitles = [
      t.settings,
      t.foodLog,
      t.dashboard,
      t.mealPlan,
      t.foodScanner,
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const AppLogo.icon(size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppBranding.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.6,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
                Text(
                  state.isGuest
                      ? t.guestMode
                      : tabSubtitles[state.activeTab.clamp(
                          0,
                          tabSubtitles.length - 1,
                        )],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => state.setTheme(isDark ? 'light' : 'dark'),
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
              color: isDark ? AppTheme.amber : const Color(0xFF475569),
            ),
          ),
          if (state.isLoggedIn) ...[
            const SizedBox(width: 4),
            PopupMenuButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 48),
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: Text(
                    state.userDisplayName.isNotEmpty
                        ? state.userDisplayName
                        : t.guestUser,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                PopupMenuItem(
                  onTap: () => state.logout(),
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 16, color: AppTheme.rose),
                      const SizedBox(width: 8),
                      Text(
                        t.logout,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.rose,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isDark
                    ? AppTheme.navy750
                    : AppTheme.lightSurfaceTint,
                child: Text(
                  (state.userDisplayName.isNotEmpty
                          ? state.userDisplayName
                          : 'G')
                      .substring(0, 1)
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          if (state.saveFailed)
            MaterialBanner(
              content: Text(t.saveFailed),
              actions: [
                TextButton(
                  onPressed: state.dismissSaveError,
                  child: Text(t.close),
                ),
              ],
            ),
          if (!kIsWeb && !state.isOnline)
            Material(
              color: AppTheme.amber.withValues(alpha: 0.18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: AppTheme.amber.withValues(alpha: 0.95),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.offlineBanner,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: state.isDark
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(index: state.activeTab, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: state.activeTab,
        onDestinationSelected: state.setActiveTab,
        t: t,
        isDark: isDark,
      ),
    );
  }
}
