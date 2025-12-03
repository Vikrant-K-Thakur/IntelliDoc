// screens/folder_view.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docuverse/shared/models/folder_model.dart';
import 'package:docuverse/shared/models/file_model.dart';
import 'package:docuverse/features/documents/services/file_storage_service.dart';
// import 'package:docuverse/constants/app_constants.dart';
// import 'package:docuverse/services/auth_service.dart';
import 'package:docuverse/shared/utils/file_utils.dart';
import 'package:docuverse/features/documents/widgets/file_management_dialog.dart';
import 'package:docuverse/screens/document_viewer.dart';

class FolderViewScreen extends StatefulWidget {
  final FolderModel folder;
  
  const FolderViewScreen({super.key, required this.folder});

  @override
  State<FolderViewScreen> createState() => _FolderViewScreenState();
}

class _FolderViewScreenState extends State<FolderViewScreen> {
  List<FileModel> folderFiles = [];
  List<FolderModel> subfolders = [];
  List<FileModel> filteredFiles = [];
  List<FolderModel> filteredSubfolders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFolderContent();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterContent();
    });
  }

  void _filterContent() {
    if (_searchQuery.isEmpty) {
      filteredFiles = List.from(folderFiles);
      filteredSubfolders = List.from(subfolders);
    } else {
      filteredFiles = folderFiles.where((file) {
        return file.name.toLowerCase().contains(_searchQuery) ||
               file.type.toLowerCase().contains(_searchQuery);
      }).toList();
      
      filteredSubfolders = subfolders.where((folder) {
        return folder.name.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadFolderContent() async {
    final files = await FileStorageService.getFilesInFolder(widget.folder.id);
    final folders = await FileStorageService.getSubfolders(widget.folder.id);
    setState(() {
      folderFiles = files;
      subfolders = folders;
      _filterContent();
    });
  }

  Future<void> _addFilesToFolder() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        List<FileModel> newFiles = [];
        
        for (var file in result.files) {
          final fileModel = FileModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + file.name.hashCode.toString(),
            name: file.name,
            path: file.path ?? '',
            type: file.extension ?? '',
            size: file.size,
            uploadedAt: DateTime.now(),
            folderId: widget.folder.id,
          );
          newFiles.add(fileModel);
        }
        
        await FileStorageService.addFiles(newFiles);
        await FileStorageService.updateFolderFileCount(widget.folder.id);
        _loadFolderContent();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.length} file(s) added to folder'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add files'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    return FileUtils.getFileIcon(fileName);
  }



  void _showFileManagement(FileModel file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FileManagementDialog(
        file: file,
        onFileUpdated: _loadFolderContent,
      ),
    );
  }

  void _createSubfolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            onChanged: (value) => folderName = value,
            decoration: const InputDecoration(
              hintText: 'Enter folder name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (folderName.isNotEmpty) {
                  final newFolder = FolderModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: folderName,
                    createdAt: DateTime.now(),
                    parentFolderId: widget.folder.id,
                  );
                  
                  await FileStorageService.addFolder(newFolder);
                  _loadFolderContent();
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.folder.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_files') {
                _addFilesToFolder();
              } else if (value == 'new_folder') {
                _createSubfolder();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_files',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('Add Files'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new_folder',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder),
                    SizedBox(width: 8),
                    Text('New Folder'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (folderFiles.isNotEmpty || subfolders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.folder.name}...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          // Content
          Expanded(
            child: (folderFiles.isEmpty && subfolders.isEmpty)
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Folder is empty',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use menu to add files or folders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Search Results Info
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Found ${filteredSubfolders.length} folders and ${filteredFiles.length} files',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Content List
                Expanded(
                  child: (filteredFiles.isEmpty && filteredSubfolders.isEmpty && _searchQuery.isNotEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try searching with different keywords',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredSubfolders.length + filteredFiles.length,
                          itemBuilder: (context, index) {
                if (index < filteredSubfolders.length) {
                  final folder = filteredSubfolders[index];
                  return Column(
                    children: [
                      DragTarget<Map<String, dynamic>>(
                        onAccept: (data) => _handleDrop(data, folder.id),
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            decoration: BoxDecoration(
                              border: candidateData.isNotEmpty 
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Dismissible(
                              key: Key(folder.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                _deleteSubfolder(folder);
                                return false;
                              },
                              child: Draggable<Map<String, dynamic>>(
                                data: {'type': 'folder', 'id': folder.id},
                                feedback: Material(
                                  elevation: 4,
                                  child: Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.folder, size: 16, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            folder.name,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.5,
                                  child: _buildSubfolderItem(folder, onRename: () => _renameSubfolder(folder)),
                                ),
                                child: _buildSubfolderItem(folder, onRename: () => _renameSubfolder(folder)),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                } else {
                  final file = filteredFiles[index - filteredSubfolders.length];
                  return Column(
                    children: [
                      Draggable<Map<String, dynamic>>(
                        data: {'type': 'file', 'id': file.id},
                        feedback: Material(
                          elevation: 4,
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getFileIcon(file.name), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildFileItem(file, onManage: () => _showFileManagement(file)),
                        ),
                        child: _buildFileItem(file, onManage: () => _showFileManagement(file)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(FileModel file, {VoidCallback? onManage}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentViewerScreen(file: file),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getFileIcon(file.name), size: 28, color: FileUtils.getFileColor(file.name)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    file.typeWithDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onManage != null)
                  GestureDetector(
                    onTap: onManage,
                    child: Icon(Icons.more_vert, size: 24, color: Colors.grey[600]),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await FileStorageService.toggleFileStar(file.id);
                    _loadFolderContent();
                  },
                  child: Icon(
                    file.isStarred ? Icons.star : Icons.star_border,
                    size: 24,
                    color: file.isStarred ? Colors.amber : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSubfolderMoreOptions(FolderModel folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.summarize, size: 24, color: Colors.blue),
              title: const Text('Summarize Documents'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Summarize feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz, size: 24, color: Colors.green),
              title: const Text('Generate Quiz'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quiz generation coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school, size: 24, color: Colors.purple),
              title: const Text('Study Plan'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Study plan feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, size: 24, color: Colors.orange),
              title: const Text('Share Folder'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, size: 24, color: Colors.red),
              title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSubfolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubfolderItem(FolderModel folder, {VoidCallback? onRename}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderViewScreen(folder: folder),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.folder, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    folder.documentCount,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    await FileStorageService.toggleFolderStar(folder.id);
                    _loadFolderContent();
                  },
                  child: Icon(
                    folder.isStarred ? Icons.star : Icons.star_border,
                    size: 24,
                    color: folder.isStarred ? Colors.amber : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _renameSubfolder(folder);
                  },
                  child: Icon(Icons.edit, size: 24, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _showSubfolderMoreOptions(folder);
                  },
                  child: Icon(Icons.more_vert, size: 24, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FolderViewScreen(folder: folder),
                      ),
                    );
                  },
                  child: Icon(Icons.folder_open, size: 24, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDrop(Map<String, dynamic> data, String targetFolderId) async {
    if (data['type'] == 'file') {
      await FileStorageService.moveFileToFolder(data['id'], targetFolderId);
      await FileStorageService.updateFolderFileCount(widget.folder.id);
      await FileStorageService.updateFolderFileCount(targetFolderId);
      _loadFolderContent();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File moved to folder'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (data['type'] == 'folder') {
      String sourceFolderId = data['id'];
      if (sourceFolderId != targetFolderId) {
        await FileStorageService.moveFolderToFolder(sourceFolderId, targetFolderId);
        _loadFolderContent();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder moved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deleteSubfolder(FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Are you sure you want to delete "${folder.name}" and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FileStorageService.deleteFolder(folder.id);
              _loadFolderContent();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Folder deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameSubfolder(FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = folder.name;
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: TextEditingController(text: folder.name),
            onChanged: (value) => newName = value,
            decoration: const InputDecoration(
              hintText: 'Enter new folder name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (newName.isNotEmpty && newName != folder.name) {
                  await FileStorageService.renameFolder(folder.id, newName);
                  _loadFolderContent();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Folder renamed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }
}