import 'package:flutter/material.dart';
import 'package:docuverse/shared/models/file_model.dart';
import 'package:docuverse/screens/summary_chat_screen.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';

class DocumentViewerScreen extends StatefulWidget {
  final FileModel file;

  const DocumentViewerScreen({super.key, required this.file});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      if (widget.file.type.toLowerCase() == 'pdf') {
        if (widget.file.path.isNotEmpty && File(widget.file.path).existsSync()) {
          _pdfController = PdfController(
            document: PdfDocument.openFile(widget.file.path),
          );
        } else {
          setState(() {
            _error = 'PDF file not found';
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading document: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildPdfViewer() {
    if (_pdfController == null) {
      return const Center(
        child: Text('Unable to load PDF'),
      );
    }

    return PdfView(
      controller: _pdfController!,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (document) {
        // Document loaded successfully
      },
      onPageChanged: (page) {
        // Page changed
      },
    );
  }

  Widget _buildUnsupportedFormat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            widget.file.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'File Type: ${widget.file.extension}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Size: ${widget.file.formattedSize}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preview not available for this file type',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement external app opening
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('External app opening coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open with External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer() {
    if (widget.file.path.isEmpty || !File(widget.file.path).existsSync()) {
      return const Center(
        child: Text('Image file not found'),
      );
    }

    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          File(widget.file.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text('Error loading image'),
            );
          },
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'generate_summary':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryChatScreen(file: widget.file),
          ),
        );
        break;
      case 'generate_quiz':
        _showAIFeatureDialog('Generate Quiz',
          'AI will create interactive quiz questions based on the document content to test your understanding.',
          Icons.quiz, Colors.green);
        break;
      case 'ask_question':
        _showAIFeatureDialog('Ask Questions',
          'Ask any questions about the document content and get AI-powered answers.',
          Icons.chat_bubble_outline, Colors.purple);
        break;
      case 'create_flashcards':
        _showAIFeatureDialog('Create Flashcards',
          'AI will generate flashcards from key concepts in your document for effective studying.',
          Icons.style, Colors.orange);
        break;
      case 'bookmark':
        _showFeatureDialog('Add Bookmark', 'Bookmark this page for quick access later.');
        break;
      case 'highlight':
        _showFeatureDialog('Highlight Text', 'Select and highlight important text in the document.');
        break;
      case 'annotate':
        _showFeatureDialog('Add Annotation', 'Add notes and comments to specific parts of the document.');
        break;
      case 'print':
        _showFeatureDialog('Print Document', 'Send document to printer or save as PDF.');
        break;
      case 'properties':
        _showPropertiesDialog();
        break;
    }
  }



  void _showAIFeatureDialog(String title, String description, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI-powered feature - Premium subscription required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title feature coming soon!'),
                  backgroundColor: color,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Try Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPropertiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Text('Document Properties'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyRow('Name', widget.file.name),
            _buildPropertyRow('Type', widget.file.extension),
            _buildPropertyRow('Size', widget.file.formattedSize),
            _buildPropertyRow('Created', '${widget.file.uploadedAt.day}/${widget.file.uploadedAt.month}/${widget.file.uploadedAt.year}'),
            _buildPropertyRow('Location', widget.file.path.isNotEmpty ? widget.file.path : 'Cloud Storage'),
            if (widget.file.type.toLowerCase() == 'pdf' && _pdfController != null)
              FutureBuilder<PdfDocument>(
                future: _pdfController!.document,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildPropertyRow('Pages', '${snapshot.data!.pagesCount}');
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDocument();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final fileType = widget.file.type.toLowerCase();
    
    if (fileType == 'pdf') {
      return _buildPdfViewer();
    } else if (['jpg', 'jpeg', 'png', 'gif', 'bmp'].contains(fileType)) {
      return _buildImageViewer();
    } else {
      return _buildUnsupportedFormat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.file.name,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _showShareDialog();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              // AI Features
              const PopupMenuItem(
                value: 'generate_summary',
                child: Row(
                  children: [
                    Icon(Icons.summarize, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Generate Summary'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'generate_quiz',
                child: Row(
                  children: [
                    Icon(Icons.quiz, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Generate Quiz'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ask_question',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.purple),
                    SizedBox(width: 12),
                    Text('Ask Questions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_flashcards',
                child: Row(
                  children: [
                    Icon(Icons.style, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Create Flashcards'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // Document Tools
              const PopupMenuItem(
                value: 'bookmark',
                child: Row(
                  children: [
                    Icon(Icons.bookmark_add, color: Colors.indigo),
                    SizedBox(width: 12),
                    Text('Add Bookmark'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'annotate',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, color: Colors.teal),
                    SizedBox(width: 12),
                    Text('Add Annotation'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              // File Operations
              const PopupMenuItem(
                value: 'properties',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Properties'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildDocumentContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _showQuickActionsBottomSheet(),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.auto_awesome, color: Colors.white),
    );
  }

  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'AI Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Summary',
                    Icons.summarize,
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SummaryChatScreen(file: widget.file),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Quiz',
                    Icons.quiz,
                    Colors.green,
                    () => _handleMenuSelection('generate_quiz'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'Ask AI',
                    Icons.chat_bubble_outline,
                    Colors.purple,
                    () => _handleMenuSelection('ask_question'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'Flashcards',
                    Icons.style,
                    Colors.orange,
                    () => _handleMenuSelection('create_flashcards'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.share, color: Colors.blue),
            SizedBox(width: 12),
            Text('Share Document'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text('Copy Link'),
              subtitle: const Text('Share via link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: const Text('Email'),
              subtitle: const Text('Send via email'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email sharing coming soon!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.green),
              title: const Text('Collaborate'),
              subtitle: const Text('Invite others to view'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Collaboration feature coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}