import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class AppFile {
  final String path;
  final String name;
  final int size;
  
  bool get isPdf => name.toLowerCase().endsWith('.pdf');
  
  AppFile({
    required this.path,
    required this.name,
    required this.size,
  });
}

class DocumentProvider with ChangeNotifier {
  List<AppFile> _selectedFiles = [];
  bool _isUploading = false;
  String? _uploadError;

  List<AppFile> get selectedFiles => _selectedFiles;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;

  final int _maxFileSize = 10 * 1024 * 1024; // 10MB

  void _addFiles(List<AppFile> files) {
    for (var file in files) {
      if (file.size <= _maxFileSize) {
        // Prevent duplicates
        if (!_selectedFiles.any((f) => f.path == file.path)) {
          _selectedFiles.add(file);
        }
      } else {
        _uploadError = 'Some files exceeded the 10MB limit and were not added.';
      }
    }
    notifyListeners();
  }

  Future<void> pickFiles() async {
    _uploadError = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        List<AppFile> newFiles = result.files
            .where((f) => f.path != null)
            .map((f) => AppFile(path: f.path!, name: f.name, size: f.size))
            .toList();
        _addFiles(newFiles);
      }
    } catch (e) {
      _uploadError = 'Error picking files: $e';
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    _uploadError = null;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      
      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final size = await file.length();
        final appFile = AppFile(
          path: pickedFile.path, 
          name: pickedFile.name, 
          size: size,
        );
        _addFiles([appFile]);
      }
    } catch (e) {
      _uploadError = 'Error taking photo: $e';
      notifyListeners();
    }
  }

  void removeFile(int index) {
    _selectedFiles.removeAt(index);
    notifyListeners();
  }

  void clearError() {
    _uploadError = null;
    notifyListeners();
  }

  // Upload to API
  Future<String?> uploadDocuments() async {
    if (_selectedFiles.isEmpty) return null;

    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      // Simulate API call to /upload-docs
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulate successful upload and getting docId
      String dummyDocId = "DOC_${DateTime.now().millisecondsSinceEpoch}";
      
      _isUploading = false;
      notifyListeners();
      
      return dummyDocId;
    } catch (e) {
      _uploadError = 'Failed to upload documents. Please try again.';
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }
}
