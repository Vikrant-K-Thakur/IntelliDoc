import 'package:flutter/material.dart';
import 'package:docuverse/shared/models/file_model.dart';
import 'package:docuverse/services/api_service.dart';
import 'package:docuverse/services/document_text_service.dart';

class SummaryChatScreen extends StatefulWidget {
  final FileModel file;

  const SummaryChatScreen({super.key, required this.file});

  @override
  State<SummaryChatScreen> createState() => _SummaryChatScreenState();
}

class _SummaryChatScreenState extends State<SummaryChatScreen> {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(
        text: "I'll analyze your document and create a summary for you...",
        isUser: false,
        isLoading: true,
      ));
    });

    try {
      print('Starting summary generation for file: ${widget.file.name}');
      
      final documentText = await DocumentTextService.extractTextFromFile(widget.file);
      print('Extracted text length: ${documentText.length}');
      
      // Validate text content
      final isValid = await DocumentTextService.validateTextContent(documentText);
      if (!isValid) {
        throw Exception('Document text is too short or empty for summarization');
      }
      
      final summary = await ApiService.generateSummary(documentText);
      print('Received summary length: ${summary.length}');
      
      setState(() {
        _messages.removeLast(); // Remove loading message
        _messages.add(ChatMessage(
          text: summary,
          isUser: false,
          isLoading: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _generateSummary: $e');
      
      String errorMessage;
      if (e.toString().contains('Backend server')) {
        errorMessage = "Backend server is not running. Please start the server and try again.";
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = "Cannot connect to the backend server. Please check if it's running on port 8000.";
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timed out')) {
        errorMessage = "Request timed out. The server may be busy processing. Please try again.";
      } else if (e.toString().contains('Empty summary')) {
        errorMessage = "The server returned an empty summary. This might be due to API configuration issues.";
      } else if (e.toString().contains('too short')) {
        errorMessage = "The document content is too short for meaningful summarization. Please upload a longer document.";
      } else {
        errorMessage = "Sorry, I couldn't generate a summary. Error: ${e.toString()}";
      }
      
      setState(() {
        _messages.removeLast(); // Remove loading message
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          isLoading: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Summary', style: TextStyle(fontSize: 18)),
            Text(
              widget.file.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing document...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: message.isError ? Colors.red[100] : Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.auto_awesome,
                size: 18,
                color: message.isError ? Colors.red[600] : Colors.blue[600],
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Generating summary...'),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.isUser && !message.isError)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.summarize, size: 14, color: Colors.blue[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'AI Summary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!message.isUser && !message.isError) const SizedBox(height: 8),
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isLoading;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isLoading = false,
    this.isError = false,
  });
}