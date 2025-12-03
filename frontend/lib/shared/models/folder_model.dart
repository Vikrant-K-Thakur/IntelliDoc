class FolderModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> fileIds;
  final String? parentFolderId;
  final bool isStarred;

  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.fileIds = const [],
    this.parentFolderId,
    this.isStarred = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'fileIds': fileIds,
      'parentFolderId': parentFolderId,
      'isStarred': isStarred,
    };
  }

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      fileIds: List<String>.from(json['fileIds'] ?? []),
      parentFolderId: json['parentFolderId'],
      isStarred: (json['isStarred'] as bool?) ?? false,
    );
  }

  String get documentCount => '${fileIds.length} Documents';

  FolderModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<String>? fileIds,
    String? parentFolderId,
    bool? isStarred,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      fileIds: fileIds ?? this.fileIds,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}