import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<(String, Uint8List)?> pickAdminImage() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';
  final changed = Completer<void>();
  input.addEventListener('change', ((web.Event _) => changed.complete()).toJS);
  input.click();
  await changed.future;
  final file = input.files?.item(0);
  if (file == null) return null;
  final buffer = await file.arrayBuffer().toDart;
  return (file.name, Uint8List.view(buffer.toDart));
}
