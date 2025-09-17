import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final Record _recorder = Record();
  String? _currentPath;

  Future<bool> hasPermission() async {
    final mic = await Permission.microphone.request();
    // Sur Android 13+, READ_MEDIA_AUDIO n'est pas requis pour la capture
    return mic.isGranted;
  }

  Future<String> startRecording() async {
    if (!await hasPermission()) {
      throw Exception('Permission micro refusée');
    }

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    final Directory dir = await getTemporaryDirectory();
    final String filePath =
        '${dir.path}/discussion_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      path: filePath,
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
      numChannels: 1,
    );

    _currentPath = filePath;
    return filePath;
  }

  Future<File?> stopRecording() async {
    final String? path = await _recorder.stop();
    final String? finalPath = path ?? _currentPath;
    _currentPath = null;
    if (finalPath == null) return null;
    return File(finalPath);
  }

  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}


