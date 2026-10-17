import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/widgets/app_logo.dart';
import 'package:nutrify/theme/app_theme.dart';

enum _AuthStep { welcome, phone, register, otp, guestName, loginPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.fromGuestUpgrade = false});

  /// When true, hides guest mode (user is upgrading from a guest session).
  final bool fromGuestUpgrade;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _countryCode = '+964';

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _otpFocus = FocusNode();
  final _nameFocus = FocusNode();

  _AuthStep _step = _AuthStep.welcome;
  bool _isRegisteringMode = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isReturningUser = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _otpFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    var digits = normalizeDigits(
      _phoneController.text,
    ).replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '$_countryCode$digits';
  }

  String get _displayPhoneNumber {
    var digits = normalizeDigits(
      _phoneController.text,
    ).replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) return _countryCode;
    return ltrFragment('$_countryCode $digits');
  }

  bool _isValidPhone(String digits) {
    var d = normalizeDigits(digits);
    if (d.startsWith('0')) {
      d = d.substring(1);
    }
    return d.length >= 9 && d.length <= 11;
  }

  bool _isValidPassword(String password) => password.trim().length >= 6;

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _continueFromPhone(AppState state) async {
    final t = state.t;
    final digits = normalizeDigits(
      _phoneController.text,
    ).replaceAll(RegExp(r'\D'), '');
    if (!_isValidPhone(digits)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidPhoneNumber)));
      return;
    }

    setState(() => _loading = true);
    final registered = await state.checkPhoneRegistered(_fullPhoneNumber);
    if (!mounted) return;
    setState(() => _loading = false);

    if (registered == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.otpBackendPending)));
      return;
    }

    setState(() => _isReturningUser = registered);

    if (registered) {
      if (_isRegisteringMode) {
        // User clicked Register but account already exists, switch to Password Login
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.phoneAlreadyRegistered)));
        setState(() {
          _isRegisteringMode = false;
          _step = _AuthStep.loginPassword;
          _passwordController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _passwordFocus.requestFocus(),
        );
      } else {
        setState(() {
          _step = _AuthStep.loginPassword;
          _passwordController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _passwordFocus.requestFocus(),
        );
      }
    } else {
      if (!_isRegisteringMode) {
        // User clicked Login but account doesn't exist, switch to Register
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.phoneNotRegistered)));
        setState(() {
          _isRegisteringMode = true;
          _step = _AuthStep.register;
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _nameFocus.requestFocus(),
        );
      } else {
        setState(() => _step = _AuthStep.register);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _nameFocus.requestFocus(),
        );
      }
    }
  }

  Future<void> _sendOtp(AppState state) async {
    final digits = normalizeDigits(
      _phoneController.text,
    ).replaceAll(RegExp(r'\D'), '');
    if (!_isValidPhone(digits)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.invalidPhoneNumber)));
      return;
    }

    setState(() => _loading = true);
    final err = await state.sendPhoneOtp(_fullPhoneNumber);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.localizeError(err))));
      return;
    }

    setState(() {
      _step = _AuthStep.otp;
      _otpController.clear();
    });
    _startResendCountdown();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _otpFocus.requestFocus(),
    );
  }

  Future<void> _submitRegistration(AppState state) async {
    final t = state.t;
    final name = _nameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidName)));
      return;
    }
    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidPassword)));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.passwordsDoNotMatch)));
      return;
    }

    await _sendOtp(state);
  }

  Future<void> _verifyOtp(AppState state) async {
    final t = state.t;
    final code = normalizeDigits(_otpController.text).trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidOtpCode)));
      return;
    }

    setState(() => _loading = true);
    final err = await state.verifyPhoneOtp(
      _fullPhoneNumber,
      code,
      password: _passwordController.text.trim(),
      name: _isReturningUser ? null : _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.localizeError(err))));
      return;
    }

    if (state.isAuthenticated) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _openGuestNameStep() {
    setState(() => _step = _AuthStep.guestName);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _nameFocus.requestFocus(),
    );
  }

  Future<void> _completeGuestSignIn(AppState state) async {
    final t = state.t;
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.invalidName)));
      return;
    }

    setState(() => _loading = true);
    await state.completeSignInWithName(name);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _backToPhoneStep() {
    _resendTimer?.cancel();
    setState(() {
      _step = _AuthStep.phone;
      _resendSeconds = 0;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _phoneFocus.requestFocus(),
    );
  }

  void _backToWelcome() {
    _resendTimer?.cancel();
    setState(() {
      _step = _AuthStep.welcome;
      _resendSeconds = 0;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _phoneController.clear();
    });
  }

  void _backFromRegister() {
    setState(() {
      _step = _AuthStep.phone;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _nameController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _phoneFocus.requestFocus(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? AppTheme.darkWelcomeGradient
                : AppTheme.lightWelcomeGradient,
          ),
          color: isDark ? AppTheme.navy900 : null,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.navy800.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark
                      ? AppTheme.brandOrange.withValues(alpha: 0.18)
                      : AppTheme.brandOrange.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? AppTheme.indigo.withValues(alpha: 0.05)
                        : const Color(0xFFE2E8F0),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.fromGuestUpgrade)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  const AppBrandHeader(
                    logoSize: 100,
                    titleSize: 32,
                    spacing: 16,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.onboardingSubtitle,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      _AuthStep.welcome => _buildWelcomeStep(
                        context,
                        state,
                        t,
                        isDark,
                      ),
                      _AuthStep.guestName => _buildGuestNameStep(
                        context,
                        state,
                        t,
                        isDark,
                      ),
                      _AuthStep.otp => _buildOtpStep(context, state, t, isDark),
                      _AuthStep.register => _buildRegisterStep(
                        context,
                        state,
                        t,
                        isDark,
                      ),
                      _AuthStep.loginPassword => _buildLoginPasswordStep(
                        context,
                        state,
                        t,
                        isDark,
                      ),
                      _ => _buildPhoneStep(context, state, t, isDark),
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _langButton('EN', 'en', state),
                      const SizedBox(width: 16),
                      _langButton('AR', 'ar', state),
                      const SizedBox(width: 16),
                      _langButton('KU', 'ku', state),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitPasswordLogin(AppState state) async {
    final digits = normalizeDigits(
      _phoneController.text,
    ).replaceAll(RegExp(r'\D'), '');
    if (!_isValidPhone(digits)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.invalidPhoneNumber)));
      return;
    }

    final password = _passwordController.text;
    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.invalidPassword)));
      return;
    }

    setState(() => _loading = true);
    final err = await state.loginWithPassword(_fullPhoneNumber, password);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.t.localizeError(err))));
      return;
    }

    if (state.isAuthenticated) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildLoginPasswordStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('login-password-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.welcomeBack,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.phoneNumber, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        _phoneField(isDark, t),
        const SizedBox(height: 16),
        Text(t.password, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _submitPasswordLogin(state),
          decoration: _inputDecoration(
            isDark,
            hint: t.passwordHint,
            icon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _submitPasswordLogin(state),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.login),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: _loading ? null : _backToWelcome,
              child: Text(t.back),
            ),
            TextButton(
              onPressed: _loading ? null : () => _sendOtp(state),
              child: Text(t.loginWithOtp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('phone-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.signInWithPhone,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 16),
        _phoneField(isDark, t),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : () => _continueFromPhone(state),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, size: 22),
            label: Text(t.continueWithPhone),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _loading
                ? null
                : () {
                    setState(() {
                      _step = _AuthStep.welcome;
                    });
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              t.back.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('register-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.createAccount,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.registerSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.phoneNumber, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        _phoneField(isDark, t, readOnly: true),
        const SizedBox(height: 12),
        Text(t.yourName, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: _inputDecoration(
            isDark,
            hint: t.nameHint,
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 12),
        Text(t.password, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
          decoration: _inputDecoration(
            isDark,
            hint: t.passwordHint,
            icon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(t.confirmPassword, style: _fieldLabelStyle(isDark)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _submitRegistration(state),
          decoration: _inputDecoration(
            isDark,
            hint: t.confirmPasswordHint,
            icon: Icons.lock_outline,
            suffix: IconButton(
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _submitRegistration(state),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.sendOtp),
          ),
        ),
        TextButton(
          onPressed: _loading ? null : _backFromRegister,
          child: Text(t.changePhoneNumber),
        ),
      ],
    );
  }

  Widget _buildOtpStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('otp-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isReturningUser ? t.welcomeBack : t.enterOtpCode,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${t.otpSentTo} ${ltrFragment(_displayPhoneNumber)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        if (_isReturningUser) ...[
          const SizedBox(height: 8),
          Text(
            t.returningUserOtpHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Text(t.password, style: _fieldLabelStyle(isDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _otpFocus.requestFocus(),
            decoration: _inputDecoration(
              isDark,
              hint: t.passwordHint,
              icon: Icons.lock_outline,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _otpController,
          focusNode: _otpFocus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          maxLength: 6,
          onSubmitted: (_) => _loading ? null : _verifyOtp(state),
          inputFormatters: [
            const LocalizedDigitsFormatter(),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 12,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: t.otpCodeHint,
            counterText: '',
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _verifyOtp(state),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.verifyOtp),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: _loading ? null : _backToPhoneStep,
              child: Text(t.changePhoneNumber),
            ),
            TextButton(
              onPressed: (_loading || _resendSeconds > 0)
                  ? null
                  : () => _sendOtp(state),
              child: Text(
                _resendSeconds > 0
                    ? t.resendOtpIn.replaceAll('{seconds}', '$_resendSeconds')
                    : t.resendOtp,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestNameStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('guest-name-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.whatIsYourName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.nameSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _completeGuestSignIn(state),
          decoration: _inputDecoration(
            isDark,
            hint: t.nameHint,
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _completeGuestSignIn(state),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(t.continueLabel),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _loading
                ? null
                : () {
                    setState(() {
                      _step = _AuthStep.welcome;
                    });
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              t.back.toUpperCase(),
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneField(bool isDark, AppLocalizations t, {bool readOnly = false}) {
    return TextField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      readOnly: readOnly,
      keyboardType: TextInputType.phone,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.done,
      onSubmitted: readOnly
          ? null
          : (_) =>
                _loading ? null : _continueFromPhone(context.read<AppState>()),
      inputFormatters: [
        const LocalizedDigitsFormatter(),
        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
      ],
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android,
                size: 20,
                color: AppTheme.indigo.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                _countryCode,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: t.phoneNumberHint,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
    );
  }

  TextStyle _fieldLabelStyle(bool isDark) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
  );

  InputDecoration _inputDecoration(
    bool isDark, {
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppTheme.indigo.withValues(alpha: 0.8)),
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1E293B).withValues(alpha: 0.5)
          : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  Widget _langButton(String label, String code, AppState state) {
    final isActive = state.lang == code;
    return GestureDetector(
      onTap: () => state.setLang(code),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isActive
              ? AppTheme.brandOrangeDeep
              : (state.isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(
    BuildContext context,
    AppState state,
    AppLocalizations t,
    bool isDark,
  ) {
    return Column(
      key: const ValueKey('welcome-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.welcomeTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          t.welcomeSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isRegisteringMode = false;
              _step = _AuthStep.loginPassword;
            });
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _phoneFocus.requestFocus(),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: AppTheme.indigo,
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: AppTheme.indigo.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login_rounded, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  t.login,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isRegisteringMode = true;
              _step = _AuthStep.phone;
            });
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _phoneFocus.requestFocus(),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isDark
                  ? AppTheme.indigoLight.withValues(alpha: 0.6)
                  : AppTheme.indigo.withValues(alpha: 0.6),
              width: 2,
            ),
            foregroundColor: isDark ? AppTheme.indigoLight : AppTheme.indigo,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_add_rounded, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  t.signUp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.fromGuestUpgrade) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  state.t.get('or'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loading ? null : _openGuestNameStep,
            style: TextButton.styleFrom(
              backgroundColor: AppTheme.rose.withValues(
                alpha: isDark ? 0.08 : 0.05,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              t.guestMode.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.rose,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
