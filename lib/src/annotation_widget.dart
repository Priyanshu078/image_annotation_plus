import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_annotation_plus/image_annotation_plus.dart';

// ImageAnnotation class
class ImageAnnotation extends StatefulWidget {
  final String imagePath;
  final AnnotationType annotationType;
  final ImageSource imageSource;
  final Uint8List? imageBytes;

  const ImageAnnotation({
    super.key,
    required this.imagePath,
    required this.annotationType,
    required this.imageSource,
    this.imageBytes,
  });

  @override
  State<StatefulWidget> createState() => _ImageAnnotationState();
}

class _ImageAnnotationState extends State<ImageAnnotation> {
  // List of annotation points for different shapes
  List<List<Offset>> annotations = [];
  List<Offset> currentAnnotation = []; // Current annotation points
  List<TextAnnotation> textAnnotations = []; // List of text annotations
  Size? imageSize; // Size of the image
  Offset? imageOffset; // Offset of the image on the screen

  @override
  void initState() {
    super.initState();
    loadImageSize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateImageOffset();
    });
  }

  // Load image size asynchronously and set imageSize state
  void loadImageSize() async {
    final image = _getImage(widget.imageSource);
    final completer = Completer<ui.Image>();

    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );

    final loadedImage = await completer.future;
    setState(() {
      imageSize = _calculateImageSize(loadedImage);
    });
  }

  // Calculate the image size to fit the screen while maintaining the aspect ratio
  Size _calculateImageSize(ui.Image image) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final imageRatio = image.width / image.height;
    final screenRatio = screenWidth / screenHeight;

    double width;
    double height;

    if (imageRatio > screenRatio) {
      width = screenWidth;
      height = screenWidth / imageRatio;
    } else {
      height = screenHeight;
      width = screenHeight * imageRatio;
    }

    return Size(width, height);
  }

  // Calculate the offset of the image on the screen
  void _calculateImageOffset() {
    if (imageSize != null) {
      final imageWidget = context.findRenderObject() as RenderBox?;
      final imagePosition = imageWidget?.localToGlobal(Offset.zero);
      final widgetPosition = (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero);
      final offsetX = imagePosition!.dx - widgetPosition.dx;
      final offsetY = imagePosition.dy - widgetPosition.dy;
      setState(() {
        imageOffset = Offset(offsetX, offsetY);
      });
    }
  }

  // Start a new annotation
  void startNewAnnotation() {
    setState(() {
      currentAnnotation = [];
      annotations.add(currentAnnotation);
    });
  }

  // Draw shape based on the current position
  void drawShape(Offset position) {
    if (position.dx >= 0 && position.dy >= 0 && position.dx <= imageSize!.width && position.dy <= imageSize!.height) {
      setState(() {
        currentAnnotation.add(position);
      });
    }
  }

  // Add a text annotation to the list
  void addTextAnnotation(Offset position, String text, Color textColor, double fontSize) {
    setState(() {
      textAnnotations.add(TextAnnotation(
        position: position,
        text: text,
        textColor: textColor,
        fontSize: fontSize,
      ));
    });
  }

  // Clear the last added annotation
  void clearLastAnnotation() {
    setState(() {
      if (annotations.isNotEmpty) {
        annotations.removeLast();
      }
      if (textAnnotations.isNotEmpty) {
        textAnnotations.removeLast();
      }
    });
  }

  // Clear all annotations
  void clearAllAnnotations() {
    setState(() {
      annotations.clear();
      textAnnotations.clear();
      currentAnnotation = [];
    });
  }

  // Show a dialog to add text annotation
  void _showTextAnnotationDialog(BuildContext context, Offset localPosition) {
    String text = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Text Annotation'),
          content: TextField(
            onChanged: (value) {
              text = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (text.isNotEmpty) {
                  // Add the text annotation
                  addTextAnnotation(localPosition, text, Colors.black, 16.0);
                }
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  ImageProvider _getImage(ImageSource source) {
    if (source == ImageSource.network) {
      return Image.network(widget.imagePath).image;
    } else if (source == ImageSource.asset) {
      return Image.asset(widget.imagePath).image;
    } else {
      return Image.memory(widget.imageBytes ?? Uint8List(0)).image;
    }
  }

  // Build the widget
  @override
  Widget build(BuildContext context) {
    if (imageSize == null || imageOffset == null) {
      return const CircularProgressIndicator(); // Placeholder or loading indicator while the image size and offset are being retrieved
    }

    return GestureDetector(
      onLongPress: clearAllAnnotations,
      onDoubleTap: clearLastAnnotation,
      onTapDown: (details) {
        if (widget.annotationType == AnnotationType.text) {
          _showTextAnnotationDialog(context, details.localPosition);
        } else {
          startNewAnnotation();
        }
      },
      child: RepaintBoundary(
        child: Stack(
          children: [
            _getImageWidget(widget.imageSource),
            Positioned(
              left: imageOffset!.dx,
              top: imageOffset!.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  drawShape(details.localPosition);
                },
                child: CustomPaint(
                  painter: AnnotationPainter(
                    annotations: annotations,
                    textAnnotations: textAnnotations,
                    annotationType: widget.annotationType,
                  ),
                  size: imageSize!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getImageWidget(ImageSource source) {
    if (source == ImageSource.network) {
      return Image.network(
        widget.imagePath,
        width: imageSize!.width,
        height: imageSize!.height,
      );
    } else if (source == ImageSource.asset) {
      return Image.asset(
        widget.imagePath,
        width: imageSize!.width,
        height: imageSize!.height,
      );
    } else {
      return Image.memory(
        widget.imageBytes ?? Uint8List(0),
        width: imageSize!.width,
        height: imageSize!.height,
      );
    }
  }
}
