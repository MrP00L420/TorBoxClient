class Torrent {
  final int id;
  final String hash;
  final String name;
  final int size;
  final String downloadState;
  final double progress;
  final bool active;
  final bool downloadFinished;

  Torrent({
    required this.id,
    required this.hash,
    required this.name,
    required this.size,
    required this.downloadState,
    required this.progress,
    required this.active,
    required this.downloadFinished,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    return Torrent(
      id: json['id'],
      hash: json['hash'],
      name: json['name'],
      size: json['size'],
      downloadState: json['download_state'],
      progress: json['progress']?.toDouble() ?? 0.0,
      active: json['active'] ?? false,
      downloadFinished: json['download_finished'] ?? false,
    );
  }
}
