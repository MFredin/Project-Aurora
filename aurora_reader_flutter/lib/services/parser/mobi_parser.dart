import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart' as html_parser;

class MobiResult {
  final String title;
  final String author;
  final String? isbn;
  final String? description;
  final String? publisher;
  final String? language;
  final String textContent;
  final Uint8List? coverImage;

  const MobiResult({
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    this.publisher,
    this.language,
    required this.textContent,
    this.coverImage,
  });
}

class MobiParseException implements Exception {
  final String message;
  const MobiParseException(this.message);
  @override
  String toString() => message;
}

class MobiParser {
  MobiParser._();

  static MobiResult parse(Uint8List bytes) {
    if (bytes.length < 78) {
      throw const MobiParseException('File too small to be a valid MOBI.');
    }

    final data = ByteData.sublistView(bytes);

    final numRecords = data.getUint16(76);
    final headerEnd = 78 + numRecords * 8;
    if (bytes.length < headerEnd) {
      throw const MobiParseException('Truncated PalmDB record table.');
    }

    final recordOffsets = <int>[];
    for (var i = 0; i < numRecords; i++) {
      recordOffsets.add(data.getUint32(78 + i * 8));
    }

    int recordLength(int index) {
      if (index + 1 < recordOffsets.length) {
        return recordOffsets[index + 1] - recordOffsets[index];
      }
      return bytes.length - recordOffsets[index];
    }

    final firstRecordOffset = recordOffsets[0];
    if (bytes.length < firstRecordOffset + 16) {
      throw const MobiParseException('First record too small.');
    }

    final compression = data.getUint16(firstRecordOffset);
    final textLength = data.getUint32(firstRecordOffset + 4);
    final textRecordCount = data.getUint16(firstRecordOffset + 8);
    final encryption = data.getUint16(firstRecordOffset + 12);

    if (encryption != 0) {
      throw const MobiParseException(
        'This file is DRM-protected. Edda can only open DRM-free ebooks.\n\n'
        'To remove DRM, use Calibre with the DeDRM plugin, '
        'then convert to EPUB.',
      );
    }

    var title = _readPalmName(bytes);
    var author = 'Unknown Author';
    String? isbn;
    String? description;
    String? publisher;
    String? language;
    int firstImageRecord = -1;
    int coverOffset = -1;

    if (bytes.length >= firstRecordOffset + 20) {
      final mobiIdent = data.getUint32(firstRecordOffset + 16);
      if (mobiIdent == 0x4D4F4249) {
        final mobiHeaderLen = data.getUint32(firstRecordOffset + 20);
        final textEncoding = data.getUint32(firstRecordOffset + 28);

        if (firstRecordOffset + 88 <= bytes.length) {
          firstImageRecord = data.getUint32(firstRecordOffset + 84);
        }

        if (firstRecordOffset + 96 <= bytes.length) {
          final exthFlags = data.getUint32(firstRecordOffset + 92);
          if (exthFlags & 0x40 != 0) {
            final exthOffset = firstRecordOffset + 16 + mobiHeaderLen;
            final exthData = _parseExth(bytes, exthOffset, textEncoding);
            if (exthData['author'] != null) author = exthData['author']!;
            if (exthData['title'] != null) title = exthData['title']!;
            isbn = exthData['isbn'];
            description = exthData['description'];
            publisher = exthData['publisher'];
            language = exthData['language'];
            if (exthData['coverOffset'] != null) {
              coverOffset = int.tryParse(exthData['coverOffset']!) ?? -1;
            }
          }
        }
      }
    }

    final textBuffer = StringBuffer();
    final isUtf8 = bytes.length >= firstRecordOffset + 32 &&
        data.getUint32(firstRecordOffset + 28) == 65001;

    for (var i = 1; i <= textRecordCount && i < recordOffsets.length; i++) {
      final offset = recordOffsets[i];
      final length = recordLength(i);
      final recordBytes = bytes.sublist(offset, offset + length);

      Uint8List decompressed;
      if (compression == 2) {
        decompressed = _decompressPalmDoc(recordBytes);
      } else if (compression == 1) {
        decompressed = Uint8List.fromList(recordBytes);
      } else {
        continue;
      }

      textBuffer.write(
        isUtf8
            ? utf8.decode(decompressed, allowMalformed: true)
            : latin1.decode(decompressed),
      );
    }

    var rawText = textBuffer.toString();
    if (rawText.length > textLength) {
      rawText = rawText.substring(0, textLength);
    }

    final doc = html_parser.parse(rawText);
    final plainText = doc.body?.text ?? rawText;

    Uint8List? coverImage;
    if (firstImageRecord > 0 && coverOffset >= 0) {
      final coverRecord = firstImageRecord + coverOffset;
      if (coverRecord < recordOffsets.length) {
        final offset = recordOffsets[coverRecord];
        final length = recordLength(coverRecord);
        coverImage = bytes.sublist(offset, offset + length);
      }
    }

    return MobiResult(
      title: title,
      author: author,
      isbn: isbn,
      description: description,
      publisher: publisher,
      language: language,
      textContent: plainText,
      coverImage: coverImage,
    );
  }

  static String _readPalmName(Uint8List bytes) {
    final nameBytes = bytes.sublist(0, 32);
    final nullIndex = nameBytes.indexOf(0);
    final end = nullIndex >= 0 ? nullIndex : 32;
    return latin1.decode(nameBytes.sublist(0, end)).trim();
  }

  static Map<String, String> _parseExth(
      Uint8List bytes, int offset, int textEncoding) {
    final result = <String, String>{};
    if (offset + 12 > bytes.length) return result;

    final data = ByteData.sublistView(bytes);
    final ident = data.getUint32(offset);
    if (ident != 0x45585448) return result;

    final recordCount = data.getUint32(offset + 8);
    var pos = offset + 12;

    for (var i = 0; i < recordCount && pos + 8 <= bytes.length; i++) {
      final type = data.getUint32(pos);
      final length = data.getUint32(pos + 4);
      if (length < 8 || pos + length > bytes.length) break;

      final valueBytes = bytes.sublist(pos + 8, pos + length);
      final value = textEncoding == 65001
          ? utf8.decode(valueBytes, allowMalformed: true)
          : latin1.decode(valueBytes);

      switch (type) {
        case 100:
          result['author'] = value;
        case 101:
          result['publisher'] = value;
        case 103:
          result['description'] = value;
        case 104:
          result['isbn'] = value;
        case 201:
          final coverIdx = length == 12
              ? data.getUint32(pos + 8).toString()
              : value;
          result['coverOffset'] = coverIdx;
        case 503:
          result['title'] = value;
      }

      pos += length;
    }

    return result;
  }

  static Uint8List _decompressPalmDoc(List<int> compressed) {
    final output = <int>[];
    var i = 0;

    while (i < compressed.length) {
      final byte = compressed[i++];

      if (byte == 0) {
        output.add(0);
      } else if (byte >= 1 && byte <= 8) {
        for (var j = 0; j < byte && i < compressed.length; j++) {
          output.add(compressed[i++]);
        }
      } else if (byte >= 0x09 && byte <= 0x7F) {
        output.add(byte);
      } else if (byte >= 0x80 && byte <= 0xBF) {
        if (i >= compressed.length) break;
        final next = compressed[i++];
        final pair = (byte << 8) | next;
        final distance = (pair >> 3) & 0x7FF;
        final length = (next & 0x07) + 3;

        if (distance > 0) {
          for (var j = 0; j < length; j++) {
            final srcIndex = output.length - distance;
            if (srcIndex >= 0 && srcIndex < output.length) {
              output.add(output[srcIndex]);
            }
          }
        }
      } else {
        output.add(0x20);
        output.add(byte ^ 0x80);
      }
    }

    return Uint8List.fromList(output);
  }
}
