import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _scannedImage;
  bool _isUploading = false;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Auto-launch scanner as soon as the screen is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _openScanner());
  }

  /// Copy file to persistent temp directory before scanner.close() deletes it
  Future<File> _persistFile(String sourcePath) async {
    final dir = await getTemporaryDirectory();
    final destPath =
        '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return File(sourcePath).copy(destPath);
  }

  Future<void> _openScanner() async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: true,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      if (result.images.isNotEmpty) {
        final saved = await _persistFile(result.images.first);
        setState(() => _scannedImage = saved);
        HapticFeedback.mediumImpact();
      }
      // If cancelled (no images), stays on the retry screen
    } catch (e) {
      _showError('Scanner error: $e');
    } finally {
      scanner.close();
    }
  }

  Future<void> _upload() async {
    if (_scannedImage == null) return;

    setState(() => _isUploading = true);

    try {
      await _apiService.uploadScan(processedFile: _scannedImage!);
      HapticFeedback.heavyImpact();

      if (!mounted) return;

      // Navigate to home (history), clear the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomeScreen(successMessage: 'Document uploaded successfully'),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _retake() {
    setState(() => _scannedImage = null);
    _openScanner();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _scannedImage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasImage ? 'Review Scan' : 'Scan Document'),
        // No back button — this is the root screen
        automaticallyImplyLeading: false,
      ),
      body: hasImage ? _buildPreview(theme) : _buildRetry(theme),
    );
  }

  /// Shown when scanner is cancelled — lets user try again
  Widget _buildRetry(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No document captured',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap below to open the scanner or\nimport from your gallery',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.document_scanner_rounded),
                label: const Text('Scan Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.file(
                  _scannedImage!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _retake,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isUploading ? 'Extracting data...' : 'Upload & Extract'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
