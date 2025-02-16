import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  VideoPlayerScreenState createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
  static const platform = MethodChannel('audio_processor');

  Future<void> _playVideo({
    required String mode,
    required double speed,
  }) async {
    try {
      const String videoPath = "mov_bbb.mp4";

      // 画面のサイズを取得
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      // 動画のサイズを決定
      const double videoWidth = 300;
      const double videoHeight = 200;
      final double x = (screenWidth - videoWidth) / 2;
      final double y = (screenHeight - videoHeight) / 4;

      final String result = await platform.invokeMethod(mode, {
        "videoPath": videoPath,
        "speed": speed,
        "x": x,
        "y": y,
        "width": videoWidth,
        "height": videoHeight,
      });

      print("iOS再生結果: $result");
    } on PlatformException catch (e) {
      print("Failed to play video on iOS: ${e.message}");
    }
  }

  Future<void> _stopVideo() async {
    try {
      final String result = await platform.invokeMethod("Stop");
      print("iOS停止結果: $result");
    } on PlatformException catch (e) {
      print("Failed to stop video on iOS: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sample")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _playVideo(mode: "Slow", speed: 0.25),
              child: const Text("スロー再生 (0.25x, 音声補正あり)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _playVideo(mode: "NotSlow", speed: 0.25),
              child: const Text("スロー再生 (0.25x, 音声補正なし)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _playVideo(mode: "NotSlow", speed: 1.0),
              child: const Text("通常再生 (1.0x)"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _stopVideo,
              child: const Text("停止"),
            ),
          ],
        ),
      ),
    );
  }
}
