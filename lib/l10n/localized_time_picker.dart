import 'package:flutter/material.dart';
import 'localized_numbers.dart';

/// Flutter's stock text-time parser accepts ASCII only. Keep its existing dial
/// for English; provide localized numeric entry (plus the same optional dial)
/// for RTL languages without changing stored TimeOfDay/reminder semantics.
Future<TimeOfDay?> showBnyadTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  if (Directionality.of(context) != TextDirection.rtl) {
    return showTimePicker(context: context, initialTime: initialTime);
  }
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _LocalizedTimeInput(initialTime: initialTime),
  );
}

class _LocalizedTimeInput extends StatefulWidget {
  const _LocalizedTimeInput({required this.initialTime});
  final TimeOfDay initialTime;
  @override
  State<_LocalizedTimeInput> createState() => _LocalizedTimeInputState();
}

class _LocalizedTimeInputState extends State<_LocalizedTimeInput> {
  late final hour = TextEditingController(text: '${widget.initialTime.hour}');
  late final minute = TextEditingController(
    text: widget.initialTime.minute.toString().padLeft(2, '0'),
  );
  bool invalid = false;
  TimeOfDay? value() {
    final h = parseLocalizedInt(hour.text), m = parseLocalizedInt(minute.text);
    return h != null && h >= 0 && h < 24 && m != null && m >= 0 && m < 60
        ? TimeOfDay(hour: h, minute: m)
        : null;
  }

  @override
  void dispose() {
    hour.dispose();
    minute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MaterialLocalizations.of(context);
    Widget field(TextEditingController controller, String label, String key) =>
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                textDirection: Directionality.of(context),
              ),
              const SizedBox(height: 8),
              TextField(
                key: ValueKey(key),
                controller: controller,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.number,
                maxLength: 2,
                inputFormatters: const [LocalizedDigitsFormatter()],
                decoration: const InputDecoration(counterText: ''),
              ),
            ],
          ),
        );
    return AlertDialog(
      title: Text(t.timePickerInputHelpText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                field(hour, t.timePickerHourLabel, 'localized-hour'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':'),
                ),
                field(minute, t.timePickerMinuteLabel, 'localized-minute'),
              ],
            ),
          ),
          if (invalid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                t.invalidTimeLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: t.dialModeButtonLabel,
          icon: const Icon(Icons.schedule),
          onPressed: () async {
            final selected = await showTimePicker(
              context: context,
              initialTime: value() ?? widget.initialTime,
              initialEntryMode: TimePickerEntryMode.dialOnly,
            );
            if (selected != null && mounted) {
              setState(() {
                hour.text = '${selected.hour}';
                minute.text = selected.minute.toString().padLeft(2, '0');
                invalid = false;
              });
            }
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () {
            final time = value();
            if (time == null) {
              setState(() => invalid = true);
            } else {
              Navigator.pop(context, time);
            }
          },
          child: Text(t.okButtonLabel),
        ),
      ],
    );
  }
}
