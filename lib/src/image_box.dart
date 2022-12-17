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

  Widget image;
  Color? pieceColor;
  Color? imagePredominantBgColor;
  bool isDone;
  Size size;

  /// Indent outside/inside the piece shape
  double jointSize;

  /// Alignment data
  PositionedData posSide;
  Offset offsetCenter;

  final JigsawConfigs? configs;
}
