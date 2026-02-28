
class File {
  final int id;
  final String md5;
  final String s3Path;
  final String name;
  final int size;
  final String mimetype;
  final String shortName;

  File({
    required this.id,
    required this.md5,
    required this.s3Path,
    required this.name,
    required this.size,
    required this.mimetype,
    required this.shortName,
  });

  factory File.fromJson(Map<String, dynamic> json) {
    return File(
      id: json['id'] as int? ?? 0,
      md5: json['md5'] as String? ?? '',
      s3Path: json['s3_path'] as String? ?? '',
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      mimetype: json['mimetype'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
    );
  }
}
