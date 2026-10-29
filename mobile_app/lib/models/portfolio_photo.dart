class PortfolioPhoto {
  const PortfolioPhoto({required this.id, required this.caption});
  final String id, caption;
  factory PortfolioPhoto.fromJson(Map<String, dynamic> j) => PortfolioPhoto(
    id: j['id'] as String,
    caption: j['caption'] as String? ?? '',
  );
  String get path => '/api/portfolio/photos/$id';
}
