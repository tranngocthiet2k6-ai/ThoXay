import 'package:flutter/material.dart';
import '../services/location_service.dart';

Future<GeoPoint?> showCoordinatesDialog(BuildContext context,
        {GeoPoint? current}) =>
    showDialog<GeoPoint>(
        context: context, builder: (_) => _CoordinatesDialog(current: current));

class _CoordinatesDialog extends StatefulWidget {
  const _CoordinatesDialog({this.current});
  final GeoPoint? current;
  @override
  State<_CoordinatesDialog> createState() => _CoordinatesDialogState();
}

class _CoordinatesDialogState extends State<_CoordinatesDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _lat =
      TextEditingController(text: widget.current?.latitude.toString() ?? '');
  late final TextEditingController _lng =
      TextEditingController(text: widget.current?.longitude.toString() ?? '');
  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _validate(String? value, double limit) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || !number.isFinite || number.abs() > limit
        ? 'Giá trị từ -$limit đến $limit'
        : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Chọn vị trí'),
        content: SizedBox(
            width: 360,
            child: Form(
                key: _form,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'Nhập tọa độ vị trí bạn muốn tìm việc hoặc đăng công trình.'),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _lat,
                      decoration: const InputDecoration(labelText: 'Vĩ độ'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) => _validate(v, 90)),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _lng,
                      decoration: const InputDecoration(labelText: 'Kinh độ'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) => _validate(v, 180)),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () {
                if (_form.currentState!.validate()) {
                  Navigator.pop(
                      context,
                      GeoPoint(double.parse(_lat.text.trim()),
                          double.parse(_lng.text.trim())));
                }
              },
              child: const Text('Dùng vị trí này'))
        ],
      );
}
