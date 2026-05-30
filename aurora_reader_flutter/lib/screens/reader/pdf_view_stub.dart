import 'dart:typed_data';
import 'package:flutter/material.dart';

Widget buildPdfView(Uint8List data, String viewId) {
  return const Center(
    child: Text(
      'PDF viewing is available in the web version of Edda.',
      style: TextStyle(color: Colors.white70, fontSize: 14),
    ),
  );
}
