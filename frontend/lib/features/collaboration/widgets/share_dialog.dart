import 'package:flutter/material.dart';
import 'package:docuverse/services/collaboration_service.dart';
import 'package:docuverse/shared/models/models.dart';

class ShareDialog extends StatefulWidget {
  final String fileName;
  final String fileUrl;
  final String fileType;

  const ShareDialog({
    super.key,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
  });

  @override
  State<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<ShareDialog> {
  final CollaborationService _collaborationService = CollaborationService();
  List<UserModel> _selectedFriends = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Share File',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // File info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFileIcon(widget.fileType),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Select friends to share with:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // Friends list
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _collaborationService.getFriends(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No friends to share with.\nAdd friends first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final friend = snapshot.data![index];
                      final isSelected = _selectedFriends.contains(friend);
                      
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriends.add(friend);
                            } else {
                              _selectedFriends.remove(friend);
                            }
                          });
                        },
                        title: Text(friend.displayName),
                        subtitle: Text(friend.email),
                        secondary: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.blue,
                          child: Text(
                            friend.getInitials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFriends.isEmpty ? null : _shareFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Share with ${_selectedFriends.length} friend${_selectedFriends.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _shareFile() async {
    for (final friend in _selectedFriends) {
      try {
        // Create or get chat with friend
        final chatId = await _collaborationService.createOrGetChat(
          friend.id,
          friend.displayName,
        );
        
        // Send file message
        await _collaborationService.sendMessage(
          chatId,
          'Shared a file: ${widget.fileName}',
          type: MessageType.document,
          fileUrl: widget.fileUrl,
          fileName: widget.fileName,
          fileType: widget.fileType,
        );
      } catch (e) {
        print('Error sharing with ${friend.displayName}: $e');
      }
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File shared with ${_selectedFriends.length} friend${_selectedFriends.length == 1 ? '' : 's'}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}