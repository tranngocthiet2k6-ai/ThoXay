import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import 'weather_card.dart';

class JobWeatherPanel extends StatelessWidget {
  const JobWeatherPanel({
    super.key,
    required this.api,
    required this.jobs,
    required this.selected,
    required this.onChanged,
    this.refreshToken,
  });
  final ApiService api;
  final List<Job> jobs;
  final Job selected;
  final ValueChanged<Job> onChanged;
  final Object? refreshToken;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Thời tiết công trình',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const ValueKey('choose-weather-job'),
        icon: const Icon(Icons.search),
        label: const Text('Chọn / tìm công trình'),
        onPressed: () async {
          final job = await showSearch<Job?>(
            context: context,
            delegate: _WeatherJobSearch(jobs),
          );
          if (context.mounted && job != null) onChanged(job);
        },
      ),
      const SizedBox(height: 8),
      WeatherCard(
        api: api,
        latitude: selected.latitude,
        longitude: selected.longitude,
        areaLabel: '${selected.title} · ${selected.address}',
        refreshToken: refreshToken,
      ),
    ],
  );
}

class _WeatherJobSearch extends SearchDelegate<Job?> {
  _WeatherJobSearch(this.jobs)
    : super(searchFieldLabel: 'Tên công trình hoặc địa chỉ');
  final List<Job> jobs;
  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Xóa tìm kiếm',
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Quay lại',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final text = query.trim().toLowerCase();
    final matches = jobs
        .where(
          (job) => '${job.title} ${job.address}'.toLowerCase().contains(text),
        )
        .toList();
    if (matches.isEmpty) {
      return const Center(child: Text('Không tìm thấy công trình phù hợp'));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (_, index) {
        final job = matches[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(job.title),
          subtitle: Text(job.address),
          onTap: () => close(context, job),
        );
      },
    );
  }
}
