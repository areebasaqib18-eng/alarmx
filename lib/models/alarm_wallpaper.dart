
class AlarmWallpaper {
  final String id;
  final String title;
  final String category;
  final String videoAsset;
  final String? thumbnailAsset;

  const AlarmWallpaper({
    required this.id,
    required this.title,
    required this.category,
    required this.videoAsset,
    this.thumbnailAsset,
  });
}

