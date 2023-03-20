// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'jigsaw_configs.dart';
import 'puzzle_piece/piece_block.dart';

class ImageBox {
  ImageBox({
    required this.image,
    this.imagePredominantBgColor,
    required this.configs,
    required this.isDone,
    required this.offsetCenter,
    required this.posSide,
    required this.jointSize,
    required this.size,
    this.pieceColor,
  });

  final Widget? image;
  final Size size;
  final Color? pieceColor;
  final Color? imagePredominantBgColor;
  bool isDone;

  /// Indent outside/inside the piece shape
  final double jointSize;

  /// Alignment data
  final PositionedData posSide;
  final Offset offsetCenter;

  final JigsawConfigs? configs;
}
