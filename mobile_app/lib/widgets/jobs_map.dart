import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import 'osm_map_view.dart';

class JobsMap extends StatelessWidget {
  const JobsMap({
    super.key,
    required this.center,
    required this.jobs,
    required this.onJobTap,
    this.tileProvider,
  });
  final GeoPoint center;
  final List<Job> jobs;
  final ValueChanged<Job> onJobTap;
  final TileProvider? tileProvider;
  @override
  Widget build(BuildContext context) => OsmMapView(
    center: center,
    tileProvider: tileProvider,
    fitPoints: jobs.map((j) => GeoPoint(j.latitude, j.longitude)).toList(),
    markers: [
      Marker(
        point: LatLng(center.latitude, center.longitude),
        width: 20,
        height: 20,
        child: Tooltip(
          message: 'Vị trí đang tìm',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ),
      for (final job in jobs)
        Marker(
          point: LatLng(job.latitude, job.longitude),
          width: 44,
          height: 44,
          alignment: Alignment.topCenter,
          child: Tooltip(
            message: '${job.title} · ${money(job.salaryPerDay)}/ngày',
            child: Semantics(
              button: true,
              label: 'Công trình ${job.title}',
              child: GestureDetector(
                key: ValueKey('job-marker-${job.id}'),
                onTap: () => onJobTap(job),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xff176b52),
                  size: 44,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
