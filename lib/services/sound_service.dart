import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();

  static final _player = AudioPlayer();
  static const _sr = 44100;

  // Bell-like wave with harmonics and fast-attack / exponential-decay envelope
  static Uint8List _buildWav(List<(double freq, double dur)> notes) {
    final pcm = <int>[];
    for (final (freq, dur) in notes) {
      final n = (_sr * dur).round();
      for (var i = 0; i < n; i++) {
        final t = i / _sr;
        final attack = (t / 0.008).clamp(0.0, 1.0);
        final decay = exp(-4.5 * t / dur);
        final env = attack * decay * 0.32;
        final wave = sin(2 * pi * freq * t)
            + 0.28 * sin(4 * pi * freq * t)
            + 0.08 * sin(6 * pi * freq * t);
        final s = (wave * env * 32767).clamp(-32767.0, 32767.0).round();
        pcm.add(s & 0xFF);
        pcm.add((s >> 8) & 0xFF);
      }
    }
    return _wav(pcm);
  }

  static Uint8List _wav(List<int> pcm) {
    final h = ByteData(44);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        h.setUint8(off + i, s.codeUnitAt(i));
      }
    }
    str(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 1, Endian.little);
    h.setUint32(24, _sr, Endian.little);
    h.setUint32(28, _sr * 2, Endian.little);
    h.setUint16(32, 2, Endian.little);
    h.setUint16(34, 16, Endian.little);
    str(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...h.buffer.asUint8List(), ...pcm]);
  }

  static Future<void> _play(List<(double, double)> notes) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(_buildWav(notes)));
    } catch (_) {}
  }

  /// Two descending tones — focus phase done, break time.
  static Future<void> focusEnd() => _play([
        (659.0, 0.65), // E5
        (523.0, 0.55), // C5
      ]);

  /// Two ascending tones — break over, back to work.
  static Future<void> breakEnd() => _play([
        (523.0, 0.20), // C5
        (784.0, 0.42), // G5
      ]);

  /// Rising C-major arpeggio — session complete!
  static Future<void> sessionComplete() => _play([
        (523.0, 0.20), // C5
        (659.0, 0.20), // E5
        (784.0, 0.55), // G5
      ]);
}
