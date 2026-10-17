import 'dart:typed_data';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:nutrify/utils/ai_strings.dart';

import 'package:flutter/material.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/screens/medical_citations_screen.dart';
import 'package:nutrify/utils/ai_trilingual_strings.dart';
import 'package:nutrify/utils/body_fat_calculator.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';

class BodyFatEstimatorScreen extends StatefulWidget {
  const BodyFatEstimatorScreen({super.key});

  @override
  State<BodyFatEstimatorScreen> createState() => _BodyFatEstimatorScreenState();
}

class _BodyFatEstimatorScreenState extends State<BodyFatEstimatorScreen> {
  final ImagePicker _picker = ImagePicker();
  final _waistController = TextEditingController();
  final _neckController = TextEditingController();
  final _hipController = TextEditingController();

  bool _busy = false;
  Uint8List? _bytes;
  BodyFatEstimate? _estimate;
  Map<String, dynamic>? _aiMeta;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBaseline());
  }

  @override
  void dispose() {
    _waistController.dispose();
    _neckController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  bool get _isFemale {
    final profile = context.read<AppState>().userProfile;
    if (profile == null) return false;
    final g = profile.gender.toLowerCase();
    return g == 'female' || g == 'f';
  }

  double? _parseCm(TextEditingController c) {
    final v = parseLocalizedDouble(c.text);
    if (v == null || v <= 0) return null;
    return v;
  }

  void _refreshBaseline() {
    final profile = context.read<AppState>().userProfile;
    if (profile == null) return;
    setState(() {
      _estimate = estimateFromProfile(profile);
      _aiMeta = null;
      _error = null;
    });
  }

  void _calculateFromMeasurements() {
    final profile = context.read<AppState>().userProfile;
    if (profile == null) return;

    final waist = _parseCm(_waistController);
    final neck = _parseCm(_neckController);
    final hip = _isFemale ? _parseCm(_hipController) : null;

    if (waist == null || neck == null || (_isFemale && hip == null)) {
      setState(
        () => _error = context.read<AppState>().t.bodyFatMeasureRequired,
      );
      return;
    }

    setState(() {
      _estimate = estimateFromMeasurements(
        profile: profile,
        waistCm: waist,
        neckCm: neck,
        hipCm: hip,
      );
      _aiMeta = null;
      _error = null;
    });
  }

  Future<void> _pick(ImageSource source) async {
    final initialState = context.read<AppState>();
    if (!await ensureAiConsent(context, initialState) || !mounted) return;
    final profile = context.read<AppState>().userProfile;
    if (profile == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        requestFullMetadata: false,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() {
        _busy = true;
        _bytes = null;
        _aiMeta = null;
        _error = null;
      });

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      final state = Provider.of<AppState>(context, listen: false);
      if (!state.isOnline) {
        setState(() {
          _busy = false;
          _error = state.t.noInternet;
        });
        return;
      }

      final waist = _parseCm(_waistController);
      final neck = _parseCm(_neckController);
      final hip = _isFemale ? _parseCm(_hipController) : null;

      BodyFatEstimate? anchor = _estimate;
      if (waist != null && neck != null && (!_isFemale || hip != null)) {
        anchor = estimateFromMeasurements(
          profile: profile,
          waistCm: waist,
          neckCm: neck,
          hipCm: hip,
        );
      } else {
        anchor ??= estimateFromProfile(profile);
      }

      final out = await state.ai.estimateBodyFatFromPhoto(
        imageBytes: bytes,
        gender: profile.gender,
        age: profile.age,
        heightCm: profile.height,
        weightKg: profile.weight,
        waistCm: waist,
        neckCm: neck,
        hipCm: hip,
        anchorPercent: anchor.centerPercent,
        anchorMethod: anchor.method,
      );

      if (!mounted) return;

      setState(() {
        _busy = false;
        _bytes = bytes;
        if (out == null) {
          _error = AiStrings.get(state.lang, state.aiErrorCode);
        } else {
          final aiMin = (out['min_percent'] as num?)?.toDouble();
          final aiMax = (out['max_percent'] as num?)?.toDouble();
          if (aiMin != null && aiMax != null) {
            _estimate = blendPhotoWithAnchor(
              anchor: anchor!,
              aiMin: aiMin,
              aiMax: aiMax,
            );
          } else {
            _estimate = anchor;
          }
          _aiMeta = out;
          _error = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      final state = Provider.of<AppState>(context, listen: false);
      setState(() {
        _busy = false;
        _error = state.t.bodyFatFailed;
      });
    }
  }

  String _fmtPct(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(1);
  }

  String _methodLabel(dynamic t, String method) {
    switch (method) {
      case 'navy':
        return t.bodyFatMethodNavy;
      case 'deurenberg':
        return t.bodyFatMethodDeurenberg;
      case 'blended':
        return t.bodyFatMethodBlended;
      default:
        return t.bodyFatMethodPhoto;
    }
  }

  String _confidenceLabel(dynamic t, String confidence) {
    switch (confidence) {
      case 'high':
        return t.bodyFatConfidenceHigh;
      case 'medium':
        return t.bodyFatConfidenceMedium;
      default:
        return t.bodyFatConfidenceLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;
    final lang = state.lang;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final profile = state.userProfile;

    final notes = _aiMeta == null
        ? ''
        : trilingualString(
            _aiMeta,
            mapKey: 'notes',
            legacyKey: 'notes',
            lang: lang,
          );
    final aiDisclaimer = _aiMeta == null
        ? ''
        : trilingualString(
            _aiMeta,
            mapKey: 'disclaimer',
            legacyKey: 'disclaimer',
            lang: lang,
          );

    final estimate = _estimate;

    return Scaffold(
      appBar: AppBar(title: Text(t.bodyFatScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            t.bodyFatScreenIntro,
            style: TextStyle(fontSize: 14, height: 1.45, color: muted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.slate600 : const Color(0xFFFCD34D),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 22,
                  color: isDark ? AppTheme.amber : const Color(0xFFB45309),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.bodyFatStaticDisclaimer,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showMedicalCitationsModal(context),
            icon: const Icon(Icons.science_outlined, size: 16),
            label: Text(t.medicalSourcesCitations),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              side: BorderSide(
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 24),
            Text(
              t.bodyFatMeasureTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t.bodyFatMeasureHint,
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
            const SizedBox(height: 12),
            Text(
              '${t.bodyFatProfileContext}: ${ltrFragment('${profile.weight.round()} kg')} · ${ltrFragment('${profile.height.round()} cm')} · ${profile.age} ${t.age}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${t.yourBmi}: ${computeBmi(weightKg: profile.weight, heightCm: profile.height).toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _measureField(
                    t.bodyFatWaistCm,
                    _waistController,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _measureField(
                    t.bodyFatNeckCm,
                    _neckController,
                    isDark,
                  ),
                ),
              ],
            ),
            if (_isFemale) ...[
              const SizedBox(height: 8),
              _measureField(t.bodyFatHipCm, _hipController, isDark),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _calculateFromMeasurements,
                icon: const Icon(Icons.straighten_rounded, size: 20),
                label: Text(t.bodyFatCalculateMeasurements),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.indigo,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            t.bodyFatPhotoOptional,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.bodyFatPhotoHint,
            style: TextStyle(fontSize: 13, height: 1.4, color: muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 20),
                  label: Text(t.startCamera),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: Text(t.uploadPhoto),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          if (_busy) ...[
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.bodyFatAnalyzing,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null && !_busy) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.rose, fontSize: 13),
            ),
          ],
          if (_bytes != null && !_busy) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.memory(_bytes!, fit: BoxFit.cover),
              ),
            ),
          ],
          if (estimate != null && !_busy) ...[
            const SizedBox(height: 24),
            Text(
              t.bodyFatEstimatedRange,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ltrFragment(
                '${_fmtPct(estimate.minPercent)}% — ${_fmtPct(estimate.maxPercent)}%',
              ),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${t.bodyFatMethodLabel}: ${_methodLabel(t, estimate.method)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${t.bodyFatConfidenceLabel}: ${_confidenceLabel(t, estimate.confidence)}',
              style: TextStyle(fontSize: 13, color: muted),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                t.bodyFatAiNotes,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                notes,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
            ],
            if (aiDisclaimer.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                t.bodyFatAiDisclaimer,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: muted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                aiDisclaimer,
                style: TextStyle(fontSize: 13, height: 1.45, color: muted),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () {
                      setState(() {
                        _bytes = null;
                        _aiMeta = null;
                        _error = null;
                        _refreshBaseline();
                      });
                    },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(t.bodyFatRetakePhoto),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _measureField(
    String label,
    TextEditingController controller,
    bool isDark,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'cm',
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
