import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/services/food_barcode_service.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

/// Opens barcode scanner → shows macros → asks to log to daily intake.
Future<void> openBarcodeScanFlow(
  BuildContext context, {
  required AppState state,
  String? mealId,
}) async {
  if (!kIsWeb) {
    final granted = await _ensureCameraPermission(context, state);
    if (!granted) return;
  }

  if (!context.mounted) return;

  final lookup = await Navigator.of(context).push<BarcodeFoodLookup>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _BarcodeScannerPage(state: state),
    ),
  );

  if (lookup == null || !context.mounted) return;

  final logged = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        _BarcodeConfirmSheet(state: state, lookup: lookup, mealId: mealId),
  );

  if (logged == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.t.barcodeLogged)));
  }
}

Future<bool> _ensureCameraPermission(
  BuildContext context,
  AppState state,
) async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;

  status = await Permission.camera.request();
  if (status.isGranted) return true;

  if (!context.mounted) return false;

  final message = status.isPermanentlyDenied
      ? state.t.barcodeCameraSettings
      : state.t.barcodeCameraDenied;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: status.isPermanentlyDenied
          ? SnackBarAction(label: state.t.settings, onPressed: openAppSettings)
          : null,
    ),
  );
  return false;
}

class _BarcodeScannerPage extends StatefulWidget {
  final AppState state;
  const _BarcodeScannerPage({required this.state});

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final FoodBarcodeService _service = FoodBarcodeService();
  // Read every common retail/product symbology so more packaged foods are
  // recognized (not just EAN/UPC) — e.g. Code 128, Code 39, ITF, DataBar.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf,
      BarcodeFormat.dataMatrix,
    ],
  );
  final TextEditingController _manualController = TextEditingController();

  bool _lookupLocked = false;
  String? _error;
  String? _lastHandledCode;
  DateTime? _lastHandledAt;

  @override
  void dispose() {
    _manualController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _messageForFailure(BarcodeLookupFailure failure) {
    final t = widget.state.t;
    switch (failure) {
      case BarcodeLookupFailure.invalidBarcode:
        return t.barcodeInvalid;
      case BarcodeLookupFailure.offline:
        return t.noInternet;
      case BarcodeLookupFailure.notFound:
        return t.barcodeNotFound;
      case BarcodeLookupFailure.networkError:
        return t.barcodeNetworkError;
    }
  }

  bool _shouldIgnoreDuplicate(String code) {
    final now = DateTime.now();
    if (_lastHandledCode == code &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastHandledCode = code;
    _lastHandledAt = now;
    return false;
  }

  Future<void> _lookupBarcode(String code) async {
    if (_lookupLocked) return;
    if (_shouldIgnoreDuplicate(code)) return;

    setState(() {
      _lookupLocked = true;
      _error = null;
    });

    await _controller.stop();

    final result = await _service.lookup(code, isOnline: widget.state.isOnline);

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(result.lookup);
      return;
    }

    if (result.failure == BarcodeLookupFailure.notFound) {
      setState(() {
        _lookupLocked = false;
        _error = null;
      });

      final saved = await showModalBottomSheet<BarcodeFoodLookup>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _BarcodeNotFoundSheet(
          state: widget.state,
          barcode:
              result.resolvedBarcode ??
              (FoodBarcodeService.barcodeLookupCandidates(code).isNotEmpty
                  ? FoodBarcodeService.barcodeLookupCandidates(code).first
                  : code),
          service: _service,
        ),
      );

      if (!mounted) return;
      if (saved != null) {
        Navigator.of(context).pop(saved);
        return;
      }

      setState(() => _error = widget.state.t.barcodeNotFound);
      await _controller.start();
      return;
    }

    setState(() {
      _lookupLocked = false;
      _error = _messageForFailure(
        result.failure ?? BarcodeLookupFailure.notFound,
      );
    });
    await _controller.start();
  }

  Future<void> _lookupManual() async {
    final code = _manualController.text.trim();
    if (code.isEmpty) return;
    _lastHandledCode = null;
    await _lookupBarcode(code);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.t;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t.scanBarcode),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t.barcodeCameraDenied,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.barcodeManualHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onDetect: (capture) {
                    for (final b in capture.barcodes) {
                      final raw = b.rawValue;
                      if (raw != null && raw.isNotEmpty) {
                        _lookupBarcode(raw);
                        break;
                      }
                    }
                  },
                ),
                if (_lookupLocked)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppTheme.indigo,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.barcodeLookingUp,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: Text(
                    t.barcodeScanHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.rose.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  t.barcodeManualEntry,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: t.barcodeManualHint,
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _lookupManual(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _lookupLocked ? null : _lookupManual,
                      child: Text(t.barcodeLookupButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarcodeConfirmSheet extends StatefulWidget {
  final AppState state;
  final BarcodeFoodLookup lookup;
  final String? mealId;

  const _BarcodeConfirmSheet({
    required this.state,
    required this.lookup,
    this.mealId,
  });

  @override
  State<_BarcodeConfirmSheet> createState() => _BarcodeConfirmSheetState();
}

class _BarcodeConfirmSheetState extends State<_BarcodeConfirmSheet> {
  late double _grams;

  @override
  void initState() {
    super.initState();
    _grams = widget.lookup.initialGrams;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.t;
    final isDark = widget.state.isDark;
    final lookup = widget.lookup;
    final macros = lookup.macrosForGrams(_grams);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lookup.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppTheme.slate900,
                          ),
                        ),
                        if (lookup.brand != null)
                          Text(
                            lookup.brand!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.slate400
                                  : AppTheme.slate600,
                            ),
                          ),
                        Text(
                          '${t.per100g}: ${lookup.caloriesPer100g.round()} ${t.kcal}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.slate500
                                : AppTheme.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.mealId != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t.mealSlotLabel(widget.mealId!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.indigoLight
                          : AppTheme.indigoDark,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                t.barcodeAmountLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                ),
              ),
              Row(
                children: [
                  _gramStepButton(Icons.remove, isDark, () {
                    setState(() => _grams = (_grams - 10).clamp(5, 2000));
                  }),
                  Expanded(
                    child: Slider(
                      value: _grams.clamp(5, 1000),
                      min: 5,
                      max: 1000,
                      divisions: 199,
                      label: '${_grams.round()} ${t.grams}',
                      onChanged: (v) =>
                          setState(() => _grams = v.roundToDouble()),
                    ),
                  ),
                  _gramStepButton(Icons.add, isDark, () {
                    setState(() => _grams = (_grams + 10).clamp(5, 2000));
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '${_grams.round()} ${t.grams}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.indigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [50, 100, 150, 200, 300, 500].map((g) {
                  final active = _grams.round() == g;
                  return GestureDetector(
                    onTap: () => setState(() => _grams = g.toDouble()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.indigo
                            : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$g${t.grams}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : (isDark
                                    ? AppTheme.slate300
                                    : AppTheme.slate600),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _macroChip(t.calories, macros['calories']!.round(), isDark),
                  const SizedBox(width: 8),
                  _macroChip(t.protein, macros['protein']!.round(), isDark),
                  const SizedBox(width: 8),
                  _macroChip(t.carbs, macros['carbs']!.round(), isDark),
                  const SizedBox(width: 8),
                  _macroChip(t.fat, macros['fat']!.round(), isDark),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                t.barcodeLogQuestion,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.slate200 : AppTheme.slate800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(t.barcodeLogNo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final foodId =
                            lookup.localFoodId ?? 'barcode_${lookup.barcode}';
                        final saved = await widget.state.addLogEntry(
                          LogEntry(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            foodId: foodId,
                            name: lookup.name,
                            amount: _grams,
                            calories: macros['calories']!,
                            protein: macros['protein']!,
                            carbs: macros['carbs']!,
                            fat: macros['fat']!,
                            timestamp: DateTime.now().millisecondsSinceEpoch,
                            mealId: widget.mealId,
                          ),
                        );
                        if (!context.mounted) return;
                        if (saved) {
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(t.saveFailed)));
                        }
                      },
                      icon: const Icon(Icons.add_chart),
                      label: Text(t.barcodeLogYes),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gramStepButton(IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppTheme.indigo),
      ),
    );
  }

  Widget _macroChip(String label, int value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.slate500 : AppTheme.slate600,
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.slate900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeNotFoundSheet extends StatefulWidget {
  final AppState state;
  final String barcode;
  final FoodBarcodeService service;

  const _BarcodeNotFoundSheet({
    required this.state,
    required this.barcode,
    required this.service,
  });

  @override
  State<_BarcodeNotFoundSheet> createState() => _BarcodeNotFoundSheetState();
}

class _BarcodeNotFoundSheetState extends State<_BarcodeNotFoundSheet> {
  final _nameController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double _parseField(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _saveManual() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final lookup = BarcodeFoodLookup(
      barcode: widget.barcode,
      name: name,
      caloriesPer100g: _parseField(_kcalController),
      proteinPer100g: _parseField(_proteinController),
      carbsPer100g: _parseField(_carbsController),
      fatPer100g: _parseField(_fatController),
      fromLocalDatabase: true,
    );
    await widget.service.remember(widget.barcode, lookup);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.state.t.barcodeSavedForNextTime)),
    );
    Navigator.pop(context, lookup);
  }

  Future<void> _pickFromApp() async {
    final food = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BarcodeFoodPickerSheet(state: widget.state),
    );
    if (food == null || !mounted) return;

    final lookup = BarcodeFoodLookup.fromFoodItem(
      barcode: widget.barcode,
      food: food,
    );
    await widget.service.remember(widget.barcode, lookup);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.state.t.barcodeSavedForNextTime)),
    );
    Navigator.pop(context, lookup);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.t;
    final isDark = widget.state.isDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.barcodeNotFoundTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.barcodeNotFoundBody,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${t.barcodeManualHint}: ${widget.barcode}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.barcodeAddManually,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.barcodeProductName),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _kcalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${t.calories} / 100g',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _proteinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${t.protein} / 100g',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _carbsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${t.carbs} / 100g',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _fatController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: '${t.fat} / 100g'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveManual,
                  child: Text(t.barcodeSaveAndContinue),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _pickFromApp,
                  child: Text(t.barcodePickFromApp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeFoodPickerSheet extends StatefulWidget {
  final AppState state;
  const _BarcodeFoodPickerSheet({required this.state});

  @override
  State<_BarcodeFoodPickerSheet> createState() =>
      _BarcodeFoodPickerSheetState();
}

class _BarcodeFoodPickerSheetState extends State<_BarcodeFoodPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.state.isDark;
    final lang = widget.state.lang;
    final matches = foodDatabase
        .where((f) {
          if (_query.trim().isEmpty) return true;
          return f.matchesSearchQuery(_query);
        })
        .take(40)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: widget.state.t.searchFood,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (_, i) {
                  final food = matches[i];
                  return ListTile(
                    title: Text(food.getLocalizedName(lang)),
                    subtitle: Text(
                      '${food.calories.round()} ${widget.state.t.kcal} / 100g',
                    ),
                    onTap: () => Navigator.pop(context, food),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
