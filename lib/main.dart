import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<Map<String, String>> imagePairs = [];

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> pickImages() async {
    try {
      final pickedImages = await ImagePicker().pickMultiImage();

      if (pickedImages.isNotEmpty) {
        List<Map<String, String>> tempImagePairs = [];

        for (final pickedImage in pickedImages) {
          final originalPath = pickedImage.path;
          final compressedPath = await compressImage(originalPath);

          tempImagePairs.add({
            'original': originalPath,
            'compressed': compressedPath,
          });
        }

        setState(() {
          imagePairs = tempImagePairs;
        });
      }
    } catch (e) {
      debugPrint('Error while picking images $e');
    }
  }

  Future<String> compressImage(String imagePath) async {
    int quality = 85;
    File? compressedImage;
    final dir = await getTemporaryDirectory();
    String targetPath;

    do {
      targetPath = path.join(
          dir.path, '${path.basenameWithoutExtension(imagePath)}_compressed_$quality.jpg');
      await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: quality,
      );
      compressedImage = File(targetPath);
      quality -= 5;
    } while (compressedImage.lengthSync() / 1024 > 10 && quality > 10);

    return compressedImage.path;
  }

  void fetchImages() {
    pickImages();
  }

  void openFullScreenImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Compression'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pickImages,
                child: const Text('Pick Images'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: imagePairs.length,
                  itemBuilder: (context, index) {
                    final originalPath = imagePairs[index]['original']!;
                    final compressedPath = imagePairs[index]['compressed']!;
                    final originalFile = File(originalPath);
                    final compressedFile = File(compressedPath);
                    final originalSize = originalFile.lengthSync() / 1024; // in KB
                    final compressedSize = compressedFile.lengthSync() / 1024; // in KB

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => openFullScreenImage(context, originalPath),
                          child: Column(
                            children: [
                              Image.file(
                                originalFile,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Text('Original: ${originalSize.toStringAsFixed(2)} KB'),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => openFullScreenImage(context, compressedPath),
                          child: Column(
                            children: [
                              Image.file(
                                compressedFile,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              Text('Compressed: ${compressedSize.toStringAsFixed(2)} KB'),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
