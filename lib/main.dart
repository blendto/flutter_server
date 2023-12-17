import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_server/video_container.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<ui.Image> getImage(String key) async {
    final byteData = await rootBundle.load(key);
    return decodeImageFromList(byteData.buffer.asUint8List());
  }

  Future<(ui.Image, ui.Image)> getImages() async {
    final hero = await getImage("assets/hero-1.png");
    final diner = await getImage("assets/diner.jpg");
    return (hero, diner);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Text('Error: ${snapshot.error}');
          }
          final hero = snapshot.data!.$1;
          final bgData = snapshot.data!.$2;
          return VideoContainer(hero: hero, bgData: bgData);
        });
  }
}
