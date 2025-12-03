import 'dart:io';
import 'package:docuverse/shared/models/file_model.dart';
import 'package:docx_to_text/docx_to_text.dart';

class DocumentTextService {
  static Future<String> extractTextFromFile(FileModel file) async {
    try {
      print('Extracting text from file: ${file.name}, type: ${file.type}');
      print('File path: ${file.path}');
      print('File content available: ${file.content != null && file.content!.isNotEmpty}');
      
      final fileType = file.type.toLowerCase();
      
      // First priority: Check if file has content property (for uploaded files)
      if (file.content != null && file.content!.isNotEmpty) {
        print('Using file content property');
        return file.content!;
      }
      
      // Second priority: Try to read from file path if available
      if (file.path.isNotEmpty) {
        final fileObject = File(file.path);
        final fileExists = fileObject.existsSync();
        print('File exists at path: $fileExists');
        
        if (fileExists) {
          // Handle different file types
          if (fileType == 'txt' || fileType == 'text') {
            print('Reading text file from path');
            return await fileObject.readAsString();
          } else if (fileType == 'docx') {
            print('Extracting text from DOCX file');
            try {
              final bytes = await fileObject.readAsBytes();
              final text = docxToText(bytes);
              if (text.trim().isEmpty) {
                throw Exception('Extracted text is empty');
              }
              return text;
            } catch (e) {
              print('Failed to extract DOCX text: $e');
              throw Exception('Unable to process DOCX file: $e');
            }
          } else if (fileType == 'pdf') {
            print('PDF files require additional processing');
            throw Exception('PDF extraction not yet implemented');
          } else {
            // For other file types, try to read as text
            try {
              print('Attempting to read file as plain text');
              return await fileObject.readAsString();
            } catch (e) {
              print('Failed to read file as text: $e');
              throw Exception('Unsupported file type: $fileType');
            }
          }
        } else {
          throw Exception('File not found at path: ${file.path}');
        }
      }
      
      throw Exception('No file content or valid path available');
      
    } catch (e) {
      print('Error in extractTextFromFile: $e');
      rethrow;  // Propagate the error instead of falling back to sample text
    }
  }

  // Keep this for testing purposes but don't use it as a fallback
  static String _getSampleText(String fileName) {
    return '''[Sample text content...]''';
  }
  
  static Future<bool> validateTextContent(String text) async {
    if (text.trim().isEmpty) {
      return false;
    }
    
    final wordCount = text.split(RegExp(r'\s+')).length;
    print('Text validation - Word count: $wordCount');
    
    return wordCount >= 20;
  }
}