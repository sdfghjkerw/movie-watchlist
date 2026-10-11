import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';

Future<Uint8List> prepareAvatar(Uint8List bytes) async {
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
    throw const FormatException('Фото должно быть не больше 5 МБ.');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (width, height) {
      final scale = math.min(1.0, 512 / math.max(width, height));
      return ui.TargetImageSize(
        width: math.max(1, (width * scale).round()),
        height: math.max(1, (height * scale).round()),
      );
    },
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const FormatException('Не удалось прочитать фото.');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

Future<Uint8List?> pickAvatar() async {
  const images = XTypeGroup(
    label: 'Images',
    extensions: ['jpg', 'jpeg', 'png', 'webp'],
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    uniformTypeIdentifiers: [
      'public.jpeg',
      'public.png',
      'org.webmproject.webp',
    ],
  );
  final file = await openFile(acceptedTypeGroups: [images]);
  if (file == null) return null;
  if (await file.length() > 5 * 1024 * 1024) {
    throw const FormatException('Фото должно быть не больше 5 МБ.');
  }
  return prepareAvatar(await file.readAsBytes());
}
