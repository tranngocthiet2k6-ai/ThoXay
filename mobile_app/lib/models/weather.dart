class AreaWeather {
  const AreaWeather({
    required this.available,
    required this.stale,
    this.temperature,
    this.apparent,
    this.code,
    this.rain,
    this.wind,
    this.isDay = true,
    this.observedAt,
  });
  final bool available, stale, isDay;
  final double? temperature, apparent, rain, wind;
  final int? code;
  final DateTime? observedAt;
  bool get storm => code != null && code! >= 95;
  bool get wet => code != null && code! >= 51 && code! <= 86 || (rain ?? 0) > 0;
  String get label => switch (code) {
    0 => isDay ? 'Trời quang, có nắng' : 'Trời quang',
    1 || 2 => 'Ít mây',
    3 => 'Nhiều mây',
    45 || 48 => 'Sương mù',
    51 || 53 || 55 || 56 || 57 => 'Mưa phùn',
    61 || 63 || 65 || 66 || 67 => 'Có mưa',
    71 || 73 || 75 || 77 || 85 || 86 => 'Có tuyết',
    80 || 81 || 82 => 'Mưa rào',
    95 || 96 || 97 || 99 => 'Có dông',
    _ => 'Điều kiện thời tiết',
  };
  String get advice => storm
      ? 'Có dông: cân nhắc hoãn công việc ngoài trời, trên cao.'
      : wet
      ? 'Mưa/ẩm ướt: chú ý bề mặt trơn và thiết bị điện.'
      : (wind ?? 0) >= 40
      ? 'Gió mạnh: kiểm tra điều kiện làm việc trên cao.'
      : (apparent ?? 0) >= 35
      ? 'Nắng nóng: bố trí nghỉ mát và nước uống.'
      : 'Tham khảo điều kiện thực tế trước khi sắp xếp công việc.';
  factory AreaWeather.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    return AreaWeather(
      available: json['available'] as bool,
      stale: json['stale'] as bool,
      temperature: (current?['temperature'] as num?)?.toDouble(),
      apparent: (current?['apparentTemperature'] as num?)?.toDouble(),
      code: (current?['weatherCode'] as num?)?.toInt(),
      rain: (current?['precipitation'] as num?)?.toDouble(),
      wind: (current?['windSpeed'] as num?)?.toDouble(),
      isDay: current?['isDay'] as bool? ?? true,
      observedAt: current?['observedAt'] == null
          ? null
          : DateTime.parse(current!['observedAt'] as String),
    );
  }
}
