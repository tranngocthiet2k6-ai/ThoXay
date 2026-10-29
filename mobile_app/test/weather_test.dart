import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tho_xay_mobile/models/weather.dart';
import 'package:tho_xay_mobile/services/api_service.dart';
import 'package:tho_xay_mobile/widgets/weather_card.dart';

const _hot = AreaWeather(
  available: true,
  stale: false,
  temperature: 32,
  apparent: 37,
  code: 0,
  rain: 0,
  wind: 12,
);

class _WeatherApi extends ApiService {
  AreaWeather result = _hot;
  bool fail = false;
  final pending = <double, Completer<AreaWeather>>{};
  final points = <double>[];
  @override
  Future<AreaWeather> weather(double latitude, double longitude) async {
    points.add(latitude);
    if (pending.containsKey(latitude)) return pending[latitude]!.future;
    if (fail) throw const ApiException('offline');
    return result;
  }
}

Widget _card(_WeatherApi api, {double latitude = 10}) => MaterialApp(
  home: Scaffold(
    body: ListView(
      children: [
        WeatherCard(
          api: api,
          latitude: latitude,
          longitude: 106,
          areaLabel: 'Công trình A',
        ),
      ],
    ),
  ),
);
void main() {
  testWidgets(
    'weather shows real values, practical advisory, attribution and stale label',
    (tester) async {
      final api = _WeatherApi()
        ..result = const AreaWeather(
          available: true,
          stale: true,
          temperature: 29,
          apparent: 31,
          code: 97,
          rain: 5,
          wind: 20,
        );
      await tester.pumpWidget(_card(api));
      await tester.pumpAndSettle();
      expect(find.text('29°C · Có dông'), findsOneWidget);
      expect(find.textContaining('Dữ liệu lưu gần nhất'), findsOneWidget);
      expect(find.textContaining('cân nhắc hoãn'), findsOneWidget);
      expect(find.text('Thời tiết: Open-Meteo · CC BY 4.0'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'offline shows unavailable and retry recovers without fake zero values',
    (tester) async {
      final api = _WeatherApi()..fail = true;
      await tester.pumpWidget(_card(api));
      await tester.pumpAndSettle();
      expect(find.text('Thời tiết tạm chưa có dữ liệu'), findsOneWidget);
      expect(find.textContaining('0°C'), findsNothing);
      api.fail = false;
      await tester.tap(find.byTooltip('Tải lại thời tiết'));
      await tester.pumpAndSettle();
      expect(find.text('32°C · Trời quang, có nắng'), findsOneWidget);
      expect(find.textContaining('bố trí nghỉ mát'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
  testWidgets(
    'late response for a previous area never overwrites the selected area',
    (tester) async {
      final api = _WeatherApi();
      final old = Completer<AreaWeather>();
      api.pending[10] = old;
      await tester.pumpWidget(_card(api));
      await tester.pump();
      await tester.pumpWidget(_card(api, latitude: 11));
      await tester.pumpAndSettle();
      expect(api.points, [10, 11]);
      expect(find.textContaining('32°C'), findsOneWidget);
      old.complete(
        const AreaWeather(
          available: true,
          stale: false,
          temperature: 19,
          code: 3,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('19°C'), findsNothing);
      expect(find.textContaining('32°C'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.dispose();
    },
  );
}
