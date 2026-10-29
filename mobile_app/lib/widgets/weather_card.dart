import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/weather.dart';
import '../services/api_service.dart';
import 'loading_jobs.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({
    super.key,
    required this.api,
    required this.latitude,
    required this.longitude,
    required this.areaLabel,
    this.refreshToken,
  });
  final ApiService api;
  final double latitude, longitude;
  final String areaLabel;
  final Object? refreshToken;
  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> with WidgetsBindingObserver {
  AreaWeather? _weather;
  bool _loading = true, _foreground = true, _expanded = false;
  int _generation = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _timer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_foreground && (ModalRoute.of(context)?.isCurrent ?? true)) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && (ModalRoute.of(context)?.isCurrent ?? true)) _load();
  }

  @override
  void didUpdateWidget(covariant WeatherCard old) {
    super.didUpdateWidget(old);
    if ((old.latitude * 100).round() != (widget.latitude * 100).round() ||
        (old.longitude * 100).round() != (widget.longitude * 100).round() ||
        old.refreshToken != widget.refreshToken) {
      _weather = null;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() => _loading = true);
    AreaWeather? result;
    try {
      result = await widget.api.weather(widget.latitude, widget.longitude);
    } on ApiException {
      /* Jobs remain usable. */
    }
    if (mounted && generation == _generation) {
      setState(() {
        _weather = result;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), weather = _weather;
    if (_loading) {
      return const ShimmerSurface(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonLine(height: 64),
        ),
      );
    }
    if (weather == null || !weather.available || weather.temperature == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text(
            widget.areaLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text('Thời tiết tạm chưa có dữ liệu'),
          trailing: IconButton(
            tooltip: 'Tải lại thời tiết',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ),
      );
    }
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(
              weather.storm
                  ? Icons.thunderstorm_outlined
                  : weather.wet
                  ? Icons.umbrella_outlined
                  : weather.isDay
                  ? Icons.wb_sunny_outlined
                  : Icons.nightlight_outlined,
              color: weather.storm
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            title: Text(
              '${weather.temperature!.round()}°C · ${weather.label}',
              style: theme.textTheme.titleMedium,
            ),
            subtitle: Text(
              '${widget.areaLabel}${weather.stale ? ' · Dữ liệu lưu gần nhất' : ''}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              weather.advice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: weather.storm ? theme.colorScheme.error : null,
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cảm giác ${weather.apparent?.round()}°C · Gió ${weather.wind?.toStringAsFixed(1)} km/h · Mưa ${weather.rain?.toStringAsFixed(1)} mm',
                  ),
                  if (weather.observedAt != null)
                    Text(
                      'Dữ liệu lúc ${_time(weather.observedAt!)} (giờ thiết bị)',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dữ liệu mô hình thời tiết khu vực, dùng để tham khảo.',
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _source,
                    child: const Text('Thời tiết: Open-Meteo · CC BY 4.0'),
                  ),
                ),
                IconButton(
                  tooltip: 'Tải lại thời tiết',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime date) {
    final value = date.toLocal();
    return '${value.day}/${value.month} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _source() async {
    try {
      await launchUrl(
        Uri.https('open-meteo.com', '/'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      /* Link is optional. */
    }
  }
}
