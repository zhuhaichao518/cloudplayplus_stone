class Painting {
  String url;
  String title;
  String artist;
  String description;

  Painting({
    required this.url,
    required this.title,
    this.artist = "Unknown",
    this.description = "",
  });
}
