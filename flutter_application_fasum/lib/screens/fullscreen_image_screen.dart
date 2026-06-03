import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

class FullScreenImageScreen extends StatefulWidget {
  final String imageBase64;

  const FullScreenImageScreen({
    super.key,
    required this.imageBase64,
  });

  @override
  State<FullScreenImageScreen> createState() =>
      _FullScreenImageScreenState();
}

class _FullScreenImageScreenState
    extends State<FullScreenImageScreen> {
  late Uint8List imageBytes;

  @override
  void initState() {
    super.initState();
    imageBytes = base64Decode(widget.imageBase64);
  }

  /// Download untuk Flutter Web
  Future<void> downloadForWeb() async {
    try {
      final blob = html.Blob([imageBytes]);

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..download =
            'fasum_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..click();

      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download dimulai'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal download: $e'),
          ),
        );
      }
    }
  }

  /// Simpan ke galeri Android/iOS
  Future<void> saveToGallery() async {
    try {
      PermissionStatus status;

      status = await Permission.storage.request();

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin penyimpanan ditolak'),
            ),
          );
        }
        return;
      }

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name:
            'fasum_${DateTime.now().millisecondsSinceEpoch}',
      );

      bool success = false;

      if (result is Map) {
        success = result['isSuccess'] == true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Gambar berhasil disimpan'
                  : 'Gagal menyimpan gambar',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  /// Tombol download utama
  Future<void> downloadImage() async {
    if (kIsWeb) {
      await downloadForWeb();
    } else {
      await saveToGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: downloadImage,
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: downloadImage,
        child: const Icon(Icons.download),
      ),

      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}