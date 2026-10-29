import '../models/models.dart';

abstract final class JobLinks {
  static Uri share(int id) =>
      Uri.https('thoxay.vercel.app', '/', {'job': '$id'});
  static int? parse(Uri uri) {
    final value = int.tryParse(uri.queryParameters['job'] ?? '');
    return value != null && value > 0 ? value : null;
  }

  static Uri directions(Job job) => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${job.latitude},${job.longitude}',
    'travelmode': 'driving',
  });
}
