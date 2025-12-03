import 'package:flutter/material.dart';

class FileUtils {
  static IconData getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  static Color getFileColor(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green;
      case 'txt':
        return Colors.grey;
      case 'xls':
      case 'xlsx':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static bool isImageFile(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static bool isDocumentFile(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    return ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension);
  }

  static bool isPresentationFile(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    return ['ppt', 'pptx', 'odp'].contains(extension);
  }

  static String getFileCategory(String fileName) {
    if (isImageFile(fileName)) return 'Image';
    if (isDocumentFile(fileName)) return 'Document';
    if (isPresentationFile(fileName)) return 'Presentation';
    return 'File';
  }
}