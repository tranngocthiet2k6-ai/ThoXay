import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/incident.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'wallet_operation_dialog.dart';

class IncidentReportDialog extends StatefulWidget {
  const IncidentReportDialog({
    super.key,
    required this.api,
    required this.job,
    this.sos = false,
    this.location,
  });
  final ApiService api;
  final Job job;
  final bool sos;
  final LocationService? location;
  @override
  State<IncidentReportDialog> createState() => _IncidentReportDialogState();
}

class _IncidentReportDialogState extends State<IncidentReportDialog> {
  final _form = GlobalKey<FormState>();
  final _description = TextEditingController();
  late final _id = requestId();
  late String _type;
  bool _busy = false, _locating = false;
  int _gpsRun = 0;
  GeoPoint? _position;
  String? _error, _gpsNote;
  Map<String, dynamic>? _attempt;
  @override
  void initState() {
    super.initState();
    _type = widget.sos ? 'SOS' : 'SAFETY';
    if (widget.sos) {
      _description.text = 'Tôi cần Admin hỗ trợ khẩn cấp tại công trường.';
    }
  }

  @override
  void dispose() {
    _gpsRun++;
    _description.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    if (_attempt != null || _locating) return;
    final run = ++_gpsRun;
    setState(() {
      _locating = true;
      _gpsNote = null;
    });
    try {
      final point = await (widget.location ?? LocationService())
          .currentPosition();
      if (mounted && run == _gpsRun && _attempt == null) {
        setState(() => _position = point);
      }
    } on LocationFailure catch (e) {
      if (mounted && run == _gpsRun) {
        setState(
          () => _gpsNote =
              'Chưa đính kèm GPS: ${e.message} Bạn vẫn có thể gửi báo cáo.',
        );
      }
    } finally {
      if (mounted && run == _gpsRun) setState(() => _locating = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _locating || !_form.currentState!.validate()) return;
    _attempt ??= {
      'type': _type,
      'description': _description.text.trim(),
      'clientRequestId': _id,
      if (_position != null) 'latitude': _position!.latitude,
      if (_position != null) 'longitude': _position!.longitude,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final detail = await widget.api.reportIncident(widget.job.id, _attempt!);
      if (mounted) Navigator.pop(context, detail);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        _type == 'SOS' ? 'Gửi SOS tới Admin' : 'Báo cáo sự cố / tranh chấp',
      ),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.job.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Báo cáo được gửi riêng tới Admin. Bạn theo dõi phản hồi trong Sự cố đã gửi.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Loại báo cáo'),
                items: ['SOS', 'SAFETY', 'PAYMENT_DISPUTE', 'OTHER']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(incidentType(t)),
                      ),
                    )
                    .toList(),
                onChanged: _busy || _attempt != null
                    ? null
                    : (t) => setState(() => _type = t!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                enabled: !_busy && _attempt == null,
                maxLength: 2000,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Tình huống và hỗ trợ cần thiết',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Nhập tình huống cần Admin hỗ trợ'
                    : null,
              ),
              const SizedBox(height: 8),
              if (_position != null)
                Text(
                  'GPS đính kèm: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                ),
              if (_gpsNote != null) Text(_gpsNote!),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy || _locating || _attempt != null
                        ? null
                        : _locate,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _locating ? 'Đang lấy GPS…' : 'Đính kèm GPS (tùy chọn)',
                    ),
                  ),
                  if (_locating || _position != null)
                    TextButton(
                      onPressed: _attempt != null
                          ? null
                          : () {
                              ++_gpsRun;
                              setState(() {
                                _locating = false;
                                _position = null;
                              });
                            },
                      child: const Text('Gửi không kèm GPS'),
                    ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Quay lại'),
        ),
        FilledButton.icon(
          onPressed: _busy || _locating ? null : _send,
          style: _type == 'SOS'
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          icon: Icon(_type == 'SOS' ? Icons.sos : Icons.send_outlined),
          label: Text(_type == 'SOS' ? 'Xác nhận gửi SOS' : 'Gửi báo cáo'),
        ),
      ],
    ),
  );
}
