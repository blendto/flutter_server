import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_server/video_container.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<ui.Image> getImage(String key) async {
    final byteData = await rootBundle.load(key);
    return decodeImageFromList(byteData.buffer.asUint8List());
  }

  Future<(ui.Image, ui.Image, ui.Image)> getImages() async {
    final hero = await getImage("assets/hero-1.png");
    final diner = await getImage("assets/diner.jpg");
    final frame = await getImage("assets/frame.png");
    return (hero, diner, frame);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      home: FutureBuilder(
          future: getImages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError || snapshot.data == null) {
              print(snapshot.error);
              return Container(color: Colors.amber);
            }
            final hero = snapshot.data!.$1;
            final bgData = snapshot.data!.$2;
            final frameData = snapshot.data!.$3;

            return VideoContainer(
              hero: hero,
              bgData: bgData,
              frameData: frameData,
            );
          }),
    );
  }
}
