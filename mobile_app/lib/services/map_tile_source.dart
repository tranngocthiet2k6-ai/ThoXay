import 'api_service.dart';

class MapTileSource {
  MapTileSource({
    required bool isWeb,
    String apiBaseUrl = ApiService.defaultBaseUrl,
    String configuredUrl = const String.fromEnvironment('MAP_TILE_URL'),
  }) : urlTemplate = configuredUrl.isNotEmpty
           ? configuredUrl
           : '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/map-tiles/{z}/{x}/{y}.png',
       headers = isWeb
           ? const {}
           : const {
               'User-Agent': 'ThoXay (vn.thoxay.tho_xay_mobile; https://thoxay.vercel.app)',
             };
  final String urlTemplate;
  final Map<String, String> headers;
}
