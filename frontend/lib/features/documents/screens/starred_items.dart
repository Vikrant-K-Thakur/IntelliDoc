import 'package:flutter/material.dart';
import '../../../shared/models/folder_model.dart';
import '../../../shared/models/file_model.dart';
import '../services/file_storage_service.dart';
import '../../../shared/utils/file_utils.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/constants/app_constants.dart';
import '../../auth/services/auth_service.dart';
import 'folder_view.dart';

class StarredItemsScreen extends StatefulWidget {
  const StarredItemsScreen({super.key});

  @override
  State<StarredItemsScreen> createState() => _StarredItemsScreenState();
}

class _StarredItemsScreenState extends State<StarredItemsScreen> {
  List<FolderModel> starredFolders = [];
  List<FileModel> starredFiles = [];

  @override
  void initState() {
    super.initState();
    _loadStarredItems();
  }

  Future<void> _loadStarredItems() async {
    final folders = await FileStorageService.getStarredFolders();
    final files = await FileStorageService.getStarredFiles();
    
    setState(() {
      starredFolders = folders;
      starredFiles = files;
    });
  }

  void _checkAuthAndNavigate(String route) {
    if (!AuthService.isLoggedIn) {
      _showLoginDialog();
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login first to preview the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Back Arrow Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const AppLogo(size: 32, showText: false),
                  const SizedBox(width: 12),
                  const Text(
                    'Starred Items',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: (starredFolders.isEmpty && starredFiles.isEmpty)
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_border,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 20),
                          Text(
                            'No starred items',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Star files and folders to see them here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: starredFolders.length + starredFiles.length,
                      itemBuilder: (context, index) {
                        if (index < starredFolders.length) {
                          final folder = starredFolders[index];
                          return Column(
                            children: [
                              _buildFolderItem(folder),
                              const SizedBox(height: 12),
                            ],
                          );
                        } else {
                          final file = starredFiles[index - starredFolders.length];
                          return Column(
                            children: [
                              _buildFileItem(file),
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
    );
  }

  Widget _buildFolderItem(FolderModel folder) {
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
            Icon(Icons.folder, size: 28, color: Colors.blue),
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
            GestureDetector(
              onTap: () async {
                await FileStorageService.toggleFolderStar(folder.id);
                _loadStarredItems();
              },
              child: Icon(
                Icons.star,
                size: 20,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(FileModel file) {
    return GestureDetector(
      onTap: () {
        _checkAuthAndNavigate(AppConstants.aiDocumentRoute);
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FileUtils.getFileIcon(file.name),
                size: 24,
                color: FileUtils.getFileColor(file.name),
              ),
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
            GestureDetector(
              onTap: () async {
                await FileStorageService.toggleFileStar(file.id);
                _loadStarredItems();
              },
              child: Icon(
                Icons.star,
                size: 20,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }
}