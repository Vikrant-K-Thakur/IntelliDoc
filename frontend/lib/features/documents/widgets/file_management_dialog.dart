import 'package:flutter/material.dart';
import 'package:docuverse/shared/models/folder_model.dart';
import 'package:docuverse/shared/models/file_model.dart';
import 'package:docuverse/features/documents/services/file_storage_service.dart';
import 'package:docuverse/features/collaboration/widgets/share_dialog.dart';

class FileManagementDialog extends StatefulWidget {
  final FileModel file;
  final VoidCallback onFileUpdated;

  const FileManagementDialog({
    super.key,
    required this.file,
    required this.onFileUpdated,
  });

  @override
  State<FileManagementDialog> createState() => _FileManagementDialogState();
}

class _FileManagementDialogState extends State<FileManagementDialog> {
  Future<void> _deleteFile() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${widget.file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FileStorageService.deleteFile(widget.file.id);
              
              if (widget.file.folderId != null) {
                await FileStorageService.updateFolderFileCount(widget.file.folderId!);
              }
              
              widget.onFileUpdated();
              Navigator.pop(context);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File deleted successfully'),
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

  void _showMoveDialog() {
    showDialog(
      context: context,
      builder: (context) => _MoveFileDialog(
        file: widget.file,
        onFileUpdated: widget.onFileUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.summarize, size: 24, color: Colors.blue),
            title: const Text('Summarize Document'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document summarization coming soon')),
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
            leading: const Icon(Icons.translate, size: 24, color: Colors.orange),
            title: const Text('Translate Document'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Translation feature coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder, size: 24, color: Colors.indigo),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, size: 24, color: Colors.teal),
            title: const Text('Share Document'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => ShareDialog(
                  fileName: widget.file.name,
                  fileUrl: widget.file.path,
                  fileType: widget.file.name.split('.').last,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, size: 24, color: Colors.red),
            title: const Text('Delete Document', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteFile();
            },
          ),
        ],
      ),
    );
  }
}

class _MoveFileDialog extends StatefulWidget {
  final FileModel file;
  final VoidCallback onFileUpdated;

  const _MoveFileDialog({
    required this.file,
    required this.onFileUpdated,
  });

  @override
  State<_MoveFileDialog> createState() => _MoveFileDialogState();
}

class _MoveFileDialogState extends State<_MoveFileDialog> {
  List<FolderModel> folders = [];
  String? selectedFolderId;

  @override
  void initState() {
    super.initState();
    selectedFolderId = widget.file.folderId;
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final loadedFolders = await FileStorageService.getFolders();
    setState(() {
      folders = loadedFolders;
    });
  }

  Future<void> _moveFile() async {
    await FileStorageService.moveFileToFolder(widget.file.id, selectedFolderId);
    
    if (widget.file.folderId != null) {
      await FileStorageService.updateFolderFileCount(widget.file.folderId!);
    }
    if (selectedFolderId != null) {
      await FileStorageService.updateFolderFileCount(selectedFolderId!);
    }
    
    widget.onFileUpdated();
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File moved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Move "${widget.file.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedFolderId,
                hint: const Text('Select folder'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No folder (Root)'),
                  ),
                  ...folders.map((folder) => DropdownMenuItem<String?>(
                    value: folder.id,
                    child: Text(folder.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFolderId = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: selectedFolderId != widget.file.folderId ? _moveFile : null,
          child: const Text('Move'),
        ),
      ],
    );
  }
}