import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'jobs_map.dart';
import 'osm_map_view.dart';

class JobMapPreview extends StatefulWidget {
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
  State<JobMapPreview> createState() => _JobMapPreviewState();
}

class _JobMapPreviewState extends State<JobMapPreview> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final job =
        widget.jobs.where((j) => j.id == _selected).firstOrNull ??
        widget.jobs.firstOrNull;
    return Container(
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
            height: 232,
            child: JobsMap(
              center: widget.center,
              jobs: widget.jobs.take(3).toList(),
              onJobTap: (job) => setState(() => _selected = job.id),
              interactive: false,
            ),
          ),
          if (job != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Material(
                color: AppPalette.of(context).surface,
                child: InkWell(
                  onTap: () => widget.onJobTap(job),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apartment_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gần bạn · ${job.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${money(job.salaryPerDay)}/ngày',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4, bottom: 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Vòng 200m quanh công trình',
                    style: TextStyle(fontSize: 10, color: Color(0xff64748b)),
                  ),
                ),
                if (widget.onExpand != null)
                  TextButton.icon(
                    onPressed: widget.onExpand,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Xem bản đồ'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
