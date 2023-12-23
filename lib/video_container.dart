import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class VideoContainer extends StatefulWidget {
  final ui.Image hero;

  final ui.Image bgData;

  final ui.Image? frameData;

  const VideoContainer({
    super.key,
    required this.hero,
    required this.bgData,
    required this.frameData,
  });

  @override
  VideoContainerState createState() => VideoContainerState();
}

class VideoContainerState extends State<VideoContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _positionAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: const Offset(0.2, 0.1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _bgAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRect(
          child: Stack(
            children: [
              Container(color: Colors.blue),
              Center(
                child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bgAnimation.value,
                        child: RawImage(
                          image: widget.bgData,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      );
                    }),
              ),
              if (widget.frameData != null)
                Center(
                  child: Transform.scale(
                    scale: 1.05,
                    child: RawImage(
                      image: widget.frameData,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomLeft,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _positionAnimation,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: FractionallySizedBox(
                          heightFactor: 1,
                          child: RawImage(
                            image: widget.hero,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
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
