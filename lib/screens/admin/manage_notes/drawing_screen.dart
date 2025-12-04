import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingScreen extends StatefulWidget {
  final Uint8List? initialImage;

  const DrawingScreen({super.key, this.initialImage});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  List<Map<String, dynamic>> strokes = [];
  ui.Image? backgroundImage;

  String selectedTool = "black"; // "black" or "white"

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    if (widget.initialImage == null) return;

    final codec = await ui.instantiateImageCodec(widget.initialImage!);
    final frame = await codec.getNextFrame();

    setState(() => backgroundImage = frame.image);
  }

  /// Save drawing as PNG
  Future<Uint8List> exportDrawing() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(800, 800);
    final rect = Offset.zero & size;

    // Transparent background
    canvas.drawRect(rect, Paint()..color = Colors.transparent);

    // Draw background image if exists
    if (backgroundImage != null) {
      canvas.drawImage(backgroundImage!, Offset.zero, Paint());
    }

    // Draw strokes
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke["color"]
        ..strokeWidth = stroke["size"]
        ..strokeCap = StrokeCap.round;

      final points = stroke["points"] as List<Offset?>;

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(800, 800);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void startStroke(Offset pos) {
    strokes.add({
      "color": selectedTool == "black" ? Colors.black : Colors.white,
      "size": selectedTool == "black" ? 4.0 : 20.0,
      "points": <Offset?>[pos],
    });
  }

  void addPoint(Offset pos) {
    (strokes.last["points"] as List<Offset?>).add(pos);
  }

  void endStroke() {
    (strokes.last["points"] as List<Offset?>).add(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drawing Editor"),
        actions: [
          // Black Pen Button
          IconButton(
            icon: Icon(Icons.brush,
                color: selectedTool == "black" ? Colors.blue : Colors.black87),
            tooltip: "Black Pen",
            onPressed: () => setState(() => selectedTool = "black"),
          ),

          // White Pen (eraser-like) Button
          IconButton(
            icon: Icon(Icons.cleaning_services,
                color: selectedTool == "white" ? Colors.blue : Colors.black87),
            tooltip: "White Pen (Eraser)",
            onPressed: () => setState(() => selectedTool = "white"),
          ),

          // Save Button
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              Navigator.pop(context, await exportDrawing());
            },
          ),
        ],
      ),

      body: GestureDetector(
        onPanStart: (d) => setState(() => startStroke(d.localPosition)),
        onPanUpdate: (d) => setState(() => addPoint(d.localPosition)),
        onPanEnd: (_) => setState(() => endStroke()),

        child: SizedBox.expand(
          child: CustomPaint(
            painter: _DrawingPainter(strokes: strokes, bg: backgroundImage),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;
  final ui.Image? bg;

  _DrawingPainter({required this.strokes, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Transparent background
    canvas.drawRect(rect, Paint()..color = Colors.transparent);

    // Draw background image
    if (bg != null) {
      canvas.drawImage(bg!, Offset.zero, Paint());
    }

    // Draw strokes
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke["color"]
        ..strokeWidth = stroke["size"]
        ..strokeCap = StrokeCap.round;

      final points = stroke["points"] as List<Offset?>;

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];

        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
