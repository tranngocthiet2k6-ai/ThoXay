import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'jobs_map.dart';
import 'osm_map_view.dart';

class JobMapPreview extends StatelessWidget {
  const JobMapPreview({
    super.key,
    required this.center,
    required this.jobs,
    required this.onJobTap,
    this.onExpand,
  });
  final GeoPoint center;
  final List<Job> jobs;
  final ValueChanged<Job> onJobTap;
  final VoidCallback? onExpand;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppPalette.of(context).surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppPalette.of(context).border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 164,
          child: JobsMap(
            center: center,
            jobs: jobs.take(3).toList(),
            onJobTap: onJobTap,
            interactive: false,
          ),
        ),
        if (onExpand != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onExpand,
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Xem bản đồ'),
            ),
          ),
      ],
    ),
  );
}

class JobLocationPin extends StatelessWidget {
  const JobLocationPin({
    super.key,
    required this.center,
    required this.selected,
    required this.onPicked,
  });
  final GeoPoint center;
  final GeoPoint? selected;
  final ValueChanged<GeoPoint>? onPicked;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 480,
    height: 180,
    child: OsmMapView(
      center: center,
      interactive: false,
      onTap: onPicked,
      markers: [
        if (selected != null)
          Marker(
            point: LatLng(selected!.latitude, selected!.longitude),
            width: 40,
            height: 48,
            child: Icon(
              Icons.location_on,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    ),
  );
}
