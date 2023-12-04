import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Editor App'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final pickedFile = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );

            if (pickedFile != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditorPage(imagePath: pickedFile.path),
                ),
              );
            }
          },
          child: Text('Select Image'),
        ),
      ),
    );
  }
}

class ImageEditorPage extends StatefulWidget {
  final String imagePath;

  const ImageEditorPage({required this.imagePath});

  @override
  _ImageEditorPageState createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late img.Image originalImage;
  late img.Image currentImage;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() {
    final file = File(widget.imagePath);
    final bytes = file.readAsBytesSync();
    originalImage = img.decodeImage(Uint8List.fromList(bytes))!;
    currentImage = img.copyResize(originalImage, width: originalImage.width, height: originalImage.height);
  }

  Future<void> applyFilter(void Function() filterFunction) async {
    await Future.microtask(() {
      filterFunction();
      setState(() {});
    });
  }

  void applyGrayscaleFilter() {
    applyFilter(() {
      currentImage = img.grayscale(currentImage);
    });
  }

  void applySepiaFilter() {
    applyFilter(() {
      currentImage = img.sepia(currentImage);
    });
  }

  void applyInvertFilter() {
    applyFilter(() {
      currentImage = img.invert(currentImage);
    });
  }

  void revertToOriginal() {
    applyFilter(() {
      currentImage = img.copyResize(originalImage, width: originalImage.width, height: originalImage.height);
    });
  }

  Future<void> cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      aspectRatioPresets: [CropAspectRatioPreset.square, CropAspectRatioPreset.ratio3x2, CropAspectRatioPreset.original],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        final file = File(croppedFile.path);
        final bytes = file.readAsBytesSync();
        currentImage = img.decodeImage(Uint8List.fromList(bytes))!;
      });
    }
  }

  void rotateImage() {
    // Rotate the image 90 degrees
    currentImage = img.copyRotate(currentImage, angle: 90);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Editor'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(
              Uint8List.fromList(img.encodePng(currentImage)),
              height: 200, // Adjust the height as needed
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => applyGrayscaleFilter(),
                  child: Text('Grayscale'),
                ),
                ElevatedButton(
                  onPressed: () => applySepiaFilter(),
                  child: Text('Sepia'),
                ),
                ElevatedButton(
                  onPressed: () => applyInvertFilter(),
                  child: Text('Invert'),
                ),
                ElevatedButton(
                  onPressed: () => revertToOriginal(),
                  child: Text('Revert to Original'),
                ),
                ElevatedButton(
                  onPressed: () => cropImage(),
                  child: Text('Crop'),
                ),
                ElevatedButton(
                  onPressed: () => rotateImage(),
                  child: Text('Rotate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}