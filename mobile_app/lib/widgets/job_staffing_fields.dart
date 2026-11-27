import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Two trades in one job, each with an editable quantity and stepper buttons.
class JobStaffingFields extends StatelessWidget {
  const JobStaffingFields({
    super.key,
    required this.skilledController,
    required this.helpersController,
    required this.skilledSelected,
    required this.helpersSelected,
    required this.onSkilledChanged,
    required this.onHelpersChanged,
    this.enabled = true,
  });

  final TextEditingController skilledController, helpersController;
  final bool skilledSelected, helpersSelected, enabled;
  final ValueChanged<bool> onSkilledChanged, onHelpersChanged;

  @override
  Widget build(BuildContext context) => FormField<bool>(
    validator: (_) {
      if (!skilledSelected && !helpersSelected) {
        return 'Chọn ít nhất một loại thợ';
      }
      final skilled = skilledSelected
          ? int.tryParse(skilledController.text) ?? 0
          : 0;
      final helpers = helpersSelected
          ? int.tryParse(helpersController.text) ?? 0
          : 0;
      return skilled + helpers > 10000 ? 'Tổng số thợ không quá 10.000' : null;
    },
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thợ cần tuyển', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _trade(
                context,
                'Thợ chính',
                skilledController,
                skilledSelected,
                onSkilledChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _trade(
                context,
                'Phụ hồ',
                helpersController,
                helpersSelected,
                onHelpersChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn một hoặc cả hai loại. Nhập số lượng hoặc bấm − / +.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              field.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );

  Widget _trade(
    BuildContext context,
    String label,
    TextEditingController controller,
    bool selected,
    ValueChanged<bool> onChanged,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primary.withValues(alpha: .05) : colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: selected ? colors.primary : colors.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: enabled ? () => onChanged(!selected) : null,
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  semanticLabel: 'Tuyển $label',
                  onChanged: enabled ? (value) => onChanged(value!) : null,
                ),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final count = int.tryParse(value.text) ?? 0;
                void step(int delta) {
                  final next = (count + delta).clamp(1, 10000).toString();
                  controller.value = TextEditingValue(
                    text: next,
                    selection: TextSelection.collapsed(offset: next.length),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Giảm số $label',
                      onPressed: enabled && selected && count > 1
                          ? () => step(-1)
                          : null,
                      icon: const Icon(Icons.remove, size: 20),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 48,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('quantity-$label'),
                        controller: controller,
                        enabled: enabled && selected,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Số lượng',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 14,
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: (text) {
                          if (!selected) return null;
                          final number = int.tryParse(text ?? '');
                          return number == null || number < 1 || number > 10000
                              ? 'Từ 1–10.000'
                              : null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tăng số $label',
                      onPressed: enabled && selected && count < 10000
                          ? () => step(1)
                          : null,
                      icon: const Icon(Icons.add, size: 20),
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 48,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
