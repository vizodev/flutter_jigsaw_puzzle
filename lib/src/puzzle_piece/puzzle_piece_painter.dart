// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_jigsaw_puzzle/src/puzzle_piece/puzzle_piece_clipper.dart';

import '../image_box.dart';
import '../jigsaw_colors.dart';

class PuzzlePiecePainter extends CustomPainter {
  const PuzzlePiecePainter({
    this.isForegroundPainter = true,
    this.isJigsawReveal = false,
    required this.imageBox,
  });

  final bool isJigsawReveal;
  final bool isForegroundPainter;
  final ImageBox imageBox;

  @override
  void paint(Canvas canvas, Size size) {
    if (isJigsawReveal) {
      return _jigsawRevealPaint(canvas, size);
    } else {
      return _standardJigsawPaint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  //helpers
  void _jigsawRevealPaint(Canvas canvas, Size size) {
    final strokeFactor = imageBox.configs?.outlinesWidthFactor ?? 2;

    // NEW
    if (!isForegroundPainter && imageBox.imagePredominantBgColor != null) {
      final Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = imageBox.imagePredominantBgColor!;
      canvas.drawPath(
          getPiecePath(size, imageBox.jointSize, imageBox.offsetCenter,
              imageBox.posSide),
          backgroundPaint);

      return;
    }

    final Paint paint = Paint()
      ..color = imageBox.pieceColor ?? Colors.transparent
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;

    final border = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = (JigsawDesign.strokePieceWidth / strokeFactor) * 1.3;

    canvas.drawPath(
      getPiecePath(
          size, imageBox.jointSize, imageBox.offsetCenter, imageBox.posSide),
      paint,
    );
    canvas.drawPath(
      getPiecePath(
          size, imageBox.jointSize, imageBox.offsetCenter, imageBox.posSide),
      border,
    );
    return;
  }

  void _standardJigsawPaint(Canvas canvas, Size size) {
    final strokeFactor = imageBox.configs?.outlinesWidthFactor ?? 1;

    // NEW
    if (!isForegroundPainter && imageBox.imagePredominantBgColor != null) {
      final Paint backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = imageBox.imagePredominantBgColor!;
      canvas.drawPath(
          getPiecePath(size, imageBox.jointSize, imageBox.offsetCenter,
              imageBox.posSide),
          backgroundPaint);
      return;
    }

    final Paint border = Paint()
      ..color = imageBox.isDone
          ? JigsawColors.pieceOutlineDone
          : JigsawColors.pieceOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = (JigsawDesign.strokePieceWidth / strokeFactor);

    canvas.drawPath(
      getPiecePath(
          size, imageBox.jointSize, imageBox.offsetCenter, imageBox.posSide),
      border,
    );

    // if (imageBox.isDone) {
    //   final Paint paintDone = Paint()
    //     ..color = JigsawColors.pieceOutlineDone
    //     ..style = PaintingStyle.stroke
    //     ..strokeWidth = (JigsawDesign.strokeCanvasWidth / strokeFactor);
    //
    //   canvas.drawPath(
    //     getPiecePath(size, imageBox.radiusPoint, imageBox.offsetCenter,
    //         imageBox.posSide),
    //     paintDone,
    //   );
    // }
  }
}
