import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/satya_api_service.dart';

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

  // The last result returned from the Satya API
  SatyaResult? _lastResult;

  List<AppFile> get selectedFiles => _selectedFiles;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;
  SatyaResult? get lastResult => _lastResult;

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
      final picker = ImagePicker();
      final List<XFile>? result = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

      if (result != null && result.isNotEmpty) {
        List<AppFile> newFiles = [];
        for (var f in result) {
          final File file = File(f.path);
          final size = await file.length();
          newFiles.add(AppFile(path: f.path, name: f.name, size: size));
        }
        _addFiles(newFiles);
      }
    } catch (e) {
      _uploadError = 'Error picking images: $e';
      notifyListeners();
    }
  }

  Future<void> takePhoto() async {
    _uploadError = null;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1500,
        maxHeight: 1500,
      );

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

  void clearAll() {
    _selectedFiles = [];
    _lastResult = null;
    _uploadError = null;
    notifyListeners();
  }

  /// Upload documents to Satya Agent API and return the result data map
  /// for use in ResultScreen / history.
  ///
  /// Returns a [Map<String, dynamic>] compatible with ResultScreen on success.
  /// Returns null on failure (error is set in [uploadError]).
  Future<Map<String, dynamic>?> uploadDocuments() async {
    if (_selectedFiles.isEmpty) return null;

    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      // Convert AppFile list to File list (images only — API accepts images)
      final imageFiles = _selectedFiles
          .where((f) => !f.isPdf)
          .map((f) => File(f.path))
          .toList();

      if (imageFiles.isEmpty) {
        _uploadError = 'Please select at least one image file (JPG, PNG, etc.).\nPDF is not currently supported by the verification API.';
        _isUploading = false;
        notifyListeners();
        return null;
      }

      // Call the Satya Agent API
      final SatyaResult result;
      if (imageFiles.length == 1) {
        result = await SatyaApiService.verifySingleDocument(imageFiles.first);
      } else {
        result = await SatyaApiService.verifyMultipleDocuments(imageFiles);
      }

      _lastResult = result;
      _isUploading = false;
      notifyListeners();

      // Return result in a format compatible with ResultScreen
      return result.toResultScreenData();
    } on SatyaApiException catch (e) {
      _uploadError = e.message;
      _isUploading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _uploadError = 'Failed to verify documents. Please try again.\n$e';
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }
}
