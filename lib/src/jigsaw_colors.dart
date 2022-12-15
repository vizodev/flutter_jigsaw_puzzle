import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:palette_generator/palette_generator.dart';

// ignore_for_file: public_member_api_docs

Future<PaletteGenerator> computePaletteColor(
    ImageProvider image, Size? size) async {
  try {
    size ??= const Size(300, 300);

    return PaletteGenerator.fromImageProvider(
      image,
      filters: [],
      targets: [
        PaletteTarget.muted,
        PaletteTarget.lightMuted,
        PaletteTarget.lightVibrant,
      ],
      maximumColorCount: 2,
      size: size,
      region: Rect.fromLTRB(
          0, size.height / 1.5, size.width * .05, size.height * .9),
      timeout: const Duration(seconds: 2),
    );
  } catch (e) {
    debugPrint(e.toString());
    return PaletteGenerator.fromColors(
      [PaletteColor(Colors.white, 10)],
    );
  }
}

/// Colors setup for jigsaw
class JigsawColors {
  const JigsawColors._();

  static const white = Colors.white;

  static const canvasBg = Color(0x274CAF50);
  static const canvasOutline = Color(0xFF5A9CCE);
  // Color(0xFF4CAF50); // Colors.green
  static Color pieceOutline = canvasOutline.withOpacity(0.7); // Colors.black12
  static const pieceOutlineDone = Color(0x54FFFFFF);

  static const blocksCarouselBg = Color(0xFF8FC1CD);
  // Color(0xFFe0af8a); // Color(0x26000000);
}

/// Design setup as strokes, fill and more for jigsaw
class JigsawDesign {
  const JigsawDesign._();

  static const strokeCanvasWidth = 5.5;
  static const strokePieceWidth = 4.0;

  // TODO: [JigsawConfigs]
  /// Indent outside/inside the box piece shape
  static double jointSize(double widthPerBlock, double heightPerBlock) =>
      math.min(widthPerBlock, heightPerBlock) / 18 * 4;
}
