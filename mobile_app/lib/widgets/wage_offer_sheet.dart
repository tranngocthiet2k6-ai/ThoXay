import 'package:flutter/material.dart';

class WageOffer {
  const WageOffer(this.rate, this.note);
  final int rate;
  final String note;
}

Future<WageOffer?> showWageOffer(BuildContext context) =>
    showModalBottomSheet<WageOffer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _WageOfferSheet(),
    );

class _WageOfferSheet extends StatefulWidget {
  const _WageOfferSheet();
  @override
  State<_WageOfferSheet> createState() => _WageOfferSheetState();
}

class _WageOfferSheetState extends State<_WageOfferSheet> {
  final _form = GlobalKey<FormState>();
  final _rate = TextEditingController(), _note = TextEditingController();
  @override
  void dispose() {
    _rate.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      8,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thương lượng giá',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Đề xuất mức công phù hợp. Chủ thầu sẽ xem và xác nhận khi duyệt đơn.',
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('offer-rate'),
              controller: _rate,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Lương đề xuất / ngày',
                suffixText: 'đ',
              ),
              validator: (value) {
                final rate = int.tryParse(value?.trim() ?? '');
                return rate == null || rate < 1 || rate > 1000000000
                    ? 'Nhập mức lương từ 1 đến 1.000.000.000đ'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('offer-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú thương lượng',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    WageOffer(int.parse(_rate.text.trim()), _note.text.trim()),
                  );
                }
              },
              child: const Text('Xem cam kết'),
            ),
          ],
        ),
      ),
    ),
  );
}
