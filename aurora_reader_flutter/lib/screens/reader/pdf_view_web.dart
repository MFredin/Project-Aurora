// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final _registered = <String>{};

Widget buildPdfView(Uint8List data, String viewId) {
  if (!_registered.contains(viewId)) {
    final blob = html.Blob([data], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        return html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
      },
    );
    _registered.add(viewId);
  }

  return HtmlElementView(viewType: viewId);
}
