
import 'package:myapp/models/file.dart';

class Torrent {
  final int id;
  final String hash;
  final String name;
  final int size;
  final String downloadState;
  final double progress;
  final bool active;
  final bool downloadFinished;
  final List<File> files;

  Torrent({
    required this.id,
    required this.hash,
    required this.name,
    required this.size,
    required this.downloadState,
    required this.progress,
    required this.active,
    required this.downloadFinished,
    required this.files,
  });

  factory Torrent.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List? ?? [];
    List<File> files = filesList.map((i) => File.fromJson(i)).toList();

    return Torrent(
      id: json['id'] as int? ?? 0,
      hash: json['hash'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      downloadState: json['download_state'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      active: json['active'] as bool? ?? false,
      downloadFinished: json['download_finished'] as bool? ?? false,
      files: files,
    );
  }
}
