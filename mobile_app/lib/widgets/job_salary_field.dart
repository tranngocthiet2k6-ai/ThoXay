import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';

class JobSalaryField extends StatelessWidget {
  const JobSalaryField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final TextEditingController controller;
  final bool enabled;
  static const minimum = 200000;
  static const maximum = 1000000000;

  static int? validAmount(String text) {
    final amount = int.tryParse(text.trim());
    return amount != null && amount > minimum && amount <= maximum
        ? amount
        : null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: const InputDecoration(
          labelText: 'Lương mỗi ngày',
          hintText: 'Ví dụ: 350000',
          prefixIcon: Icon(Icons.payments_outlined),
          suffixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(widthFactor: 1, child: Text('VND')),
          ),
          helperText:
              'Trên 200.000 VND/ngày. Tự nhập hoặc chọn nhanh bên dưới.',
          helperMaxLines: 3,
          errorMaxLines: 3,
        ),
        validator: (value) => validAmount(value ?? '') == null
            ? 'Lương phải trên 200.000 và không quá 1.000.000.000 VND/ngày'
            : null,
      ),
      const SizedBox(height: 8),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amount in [250000, 300000, 400000, 500000, 700000])
              ChoiceChip(
                label: Text(money(amount.toDouble(), currency: 'VND')),
                selected: validAmount(value.text) == amount,
                onSelected: enabled
                    ? (_) {
                        final text = '$amount';
                        controller.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.collapsed(
                            offset: text.length,
                          ),
                        );
                      }
                    : null,
              ),
          ],
        ),
      ),
    ],
  );
}
