class FileModel {
  final String id;
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime uploadedAt;
  final String? folderId;
  final bool isStarred;
  final String? content;

  FileModel({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.uploadedAt,
    this.folderId,
    this.isStarred = false,
    this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
      'folderId': folderId,
      'isStarred': isStarred,
      'content': content,
    };
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
      folderId: json['folderId'],
      isStarred: (json['isStarred'] as bool?) ?? false,
      content: json['content'],
    );
  }

  String get extension => name.split('.').last.toUpperCase();
  
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get typeWithDate => '$extension • ${uploadedAt.toString().split(' ')[0]}';

  FileModel copyWith({
    String? id,
    String? name,
    String? path,
    String? type,
    int? size,
    DateTime? uploadedAt,
    String? folderId,
    bool? isStarred,
    String? content,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      folderId: folderId ?? this.folderId,
      isStarred: isStarred ?? this.isStarred,
      content: content ?? this.content,
    );
  }
}