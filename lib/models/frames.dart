import 'dart:ui' as ui;

class FrameItem {
  final Duration duration;

  final ui.Image image;

  FrameItem({required this.image, required this.duration});

  int index = 0;

  Future<List<int>> getByteData() async {
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawUnmodified);
    image.dispose();
    return byteData!.buffer.asUint8List().toList(growable: false);
  }
}

class Frames {
  final List<FrameItem> frames = [];

  void add(FrameItem frameItem) {
    return frames.add(frameItem);
  }

  Stream<List<int>> imagesStream() {
    return Stream.fromFutures(frames.map((e) => e.getByteData()));
  }

  Future<List<List<int>>> waitForImages() {
    return Future.wait(frames.map((e) => e.getByteData()));
  }
}
