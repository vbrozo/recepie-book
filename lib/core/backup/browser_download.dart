import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Triggers a browser "Save As" download for [bytes] named [fileName] —
/// the web equivalent of writing a file to disk. Only meaningful under
/// `kIsWeb`; callers are expected to check that themselves (mirrors how
/// [ImageStorageService] branches on platform internally instead of via
/// conditional imports, since `dart:js_interop`/`package:web` compile fine
/// on every platform, they just have nothing to talk to outside a browser).
void triggerBrowserDownload(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/zip'),
  );
  final url = web.URL.createObjectURL(blob);

  web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..click();

  web.URL.revokeObjectURL(url);
}
