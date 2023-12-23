import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_server/video_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;

import 'models/frames.dart';

const port = 52244;

final outputFormatsMap = {
  "x-matroska": "matroska",
  "png": "image2",
};

shelf_router.Router generateRouter(TestWidgetsFlutterBinding binding) {
  final router = shelf_router.Router();

  router.all('/', (req) => Response.ok("Healthy"));

  router.post('/renderImage', (Request req) async {
    final dataStr = await req.readAsString();
    final data = jsonDecode(dataStr);

    final encodedImage = data["encodedImage"] as String;
    final userHero = await decodeImageFromList(base64Decode(encodedImage));
    final useFrame = data["useFrame"] as bool;

    final out = await generateWidget(
      userHero: userHero,
      binding: binding,
      size: const Size(404, 720),
      renderSize: const Size(404, 720),
      outputFormat: "mp4",
      fps: 18,
      duration: const Duration(seconds: 10),
      useFrame: useFrame,
    );

    return Response.ok(out, headers: {"Content-Type": "video/mp4"});
  });
  return router;
}

Future<bool> loadFonts() async {
  try {
    final bytes = rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    var custom = FontLoader('Roboto');
    custom.addFont(bytes);
    await custom.load();
    fontsLoadCompleter.complete();
    return true;
  } catch (e, trace) {
    fontsLoadCompleter.completeError(e, trace);
    print("Failed Loading fonts");
    print(e);
    print(trace);
    return false;
  }
}

void main() async {
  final binding = AutomatedTestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  loadFonts();
  testWidgets("Server Runner", (tester) async {
    final router = generateRouter(binding);
    final server =
        await binding.runAsync(() => shelf_io.serve(router, 'localhost', port));
    if (server == null) {
      throw Exception("Could not start server");
    }
    server.idleTimeout = null;
    print("Running Server: ${server.address.address}:${server.port}");
    await Completer().future;
  }, timeout: Timeout.none);
}

final Completer<void> fontsLoadCompleter = Completer();

Future<ui.Image> getImage(String key) async {
  final byteData = await rootBundle.load(key);
  return decodeImageFromList(byteData.buffer.asUint8List());
}

Future<List<int>> generateWidget({
  required ui.Image? userHero,
  required TestWidgetsFlutterBinding binding,
  required Size size,
  required Size? renderSize,
  required String outputFormat,
  required int fps,
  required Duration duration,
  required bool useFrame,
}) async {
  renderSize ??= size;
  final GlobalKey key = GlobalKey();

  final hero =
      userHero ?? await binding.runAsync(() => getImage("assets/hero-1.png"));
  final bgData =
      await binding.runAsync(() => getImage("assets/bg-neighbourhood.png"));
  final frameData = useFrame
      ? await binding.runAsync(() => getImage("assets/frame.png"))
      : null;

  final widget = View(
    view: binding.platformDispatcher.implicitView!,
    child: MaterialApp(
      home: Scaffold(
        body: OverflowBox(
          maxHeight: double.infinity,
          maxWidth: double.infinity,
          child: SizedBox(
            height: renderSize.height,
            width: renderSize.width,
            child: RepaintBoundary(
              key: key,
              child: VideoContainer(
                hero: hero!,
                bgData: bgData!,
                frameData: frameData,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  binding.attachRootWidget(widget);
  binding.scheduleWarmUpFrame();

  final perFrameDuration = Duration(milliseconds: (1000 / (fps)).round());

  Duration currentDuration = Duration.zero;
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary;

  final frames = Frames();
  while (currentDuration <= duration) {
    final image = boundary.toImageSync();
    frames.add(FrameItem(image: image, duration: currentDuration));
    currentDuration += perFrameDuration;
    await binding.pump(perFrameDuration);
  }
  hero.dispose();
  bgData.dispose();
  const directoryPrefix = 'outputs/temp';
  const outputPath = '$directoryPrefix/output';

  int index = 0;
  final tempDir = await Directory(directoryPrefix).create(recursive: true);
  final fileCreationFutures =
      (await frames.waitForImages()).map((imageBytes) async {
    const paddingLength = 4;
    final name =
        '$directoryPrefix/out-${(++index).toString().padLeft(paddingLength, '0')}.raw';
    await File(name).writeAsBytes(imageBytes);
  });
  await Future.wait(fileCreationFutures);

  final process = await Process.run('ffmpeg', <String>[
    "-f",
    "image2",
    "-video_size",
    "${size.width.toInt()}x${size.height.toInt()}",
    '-pix_fmt',
    'rgba',
    "-r",
    fps.toString(),
    "-y",
    '-i',
    '$directoryPrefix/out-%04d.raw',
    '-loop',
    '0',
    '-t',
    (currentDuration.inMilliseconds / 1000).toString(),
    if (outputFormat == "gif") ...[
      '-vf',
      'split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse',
    ],
    '-f',
    outputFormatsMap[outputFormat] ?? outputFormat,
    '-vcodec',
    'libx264',
    '-pix_fmt',
    'yuvj420p',
    '-preset',
    'ultrafast',
    '-brand',
    'mp42',
    outputPath,
  ]);

  print(process.stderr);

  final bytes = await File(outputPath).readAsBytes();

  Future.microtask(() async {
    await tempDir.delete(recursive: true);
  });
  return bytes;
}
